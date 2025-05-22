extends Button

@onready var label = $replyText

var can_reply := true
var reply_tooltip_text := "Enable Reply and Mic to send a response."

func _ready() -> void:
	GameManager.connect("reply_conditions_changed", Callable(self, "_on_reply_conditions_changed"))
	GameManager.connect("listen_toggled", Callable(self, "_on_reply_conditions_changed"))
	# Listen for both reply and listen toggle changes
	
func setReply():
	label = $replyText

func setup(reply_text: String, is_enabled: bool):
	if label == null:
		label = $replyText
	label.text = reply_text
	self.disabled = not is_enabled
	self.tooltip_text = reply_tooltip_text if not is_enabled else ""
	
func _on_reply_conditions_changed(_a = null, _b = null):
	var enabled = GameManager.replyOn and GameManager.micOn and GameManager.listenOn
	self.disabled = not enabled
	self.tooltip_text = reply_tooltip_text if not enabled else ""
