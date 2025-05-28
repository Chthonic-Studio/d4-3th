extends Node

# USAGE
# start_dialogue(frequency_id, dialogue_id):
# Call when you want to trigger a dialogue for a frequency.
# It sets the status, starts standby timer if needed, and blocks if another dialogue is in progress for that frequency.

# try_activate_dialogue(frequency_id):
# Call when player tunes in and all conditions (Listen, Reply, etc.) are met.
# This will move a dialogue from standby to active, show UI, and pause time.

# interrupt_active_dialogue(frequency_id):
# Call when player leaves mid-conversation (by frequency change, Listen/Reply toggled off, etc.).
# This will start the waiting timer.

# try_resume_waiting_dialogue(frequency_id):
# Call if the player returns to a waiting dialogue before the timer expires.

# get_dialogue_status(dialogue_id):
# For UI or scripting logic, check the current status of any dialogue.

@export var dialogue_data_path := "res://data/dialogues/dialogues.json" # Path to JSON file(s)
@export var message_history_save_path := "user://message_history.save"

signal dialogue_started(frequency_id)
signal dialogue_ended(frequency_id)
signal message_added(frequency_id, message_data)
signal reply_options_changed(frequency_id, options)
signal message_history_loaded(frequency_id)
signal system_message(text)

# Standby durations for categories
var standby_duration_map := {
	"low_priority": 60,    # 1 hour, in-game minutes
	"mid_priority": 120,   # 2 hours
	"high_priority": 180,  # 3 hours
	"permanent": -1        # -1: never expires
}
var default_standby_category := "low_priority"
var waiting_duration_minutes := 60

# Runtime Data
var dialogue_data := {}                # Parsed dialogue trees by id
var frequency_histories := {}          # {frequency_id: [message_dict, ...]}
var active_dialogues := {}             # {frequency_id: {tree_id, current_node_id, ...}}
var frequency_active := {}             # {frequency_id: true/false}
var frequency_pending_dialogue := {}   # {frequency_id: dialogue_id}

# --- NEW: Timers and state trackers ---
var standby_timers := {}    # { frequency_id: Timer }
var waiting_timers := {}    # { frequency_id: Timer }

enum VoiceModulation { INACTIVE, NORMAL, HOSTILE, DISTRESSED }

# Helper to find standby duration from JSON node or fallback
func _get_standby_duration(dialogue_id: String) -> int:
	var d = null
	# Find the actual dialogue JSON tree
	for entry in dialogue_data:
		if entry == dialogue_id:
			d = dialogue_data[entry]
			break
	if d and d.has("standby_category"):
		var cat = d["standby_category"]
		return standby_duration_map.get(cat, standby_duration_map[default_standby_category])
	return standby_duration_map[default_standby_category]

func _ready():
	load_dialogue_data()
	load_message_history()

# Load dialogue trees from JSON
func load_dialogue_data():
	var file = FileAccess.open(dialogue_data_path, FileAccess.READ)
	if not file:
		push_error("DialogueManager: Failed to open dialogue data at %s" % dialogue_data_path)
		return
	var raw = file.get_as_text()
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary and parsed.has("dialogues"):
		for d in parsed["dialogues"]:
			# Allow standby_category to be at top-level of dialogue if present
			var tree = d["tree"]
			if d.has("standby_category"):
				tree["standby_category"] = d["standby_category"]
			dialogue_data[d["id"]] = tree
	else:
		push_error("DialogueManager: Invalid dialogue data format.")

# Start a dialogue for a frequency
# Pass in the frequency_id and the dialogue_id to use
# Start a dialogue, but only if frequency is available (no standby/waiting there)
# Returns true if started, false if blocked
func start_dialogue(frequency_id: int, dialogue_id: String) -> bool:
	# Check if frequency already has a dialogue in progress or standby/waiting
	if _frequency_has_dialogue(frequency_id):
		return false
	# Mark as onStandby and set timer if needed
	frequency_pending_dialogue[frequency_id] = dialogue_id
	EventsManager.set_dialogue_status(dialogue_id, "onStandby")
	# Start standby timer if not permanent
	var duration = _get_standby_duration(dialogue_id)
	if duration > 0:
		_start_standby_timer(frequency_id, dialogue_id, duration)
	emit_signal("dialogue_started", frequency_id)
	return true
	
