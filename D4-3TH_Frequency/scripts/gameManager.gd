extends Node

signal game_started
signal game_over

signal frequency_changed(frequency: int)
signal active_frequency_changed(frequency: int)
signal frequencies_updated
signal found_frequencies_updated

@onready var FrequencyOptions = preload("res://scripts/lists/frequencyOptions.gd").new()
@onready var ThreatTraits = preload("res://scripts/lists/threatTraits.gd").new()
@onready var Names = preload("res://scripts/lists/names.gd").new()

var is_game_running: bool = false
var frequencies := []
var found_frequencies := []
var threat_traits := []
var personnel := []

var frequency_update_interval = 0.4

var status = ["ONLINE", "OFFLINE", "COMPROMISED"]

func _ready():
	initialize_run()

func start_game():
	is_game_running = true
	emit_signal("game_started")
	# Initialize other systems as needed

func end_game():
	is_game_running = false
	emit_signal("game_over")
	# Handle end game logic

func reset_game():
	is_game_running = false
	# Reset other systems

func signal_number_changed(frequency: int) -> void:
	print("Active signal changed to: ", frequency)
	emit_signal("frequency_changed", frequency)
	emit_signal("active_frequency_changed", frequency)

func initialize_run():
	generate_threat_traits()
	generate_frequencies()
	found_frequencies.clear() # Reset founds on new run

func generate_threat_traits():
	print("Generating threat traits")
	threat_traits = []
	var pool = ThreatTraits.TRAITS.duplicate()
	pool.shuffle()
	threat_traits = pool.slice(0, 4)

func generate_frequencies():
	print("Generating Frequencies")
	frequencies.clear()
	var freq_ids := {}
	freq_ids[1001] = true # Always add command center

	# Use "Army" for command center
	var freq_type = "Army"
	var ranges = FrequencyOptions.STATS_RANGES[freq_type]
	var operator_name = Names.get_random_operator_name()
	frequencies.append({
		"id": 1001,
		"operator": operator_name,
		"type": freq_type,
		"signal_integrity_range": ranges["signal_integrity"],
		"error_rate_range": ranges["error_rate"],
		"latency_range": ranges["latency"],
		"transponder_dots_range": ranges["transponder_dots"],
		"transponder_signature": "RECOGNIZED",
		"personnel": [],
		"status": "ONLINE",
		"data_entries": ["1001", "Operator: General " + operator_name, "Type: Command Center"]
	})

	while frequencies.size() < 30:
		var id = randi_range(1002, 9899)
		if freq_ids.has(id): continue    
		freq_ids[id] = true
		freq_type = FrequencyOptions.TYPES.pick_random()
		ranges = FrequencyOptions.STATS_RANGES[freq_type]
		operator_name = Names.get_random_operator_name()
		frequencies.append({
			"id": id,
			"operator": operator_name,
			"type": freq_type,
			"signal_integrity_range": ranges["signal_integrity"],
			"error_rate_range": ranges["error_rate"],
			"latency_range": ranges["latency"],
			"transponder_dots_range": ranges["transponder_dots"],
			"transponder_signature": "RECOGNIZED",
			"personnel": [],
			"status": status.pick_random(),
			"data_entries": [str(id), "Operator: " + operator_name, "Type: " + freq_type]
		})

	emit_signal("frequencies_updated")

# Utility: Get all used frequency IDs (known + found)
func get_all_frequency_ids() -> Dictionary:
	var ids = {}
	for f in frequencies:
		ids[f.id] = true
	for f in found_frequencies:
		ids[f.id] = true
	return ids

# Found Frequencies
# Accepts either a partial or full dictionary, fills randoms as needed

# Example: add_found_frequency({ "type": "Civilian" }) or add_found_frequency({ ...full_dict... })
# GameManager.add_found_frequency({ "type": "Civilian", "operator": "Lt. Novak" })
# or for random civilian:
# GameManager.add_found_frequency({ "type": "Civilian" })
# or full custom:
# GameManager.add_found_frequency({ "id": 1234, "type": "Entity", "status": "ONLINE", ... })

func add_found_frequency(freq_dict := {}):
	var ids = get_all_frequency_ids()
	var id = freq_dict["id"] if freq_dict.has("id") else 0
	if id == 0:
		# Generate a unique id
		while true:
			id = randi_range(1002, 9899)
			if not ids.has(id):
				break
	else:
		if ids.has(id):
			push_warning("Duplicate frequency id for found frequency: %s" % id)
			return
	freq_dict["id"] = id

	# Set or randomize other fields as needed
	var freq_type = freq_dict["type"] if freq_dict.has("type") else FrequencyOptions.TYPES.pick_random()
	var ranges = FrequencyOptions.STATS_RANGES[freq_type]
	freq_dict["type"] = freq_type
	freq_dict["signal_integrity_range"] = freq_dict["signal_integrity_range"] if freq_dict.has("signal_integrity_range") else ranges["signal_integrity"]
	freq_dict["error_rate_range"] = freq_dict["error_rate_range"] if freq_dict.has("error_rate_range") else ranges["error_rate"]
	freq_dict["latency_range"] = freq_dict["latency_range"] if freq_dict.has("latency_range") else ranges["latency"]
	freq_dict["transponder_dots_range"] = freq_dict["transponder_dots_range"] if freq_dict.has("transponder_dots_range") else ranges["transponder_dots"]
	freq_dict["transponder_signature"] = freq_dict["transponder_signature"] if freq_dict.has("transponder_signature") else "RECOGNIZED"
	freq_dict["operator"] = freq_dict["operator"] if freq_dict.has("operator") else Names.get_random_operator_name()
	freq_dict["personnel"] = freq_dict["personnel"] if freq_dict.has("personnel") else []
	freq_dict["status"] = freq_dict["status"] if freq_dict.has("status") else status.pick_random()
	freq_dict["data_entries"] = freq_dict["data_entries"] if freq_dict.has("data_entries") else [str(freq_dict["id"]), "Operator: " + freq_dict["operator"], "Type: " + freq_type]

	found_frequencies.append(freq_dict)
	emit_signal("found_frequencies_updated")
