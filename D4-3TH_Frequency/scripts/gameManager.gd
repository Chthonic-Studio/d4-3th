extends Node

signal game_started
signal game_over
signal frequency_changed(frequency: int)
signal active_frequency_changed(frequency: int)
signal frequencies_updated

@onready var FrequencyOptions = preload("res://scripts/lists/frequencyOptions.gd").new()
@onready var ThreatTraits = preload("res://scripts/lists/threatTraits.gd").new()
@onready var Names = preload("res://scripts/lists/names.gd").new()

var is_game_running: bool = false
var frequencies := []
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
	# Reset all relevant state for a new run
	is_game_running = false
	# Reset other systems

func signal_number_changed(frequency: int) -> void:
	print("Active signal changed to: ", frequency)
	emit_signal("frequency_changed", frequency)
	emit_signal("active_frequency_changed", frequency)

func initialize_run():
	generate_threat_traits()
	generate_frequencies()

func generate_threat_traits():
	print("Generating threat traits")
	threat_traits = []
	var pool = ThreatTraits.TRAITS.duplicate()
	pool.shuffle()
	# Pick 4 random traits
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