# Call this whenever player "engages" with a frequency
# When player TUNES IN and conditions are right, activate the dialogue
func try_activate_dialogue(frequency_id: int):
	print("DIALOGUE MANAGER: try_activate_dialogue called for freq", frequency_id)
	# Only activate if conditions are right (Listen/Reply ON, on correct freq)
	if not frequency_pending_dialogue.has(frequency_id):
		print("DIALOGUE MANAGER: No pending dialogue for freq", frequency_id)
		return
	var dialogue_id = frequency_pending_dialogue[frequency_id]
	# Stop standby timer if any
	if standby_timers.has(frequency_id):
		standby_timers[frequency_id].stop()
		standby_timers[frequency_id].queue_free()
		standby_timers.erase(frequency_id)
	EventsManager.set_dialogue_status(dialogue_id, "active")
	active_dialogues[frequency_id] = {
		"tree_id": dialogue_id,
		"current_node": "start"
	}
	frequency_pending_dialogue.erase(frequency_id)
	frequency_active[frequency_id] = true
	emit_signal("dialogue_started", frequency_id)
	_show_current_node(frequency_id)
	# Pause time
	if TimeManager:
		TimeManager.stop()

# Helper: Check if frequency is blocked for new dialogue (already has onStandby/waiting/active)
func _frequency_has_dialogue(frequency_id: int) -> bool:
	if frequency_id in frequency_pending_dialogue:
		return true
	if frequency_id in active_dialogues:
		return true
	if frequency_id in waiting_timers:
		return true
	return false

# Standby timer logic
func _start_standby_timer(frequency_id: int, dialogue_id: String, minutes: int):
	# Remove any old timer
	if standby_timers.has(frequency_id):
		standby_timers[frequency_id].queue_free()
		standby_timers.erase(frequency_id)
	# Create timer (in-game, so use timeManager callbacks or polling)
	var timer = Timer.new()
	timer.wait_time = 0.5  # Each in-game minute is 0.5 real seconds by your timeManager
	timer.one_shot = false
	timer.set_meta("frequency_id", frequency_id)
	timer.set_meta("dialogue_id", dialogue_id)
	timer.set_meta("remaining", minutes)
	timer.timeout.connect(func():
		var rem = timer.get_meta("remaining") - 1
		timer.set_meta("remaining", rem)
		if rem <= 0:
			# Standby expired, mark as lost
			EventsManager.set_dialogue_status(dialogue_id, "lost")
			frequency_pending_dialogue.erase(frequency_id)
			timer.stop()
			timer.queue_free()
			standby_timers.erase(frequency_id)
	)
	add_child(timer)
	standby_timers[frequency_id] = timer
	timer.start()

# Handle dialogue interruption when player leaves (Listen or Reply off, or frequency changed)
func interrupt_active_dialogue(frequency_id: int):
	if not active_dialogues.has(frequency_id):
		return
	var dialogue_id = active_dialogues[frequency_id]["tree_id"]
	EventsManager.set_dialogue_status(dialogue_id, "waiting")
	# Start waiting timer (1 hour in-game)
	_start_waiting_timer(frequency_id, dialogue_id)
	# Hide UI, mark not active
	frequency_active[frequency_id] = false
	emit_signal("dialogue_ended", frequency_id)
	# Resume time
	if TimeManager:
		TimeManager.start()

# End a dialogue for a frequency
# Mark as done, handle time resume
func end_dialogue(frequency_id: int):
	if not active_dialogues.has(frequency_id):
		return
	var dialogue_id = active_dialogues[frequency_id]["tree_id"]
	EventsManager.set_dialogue_status(dialogue_id, "done")
	frequency_active[frequency_id] = false
	active_dialogues.erase(frequency_id)
	emit_signal("dialogue_ended", frequency_id)
	# Resume time
	if TimeManager:
		TimeManager.start()

