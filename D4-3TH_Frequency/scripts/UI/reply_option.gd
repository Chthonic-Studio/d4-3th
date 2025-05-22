extends Button

@onready var label = $replyText

var can_reply := true
var reply_tooltip_text := "Enable Reply and Mic to send a response."

func _ready() -> void:
	GameManager.connect("reply_conditions_changed", Callable(self, "_on_reply_conditions_changed"))

func setReply():
	label = $replyText

func setup(reply_text: String, is_enabled: bool):
	if label == null:
		setReply()
	else:
		pass
	label.text = reply_text
	self.disabled = not is_enabled
	if not is_enabled:
		self.tooltip_text = reply_tooltip_text
	else:
		self.tooltip_text = ""
	print("ReplyOption setup: text=", reply_text, " enabled=", is_enabled, " disabled=", self.disabled)

func _on_reply_conditions_changed(reply_on: bool, mic_on: bool):
	var enabled = reply_on and mic_on
	self.disabled = not enabled
	if not enabled:
		self.tooltip_text = reply_tooltip_text
	else:
		self.tooltip_text = ""
