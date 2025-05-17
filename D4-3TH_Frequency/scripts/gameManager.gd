extends Node

signal game_started
signal game_over

signal frequency_changed(frequency: int)

var is_game_running: bool = false

func _ready():
	pass

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
