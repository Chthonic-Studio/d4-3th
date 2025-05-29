extends Node

@export var dialogue_data_path := "res://data/dialogues/dialogues.json"
@export var message_history_save_path := "user://message_history.save"

signal dialogue_started(frequency_id)
signal dialogue_ended(frequency_id)
signal message_added(frequency_id, message_data)
signal reply_options_changed(frequency_id, options)
signal message_history_loaded(frequency_id)
signal system_message(text)
signal dialogue_data_loaded

var standby_duration_map := {
	"low_priority": 60,
	"mid_priority": 120,
	"high_priority": 180,
	"permanent": -1
}
var default_standby_category := "low_priority"
var waiting_duration_minutes := 60

var dialogue_data := {}
var frequency_histories := {}
var active_dialogues := {}
var frequency_active := {}
var frequency_pending_dialogue := {}  # {frequency_id: {id, start_node}}
var standby_timers := {}
var waiting_timers := {}

enum VoiceModulation { INACTIVE, NORMAL, HOSTILE, DISTRESSED }

func _get_standby_duration(dialogue_id: String) -> int:
	var d = null
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

func load_dialogue_data():
	var file = FileAccess.open(dialogue_data_path, FileAccess.READ)
	if not file:
		push_error("DialogueManager: Failed to open dialogue data at %s" % dialogue_data_path)
		return
	var raw = file.get_as_text()
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary and parsed.has("dialogues"):
		for d in parsed["dialogues"]:
			var tree = d["tree"]
			if d.has("standby_category"):
				tree["standby_category"] = d["standby_category"]
			dialogue_data[d["id"]] = tree
	else:
		push_error("DialogueManager: Invalid dialogue data format.")
	print("DEBUG: dialogue_data keys after loading:", dialogue_data.keys())
	if dialogue_data.has("scavenger_request"):
		print("DEBUG: scavenger_request tree keys after loading:", dialogue_data["scavenger_request"].keys())
	emit_signal("dialogue_data_loaded")
	
# Start a dialogue for a frequency (optionally at a specific node)
func start_dialogue(frequency_id: int, dialogue_id: String, start_node: String = "") -> bool:
	print("DEBUG: (top of start_dialogue) dialogue_data['scavenger_request'] keys:", dialogue_data.get("scavenger_request", {}).keys())
	if _frequency_has_dialogue(frequency_id):
		return false
	var tree = dialogue_data.get(dialogue_id, {})
	print("DEBUG: Starting dialogue", dialogue_id, "tree keys:", tree.keys())
	var node = start_node
	if node == "" or not tree.has(node):
		# Priority: start_human > start_entity > start > any node
		if tree.has("start_human"):
			node = "start_human"
		elif tree.has("start_entity"):
			node = "start_entity"
		elif tree.has("start"):
			node = "start"
		elif tree.keys().size() > 0:
			node = tree.keys()[0]
		else:
			push_error("DialogueManager: No valid start node in dialogue '%s', tree keys: %s" % [dialogue_id, tree.keys()])
			return false
	frequency_pending_dialogue[frequency_id] = {"id": dialogue_id, "start_node": node}
	EventsManager.set_dialogue_status(dialogue_id, "onStandby")
	var duration = _get_standby_duration(dialogue_id)
	if duration > 0:
		_start_standby_timer(frequency_id, dialogue_id, duration)
	emit_signal("dialogue_started", frequency_id)
	return true


# Helper: Start at dynamic branch based on role
func start_dialogue_dynamic(frequency_id: int, dialogue_id: String, role: String = "") -> bool:
	print("DEBUG: (top of start_dialogue) dialogue_data['scavenger_request'] keys:", dialogue_data.get("scavenger_request", {}).keys())
	var tree = dialogue_data.get(dialogue_id, {})
	var start_node = "start"
	if role != "" and tree.has("start_%s" % role):
		start_node = "start_%s" % role
	elif tree.has("start"):
		start_node = "start"
	elif tree.keys().size() > 0:
		start_node = tree.keys()[0]
	else:
		start_node = ""
	return start_dialogue(frequency_id, dialogue_id, start_node)

func try_activate_dialogue(frequency_id: int):
	if not frequency_pending_dialogue.has(frequency_id):
		return
	var entry = frequency_pending_dialogue[frequency_id]
	var dialogue_id = entry["id"] if entry.has("id") else entry
	var start_node = entry.get("start_node", "")
	if standby_timers.has(frequency_id):
		standby_timers[frequency_id].stop()
		standby_timers[frequency_id].queue_free()
		standby_timers.erase(frequency_id)
	EventsManager.set_dialogue_status(dialogue_id, "active")
	var node_id = start_node if start_node != "" else "start"
	active_dialogues[frequency_id] = {
		"tree_id": dialogue_id,
		"current_node": node_id
	}
	frequency_pending_dialogue.erase(frequency_id)
	frequency_active[frequency_id] = true
	emit_signal("dialogue_started", frequency_id)
	_show_current_node(frequency_id)
	if TimeManager:
		TimeManager.stop()

