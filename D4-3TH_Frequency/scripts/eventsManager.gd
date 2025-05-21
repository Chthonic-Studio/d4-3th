extends Node

# USAGE
# From DialogueManager when a reply sets a flag
# EventsManager.set_flag("heard_distress_call")

# From DialogueManager when a reply triggers a custom event
# EventsManager.trigger_event("entity_mimic_detected", {"frequency_id": 1572})

# To check a flag in dialogue conditions
# EventsManager.get_flag("heard_distress_call")

# To handle game progression save/load:
# EventsManager.save_progression()
# EventsManager.load_progression()

signal flag_changed(flag_name: String, value: Variant)
signal event_triggered(event_name: String, payload: Dictionary)
signal progression_loaded()
signal progression_saved()

# Flags/variables
var global_flags := {}         # {flag_name: value}
var frequency_flags := {}      # {frequency_id: {flag_name: value}}

@export var save_path := "user://progression.save"

# Set a global flag/variable
func set_flag(flag_name: String, value: Variant = true):
	global_flags[flag_name] = value
	emit_signal("flag_changed", flag_name, value)

# Get a global flag/variable
func get_flag(flag_name: String) -> Variant:
	return global_flags.get(flag_name, false)

# Set a flag for a specific frequency
func set_frequency_flag(frequency_id: int, flag_name: String, value: Variant = true):
	if not frequency_flags.has(frequency_id):
		frequency_flags[frequency_id] = {}
	frequency_flags[frequency_id][flag_name] = value
	emit_signal("flag_changed", "%s_%s" % [frequency_id, flag_name], value)

# Get a flag for a specific frequency
func get_frequency_flag(frequency_id: int, flag_name: String) -> Variant:
	if not frequency_flags.has(frequency_id):
		return false
	return frequency_flags[frequency_id].get(flag_name, false)

# Emit a custom event (for dialogue, triggers, etc.)
func trigger_event(event_name: String, payload: Dictionary = {}):
	emit_signal("event_triggered", event_name, payload)

# SAVE/LOAD

func save_progression():
	var data = {
		"global_flags": global_flags,
		"frequency_flags": frequency_flags
	}
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()
		emit_signal("progression_saved")

func load_progression():
	if not FileAccess.file_exists(save_path):
		return
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var data = file.get_var()
		global_flags = data.get("global_flags", {})
		frequency_flags = data.get("frequency_flags", {})
		file.close()
		emit_signal("progression_loaded")

func reset_all():
	global_flags = {}
	frequency_flags = {}
	save_progression()
