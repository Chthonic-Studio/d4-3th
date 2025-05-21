extends Button

@onready var label = $Label

var can_reply := true
var reply_tooltip_text := "Enable Reply and Mic to send a response."

func setup(reply_text: String, is_enabled: bool):
	label.text = reply_text
	self.disabled = not is_enabled
	if not is_enabled:
		self.hint_tooltip = tooltip_text
	else:
		self.hint_tooltip = ""