func _frequency_has_dialogue(frequency_id: int) -> bool:
	return (
		frequency_id in frequency_pending_dialogue
		or frequency_id in active_dialogues
		or frequency_id in waiting_timers
	)

func _start_standby_timer(frequency_id: int, dialogue_id: String, minutes: int):
	if standby_timers.has(frequency_id):
		standby_timers[frequency_id].queue_free()
		standby_timers.erase(frequency_id)
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = false
	timer.set_meta("frequency_id", frequency_id)
	timer.set_meta("dialogue_id", dialogue_id)
	timer.set_meta("remaining", minutes)
	timer.timeout.connect(func():
		var rem = timer.get_meta("remaining") - 1
		timer.set_meta("remaining", rem)
		if rem <= 0:
			EventsManager.set_dialogue_status(dialogue_id, "lost")
			frequency_pending_dialogue.erase(frequency_id)
			timer.stop()
			timer.queue_free()
			standby_timers.erase(frequency_id)
	)
	add_child(timer)
	standby_timers[frequency_id] = timer
	timer.start()

func interrupt_active_dialogue(frequency_id: int):
	if not active_dialogues.has(frequency_id):
		return
	var dialogue_id = active_dialogues[frequency_id]["tree_id"]
	EventsManager.set_dialogue_status(dialogue_id, "waiting")
	_start_waiting_timer(frequency_id, dialogue_id)
	frequency_active[frequency_id] = false
	emit_signal("dialogue_ended", frequency_id)
	if TimeManager:
		TimeManager.start()

func end_dialogue(frequency_id: int):
	if not active_dialogues.has(frequency_id):
		return
	var dialogue_id = active_dialogues[frequency_id]["tree_id"]
	EventsManager.set_dialogue_status(dialogue_id, "done")
	frequency_active[frequency_id] = false
	active_dialogues.erase(frequency_id)
	emit_signal("dialogue_ended", frequency_id)
	# emit_signal("reply_options_changed", frequency_id, [])
	if TimeManager:
		TimeManager.start()
	GameManager.set_voice_modulation_value("INACTIVE")

