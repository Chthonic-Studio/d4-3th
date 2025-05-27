extends Node

# USAGE
# --- Flags ---
# Set a global flag:
#   EventsManager.set_flag("heard_distress_call")
# Get a global flag:
#   EventsManager.get_flag("heard_distress_call")
#
# Set a frequency-specific flag:
#   EventsManager.set_frequency_flag(1234, "responded", true)
# Get a frequency-specific flag:
#   EventsManager.get_frequency_flag(1234, "responded")
#
# --- Dialogue Status ---
# Set dialogue status (e.g., "onStandby", "waiting", "done", "lost", etc.):
#   EventsManager.set_dialogue_status("intro_commander", "onStandby")
# Get dialogue status:
#   EventsManager.get_dialogue_status("intro_commander")
#
# --- Custom Events ---
# Trigger a custom event (with optional payload):
#   EventsManager.trigger_event("entity_mimic_detected", {"frequency_id": 1572})
#
# --- Persistence ---
# Save all progression (flags and dialogue statuses):
#   EventsManager.save_progression()
# Load all progression:
#   EventsManager.load_progression()
# Reset all progression for a new run:
#   EventsManager.reset_all()
#
# Save or load just dialogue status (rarely needed directly):
#   EventsManager.save_dialogue_status()
#   EventsManager.load_dialogue_status()
#   EventsManager.reset_dialogue_status()

signal flag_changed(flag_name: String, value: Variant)
signal event_triggered(event_name: String, payload: Dictionary)
signal progression_loaded()
signal progression_saved()
signal dialogue_status_changed(dialogue_id: String, status: String)

# Flags/variables
var global_flags := {}         	# {flag_name: value}
var frequency_flags := {}      	# {frequency_id: {flag_name: value}}
var dialogue_status := {}		# { dialogue_id: status }

@export var dialogue_status_save_path := "user://dialogue_status.save"

@export var save_path := "user://progression.save"

var camera_feed: Node = null

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

# Set dialogue status (call this whenever a status changes)
func set_dialogue_status(dialogue_id: String, status: String):
	dialogue_status[dialogue_id] = status
	emit_signal("dialogue_status_changed", dialogue_id, status)
	save_dialogue_status()

# Get dialogue status
func get_dialogue_status(dialogue_id: String) -> String:
	return dialogue_status.get(dialogue_id, "off")

# Save/load dialogue statuses (per run)
func save_dialogue_status():
	var file = FileAccess.open(dialogue_status_save_path, FileAccess.WRITE)
	if file:
		file.store_var(dialogue_status)
		file.close()

func load_dialogue_status():
	if not FileAccess.file_exists(dialogue_status_save_path):
		return
	var file = FileAccess.open(dialogue_status_save_path, FileAccess.READ)
	if file:
		dialogue_status = file.get_var()
		file.close()

# Reset dialogue statuses for new run
func reset_dialogue_status():
	dialogue_status = {}
	save_dialogue_status()

# SAVE/LOAD

func save_progression():
	var data = {
		"global_flags": global_flags,
		"frequency_flags": frequency_flags,
		"dialogue_status": dialogue_status
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
		dialogue_status = data.get("dialogue_status", {})
		file.close()
		emit_signal("progression_loaded")

func reset_all():
	global_flags = {}
	frequency_flags = {}
	dialogue_status = {}
	save_progression()
	
	