func _start_waiting_timer(frequency_id: int, dialogue_id: String):
	if waiting_timers.has(frequency_id):
		waiting_timers[frequency_id].queue_free()
		waiting_timers.erase(frequency_id)
	var timer = Timer.new()
	timer.wait_time = 0.5  # Each in-game minute is 0.5 real seconds
	timer.one_shot = false
	timer.set_meta("frequency_id", frequency_id)
	timer.set_meta("dialogue_id", dialogue_id)
	timer.set_meta("remaining", waiting_duration_minutes)
	timer.timeout.connect(func():
		var rem = timer.get_meta("remaining") - 1
		timer.set_meta("remaining", rem)
		if rem <= 0:
			# Waiting expired, mark as interrupted
			EventsManager.set_dialogue_status(dialogue_id, "interrupted")
			if active_dialogues.has(frequency_id):
				active_dialogues.erase(frequency_id)
			timer.stop()
			timer.queue_free()
			waiting_timers.erase(frequency_id)
	)
	add_child(timer)
	waiting_timers[frequency_id] = timer
	timer.start()
	
# Resume waiting dialogue if player returns before timer expires
func try_resume_waiting_dialogue(frequency_id: int):
	if not waiting_timers.has(frequency_id):
		return
	# Resume dialogue (set as active, remove waiting timer)
	var dialogue_id = waiting_timers[frequency_id].get_meta("dialogue_id")
	EventsManager.set_dialogue_status(dialogue_id, "active")
	active_dialogues[frequency_id] = {
		"tree_id": dialogue_id,
		"current_node": "start"  # Optionally track where to resume
	}
	waiting_timers[frequency_id].stop()
	waiting_timers[frequency_id].queue_free()
	waiting_timers.erase(frequency_id)
	frequency_active[frequency_id] = true
	emit_signal("dialogue_started", frequency_id)
	_show_current_node(frequency_id)
	# Pause time
	if TimeManager:
		TimeManager.stop()

# Show the current node (message and replies) for a frequency
func _show_current_node(frequency_id: int):
	if not active_dialogues.has(frequency_id):
		return
	var tree_id = active_dialogues[frequency_id]["tree_id"]
	var node_id = active_dialogues[frequency_id]["current_node"]
	var node = dialogue_data[tree_id][node_id]
	if not _check_conditions(node):
		# If this node is not available, try to end dialogue
		end_dialogue(frequency_id)
		return
	# Compose message
	var message_data = {
		"body": node.get("message", ""),
		"sender": node.get("sender", "operator"),
		"voice_modulation": node.get("voice_modulation", "Normal"),
		"audio": node.get("audio", null),
		"date": TimeManager.get_time(), # {day, hour, minute}
		"bg_audio": node.get("bg_audio", null)
	}
	_add_message_to_history(frequency_id, message_data)
	emit_signal("message_added", frequency_id, message_data)
	# Handle audio
	if message_data.audio:
		AudioManager.play_voice(load(message_data.audio))
	if message_data.bg_audio:
		AudioManager.play_music(load(message_data.bg_audio))
	# Prepare replies
	var reply_options := []
	for reply in node.get("replies", []):
		if _check_conditions(reply):
			reply_options.append(reply)
	emit_signal("reply_options_changed", frequency_id, reply_options)
	# If no replies, end dialogue
	if reply_options.size() == 0:
		end_dialogue(frequency_id)

# Called by UI when player selects a reply
func choose_reply(frequency_id: int, reply_index: int):
	print("Choose_reply called")
	if not active_dialogues.has(frequency_id):
		return
	var tree_id = active_dialogues[frequency_id]["tree_id"]
	var node_id = active_dialogues[frequency_id]["current_node"]
	var node = dialogue_data[tree_id][node_id]
	var available_replies = []
	for reply in node.get("replies", []):
		if _check_conditions(reply):
			available_replies.append(reply)
	if reply_index >= available_replies.size():
		push_error("DialogueManager: Invalid reply index")
		return
	var reply = available_replies[reply_index]

	# Mark the dialogue as "in_progress" or checkpoint as needed
	EventsManager.set_dialogue_status(tree_id, "in_progress") # or use another descriptor if you prefer

	# Set flags using EventsManager
	for flag in reply.get("set_flags", []):
		EventsManager.set_flag(flag)
	# Trigger custom event if present
	if reply.has("custom_event"):
		EventsManager.trigger_event(reply["custom_event"], reply.get("custom_payload", {}))
		emit_signal("system_message", "[SYSTEM] Event triggered: %s" % reply["custom_event"])
	# Advance to next node, if any
	if reply.has("next"):
		active_dialogues[frequency_id]["current_node"] = reply["next"]
		_show_current_node(frequency_id)
	elif reply.get("end_dialogue", false):
		GameManager.set_voice_modulation_value("INACTIVE")
		end_dialogue(frequency_id)
	else:
		# If neither, just end dialogue for safety
		GameManager.set_voice_modulation_value("INACTIVE")
		end_dialogue(frequency_id)
		
