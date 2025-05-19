extends Label

var frequency_id: int = -1
@onready var button = $foundFrequencyButton

func set_frequency_data(freq: Dictionary):
	frequency_id = freq["id"]
	self.text = str(freq["id"])
	match freq["status"]:
		"ONLINE":
			self.modulate = Color(0.2, 1.0, 0.2)
		"OFFLINE":
			self.modulate = Color(1, 1, 1)
		"COMPROMISED":
			self.modulate = Color(1, 0.1, 0.1)

func set_active(is_active: bool):
	self.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0) if is_active else Color(1,1,1))
