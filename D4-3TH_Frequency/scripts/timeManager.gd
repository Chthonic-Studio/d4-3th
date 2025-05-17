extends Node

signal time_updated(current_hour: int, current_minute: int)
signal day_passed(day_count: int)

var current_hour: int = 0
var current_minute: int = 0
var day_count: int = 1

const SECONDS_PER_INGAME_MINUTE: float = 0.5

var _tick_timer: Timer

func _ready():
	_tick_timer = Timer.new()
	_tick_timer.wait_time = SECONDS_PER_INGAME_MINUTE
	_tick_timer.one_shot = false
	add_child(_tick_timer)
	_tick_timer.connect("timeout", Callable(self, "_on_tick"))
	start() # Time starts passing when game starts

func start():
	_tick_timer.start()

func stop():
	_tick_timer.stop()

func reset():
	current_hour = 0
	current_minute = 0
	day_count = 1
	stop()
	emit_signal("time_updated", current_hour, current_minute)

func _on_tick():
	_advance_time()

func _advance_time():
	current_minute += 1
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
		if current_hour >= 24:
			current_hour = 0
			day_count += 1
			emit_signal("day_passed", day_count)
	emit_signal("time_updated", current_hour, current_minute)

# Fetch the current in-game time as a tuple (hour, minute)
func get_time() -> Dictionary:
	return {
		"hour": current_hour,
		"minute": current_minute,
		"day": day_count
	}

# Public function to get formatted time string (e.g., "09:04")
func get_time_string() -> String:
	return "%02d:%02d" % [current_hour, current_minute]

# Optional: advance time by a specific amount of minutes
func advance_minutes(minutes: int):
	for i in range(minutes):
		_advance_time()