# Check if all conditions on an object (node or reply) are satisfied
func _check_conditions(obj: Dictionary) -> bool:
	if not obj.has("conditions"):
		return true
	for cond in obj["conditions"]:
		if cond.begins_with("not_"):
			var flag = cond.substr(4)
			# Use EventsManager for all flag checks
			if EventsManager.get_flag(flag):
				return false
		else:
			if not EventsManager.get_flag(cond):
				return false
	return true

# Add a message to the persistent history (per frequency)
func _add_message_to_history(frequency_id: int, message_data: Dictionary):
	if not frequency_histories.has(frequency_id):
		frequency_histories[frequency_id] = []
	frequency_histories[frequency_id].append(message_data)

# Get history for a frequency (for UI)
func get_message_history(frequency_id: int) -> Array:
	return frequency_histories.get(frequency_id, [])

# Check if a frequency has an active dialogue
func is_dialogue_active(frequency_id: int) -> bool:
	return frequency_active.get(frequency_id, false)

func get_dialogue_status(dialogue_id: String) -> String:
	return EventsManager.get_dialogue_status(dialogue_id)

# Save/load message history (per run)
func save_message_history():
	var file = FileAccess.open(message_history_save_path, FileAccess.WRITE)
	if not file:
		push_error("DialogueManager: Could not save message history")
		return
	file.store_var(frequency_histories)
	file.close()

func load_message_history():
	if not FileAccess.file_exists(message_history_save_path):
		return
	var file = FileAccess.open(message_history_save_path, FileAccess.READ)
	if file:
		frequency_histories = file.get_var()
		file.close()
		for freq_id in frequency_histories.keys():
			emit_signal("message_history_loaded", freq_id)

func replace_dialogue_vars(text: String) -> String:
	# Supports {variable} replacement from EventsManager/global_flags and GameManager
	var new_text = text
	var regex = RegEx.new()
	regex.compile(r"\{([a-zA-Z0-9_]+)\}")
	var matches = regex.search_all(text)
	for match in matches:
		var var_name = match.get_string(1)
		var value = EventsManager.get_flag(var_name)
		if value == null and GameManager.has(var_name):
			value = GameManager.get(var_name)
		new_text = new_text.replace("{" + var_name + "}", str(value))
	return new_text

func assign_random_dialogue_to_white_frequency():
	var candidates = []
	for freq in GameManager.frequencies + GameManager.found_frequencies:
		if GameManager.get_frequency_state(freq) == "no_standby":
			candidates.append(freq)
	if candidates.size() == 0:
		return false
	var freq = candidates.pick_random()
	# Find unused dialogues (not shown this run)
	var unused_dialogues = []
	for d_id in dialogue_data.keys():
		if EventsManager.get_dialogue_status(d_id) == "off":
			unused_dialogues.append(d_id)
	if unused_dialogues.size() == 0:
		return false
	var chosen_dialogue = unused_dialogues.pick_random()
	start_dialogue(freq["id"], chosen_dialogue)
	return true

# API: externally add messages (e.g. for system messages, events)
func add_message(frequency_id: int, message_data: Dictionary):
	_add_message_to_history(frequency_id, message_data)
	emit_signal("message_added", frequency_id, message_data)
	save_message_history()

# Set Flags through Events Manager
func set_flag(flag: String, value: bool = true):
	EventsManager.set_flag(flag, value)

func get_flag(flag: String) -> bool:
	return EventsManager.get_flag(flag)

# Optionally expose reset/clear functions for new runs, etc.
func reset_all():
	frequency_histories = {}
	active_dialogues = {}
	frequency_active = {}
	save_message_history()
