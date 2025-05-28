extends Label

var frequency_id: int = -1
@onready var button = $foundFrequencyButton

func set_frequency_data(freq: Dictionary):
	frequency_id = freq["id"]
	self.text = str(freq["id"])
	var state = GameManager.get_frequency_state(freq)
	match state:
		"normal":
			self.modulate = Color(0.2, 1.0, 0.2)
			_stop_flashing(self)
		"no_standby":
			self.modulate = Color(1, 1, 1)
			_stop_flashing(self)
		"compromised":
			self.modulate = Color(1, 0.1, 0.1)
			_stop_flashing(self)
		"emergency":
			self.modulate = Color(0.2, 1.0, 0.2)
			_start_flashing(self, Color(0.2, 1.0, 0.2), Color(1, 1, 1))

func set_active(is_active: bool):
	self.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0) if is_active else Color(1,1,1))

# Helper for flashing, attach a Timer to label if needed
func _start_flashing(label: Label, color_a: Color, color_b: Color):
	if not label.has_node("flash_timer"):
		var timer = Timer.new()
		timer.name = "flash_timer"
		timer.wait_time = 0.5
		timer.one_shot = false
		timer.autostart = true
		timer.connect("timeout", Callable(self, "_on_flash_timer_timeout").bind(label, color_a, color_b))
		label.add_child(timer)
		timer.start()
func _stop_flashing(label: Label):
	if label.has_node("flash_timer"):
		label.get_node("flash_timer").queue_free()
		label.modulate = Color(1,1,1)
func _on_flash_timer_timeout(label: Label, color_a: Color, color_b: Color):
	label.modulate = color_b if label.modulate == color_a else color_a
