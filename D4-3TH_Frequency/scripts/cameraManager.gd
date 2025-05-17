extends Node

signal camera_changed(active_camera_index: int)

var camera_feeds: Array = [] # Populate with references to camera feed nodes or IDs
var active_camera_index: int = 0

func _ready():
	# Initialize or assign camera feeds as needed
	pass

func set_camera(index: int):
	if index >= 0 and index < camera_feeds.size():
		active_camera_index = index
		emit_signal("camera_changed", active_camera_index)
		# Additional logic: update UI, focus camera, etc.

func next_camera():
	var next_index = (active_camera_index + 1) % camera_feeds.size()
	set_camera(next_index)

func prev_camera():
	var prev_index = (active_camera_index - 1 + camera_feeds.size()) % camera_feeds.size()
	set_camera(prev_index)

func reset():
	active_camera_index = 0
	emit_signal("camera_changed", active_camera_index)
