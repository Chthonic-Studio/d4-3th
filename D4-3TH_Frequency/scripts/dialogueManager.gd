extends Node

@export var dialogue_data_path := "res://data/dialogues/dialogues.json" # Path to JSON file(s)
@export var message_history_save_path := "user://message_history.save"

signal dialogue_started(frequency_id)
signal dialogue_ended(frequency_id)
signal message_added(frequency_id, message_data)
signal reply_options_changed(frequency_id, options)
signal message_history_loaded(frequency_id)
signal system_message(text)

# Runtime Data
var dialogue_data := {}                # Parsed dialogue trees by id
var frequency_histories := {}          # {frequency_id: [message_dict, ...]}
var active_dialogues := {}             # {frequency_id: {tree_id, current_node_id, ...}}
var frequency_active := {}             # {frequency_id: true/false}

enum VoiceModulation { Normal, Hostile, Distressed }

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
			dialogue_data[d["id"]] = d["tree"]
	else:
		push_error("DialogueManager: Invalid dialogue data format.")

# Start a dialogue for a frequency
# Pass in the frequency_id and the dialogue_id to use
func start_dialogue(frequency_id: int, dialogue_id: String):
	if not dialogue_data.has(dialogue_id):
		push_error("DialogueManager: Dialogue id '%s' not found." % dialogue_id)
		return
	active_dialogues[frequency_id] = {
		"tree_id": dialogue_id,
		"current_node": "start"
	}
	frequency_active[frequency_id] = true
	emit_signal("dialogue_started", frequency_id)
	_show_current_node(frequency_id)

# End a dialogue for a frequency
func end_dialogue(frequency_id: int):
	frequency_active[frequency_id] = false
	if active_dialogues.has(frequency_id):
		active_dialogues.erase(frequency_id)
	emit_signal("dialogue_ended", frequency_id)

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
	# Set flags using EventsManager
	for flag in reply.get("set_flags", []):
		EventsManager.set_flag(flag)
	# Trigger custom event if present
	if reply.has("custom_event"):
		EventsManager.trigger_event(reply["custom_event"], reply.get("custom_payload", {}))
		emit_signal("system_message", "[SYSTEM] Event triggered: %s" % reply["custom_event"])

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
