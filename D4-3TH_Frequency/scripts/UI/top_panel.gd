extends MarginContainer

@onready var timeLabel = $TopPanelRect/timeLabel
@onready var musicOn = $TopPanelRect/musicOn
@onready var musicOff = $TopPanelRect/musicOff
@onready var musicButton = $TopPanelRect/musicButton

func _ready():
	# Connect to timeManager's time_updated signal
	TimeManager.connect("time_updated", Callable(self, "_on_time_updated"))
	
	# Set the initial time
	timeLabel.text = TimeManager.get_time_string()

func _on_time_updated(hour: int, minute: int) -> void:
	# Update the label with the new time
	timeLabel.text = "%02d:%02d" % [hour, minute]


func _on_reply_button_pressed() -> void:
	pass # Replace with function body.