func _start_waiting_timer(frequency_id: int, dialogue_id: String):
	if waiting_timers.has(frequency_id):
		waiting_timers[frequency_id].queue_free()
		waiting_timers.erase(frequency_id)
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = false
	timer.set_meta("frequency_id", frequency_id)
	timer.set_meta("dialogue_id", dialogue_id)
	timer.set_meta("remaining", waiting_duration_minutes)
	timer.timeout.connect(func():
		var rem = timer.get_meta("remaining") - 1
		timer.set_meta("remaining", rem)
		if rem <= 0:
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

func try_resume_waiting_dialogue(frequency_id: int):
	if not waiting_timers.has(frequency_id):
		return
	var dialogue_id = waiting_timers[frequency_id].get_meta("dialogue_id")
	EventsManager.set_dialogue_status(dialogue_id, "active")
	active_dialogues[frequency_id] = {
		"tree_id": dialogue_id,
		"current_node": "start"
	}
	waiting_timers[frequency_id].stop()
	waiting_timers[frequency_id].queue_free()
	waiting_timers.erase(frequency_id)
	frequency_active[frequency_id] = true
	emit_signal("dialogue_started", frequency_id)
	_show_current_node(frequency_id)
	if TimeManager:
		TimeManager.stop()

func _show_current_node(frequency_id: int):
	if not active_dialogues.has(frequency_id):
		return
	var tree_id = active_dialogues[frequency_id]["tree_id"]
	var node_id = active_dialogues[frequency_id]["current_node"]
	var tree = dialogue_data.get(tree_id, {})
	# fallback logic...
	var node = tree[node_id]
	if not _check_conditions(node):
		end_dialogue(frequency_id)
		return
	var message_data = {
		"body": node.get("message", ""),
		"sender": node.get("sender", "operator"),
		"voice_modulation": node.get("voice_modulation", "Normal"),
		"audio": node.get("audio", null),
		"date": TimeManager.get_time(),
		"bg_audio": node.get("bg_audio", null)
	}
	if message_data.voice_modulation != null:
		GameManager.set_voice_modulation_value(message_data.voice_modulation)
	var history = frequency_histories.get(frequency_id, [])
	if history.size() == 0 or history[-1]["body"] != message_data["body"]:
		_add_message_to_history(frequency_id, message_data)
		emit_signal("message_added", frequency_id, message_data)
	if message_data.audio:
		AudioManager.play_voice(load(message_data.audio))
	if message_data.bg_audio:
		AudioManager.play_music(load(message_data.bg_audio))
	var reply_options := []
	for reply in node.get("replies", []):
		if _check_conditions(reply):
			reply_options.append(reply)
	emit_signal("reply_options_changed", frequency_id, reply_options)
	if reply_options.size() == 0:
		end_dialogue(frequency_id)

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

	# Hide reply options immediately after picking a reply
	emit_signal("reply_options_changed", frequency_id, [])

	EventsManager.set_dialogue_status(tree_id, "in_progress")
	for flag in reply.get("set_flags", []):
		EventsManager.set_flag(flag)
	if reply.has("custom_event"):
		EventsManager.trigger_event(reply["custom_event"], reply.get("custom_payload", {}))
		emit_signal("system_message", "[SYSTEM] Event triggered: %s" % reply["custom_event"])

	# Delayed outcome logic
	if reply.has("delay") and reply.has("outcomes"):
		var delay_range = reply["delay"]
		var outcomes = reply["outcomes"]
		var delay_time = randi_range(delay_range[0], delay_range[1])
		var next_node = _pick_weighted_node(outcomes)
		_schedule_delayed_dialogue(frequency_id, tree_id, next_node, delay_time)
		GameManager.set_voice_modulation_value("INACTIVE")
		end_dialogue(frequency_id)
		return

	if reply.has("next"):
		active_dialogues[frequency_id]["current_node"] = reply["next"]
		_show_current_node(frequency_id)
	elif reply.get("end_dialogue", false):
		GameManager.set_voice_modulation_value("INACTIVE")
		end_dialogue(frequency_id)
	else:
		GameManager.set_voice_modulation_value("INACTIVE")
		end_dialogue(frequency_id)

# Weighted random outcome picker
func _pick_weighted_node(outcomes: Array) -> String:
	var total = 0
	for outcome in outcomes:
		total += outcome["weight"]
	var pick = randi() % int(total)
	var acc = 0
	for outcome in outcomes:
		acc += outcome["weight"]
		if pick < acc:
			return outcome["node"]
	return outcomes[0]["node"]

# Schedules a follow-up dialogue after delay (puts as pending/standby)
func _schedule_delayed_dialogue(frequency_id: int, dialogue_id: String, node_id: String, delay_seconds: int):
	var timer = Timer.new()
	timer.wait_time = delay_seconds
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_on_delayed_dialogue_timeout").bind(frequency_id, dialogue_id, node_id))
	add_child(timer)
	timer.start()

func _on_delayed_dialogue_timeout(frequency_id: int, dialogue_id: String, node_id: String):
	start_dialogue(frequency_id, dialogue_id, node_id)

# --- End new delayed outcome logic ---

func _check_conditions(obj: Dictionary) -> bool:
	if not obj.has("conditions"):
		return true
	for cond in obj["conditions"]:
		if cond.begins_with("not_"):
			var flag = cond.substr(4)
			if EventsManager.get_flag(flag):
				return false
		else:
			if not EventsManager.get_flag(cond):
				return false
	return true

func _add_message_to_history(frequency_id: int, message_data: Dictionary):
	if not frequency_histories.has(frequency_id):
		frequency_histories[frequency_id] = []
	frequency_histories[frequency_id].append(message_data)

func get_message_history(frequency_id: int) -> Array:
	return frequency_histories.get(frequency_id, [])

func is_dialogue_active(frequency_id: int) -> bool:
	return frequency_active.get(frequency_id, false)

func get_dialogue_status(dialogue_id: String) -> String:
	return EventsManager.get_dialogue_status(dialogue_id)

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
	var unused_dialogues = []
	for d_id in dialogue_data.keys():
		if EventsManager.get_dialogue_status(d_id) == "off":
			unused_dialogues.append(d_id)
	if unused_dialogues.size() == 0:
		return false
	var chosen_dialogue = unused_dialogues.pick_random()
	start_dialogue(freq["id"], chosen_dialogue)
	return true

func add_message(frequency_id: int, message_data: Dictionary):
	_add_message_to_history(frequency_id, message_data)
	emit_signal("message_added", frequency_id, message_data)
	save_message_history()

func set_flag(flag: String, value: bool = true):
	EventsManager.set_flag(flag, value)

func get_flag(flag: String) -> bool:
	return EventsManager.get_flag(flag)

func reset_all():
	frequency_histories = {}
	active_dialogues = {}
	frequency_active = {}
	save_message_history()
