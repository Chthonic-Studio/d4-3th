extends HBoxContainer

@onready var sender_label = $Sender
@onready var body_label = $Body

var reveal_speed := 0.03 # seconds per character
var reveal_timer = null

func setup(message: Dictionary):
	var sender = message.get("sender", "???")
	var time_string = _format_time(message.get("date", {}))
	var body = message.get("body", "")
	# Compose full text: "[hh:mm, MM/DD] <body>"
	var full_text = "[%s] %s" % [time_string, body]

	sender_label.text = sender

	if sender == "Player":
		body_label.text = full_text
		self.add_theme_color_override("bg_color", Color(0.1, 0.2, 0.5, 0.2))
	else:
		body_label.text = ""
		_reveal_word_by_word(full_text)
		self.add_theme_color_override("bg_color", Color(0.2, 0.2, 0.2, 0.2))

	# Forward voice modulation to GameManager (for BottomPanel)
	if message.has("voice_modulation"):
		GameManager.set_voice_modulation_value(message["voice_modulation"])

func _reveal_word_by_word(full_text):
	if reveal_timer:
		reveal_timer.stop()
		reveal_timer.queue_free()
	body_label.text = ""
	var chars = full_text.split("")
	var index = 0
	reveal_timer = Timer.new()
	reveal_timer.wait_time = reveal_speed
	reveal_timer.one_shot = false
	reveal_timer.connect("timeout", func():
		if index < chars.size():
			body_label.text += chars[index]
			index += 1
		else:
			reveal_timer.stop()
			reveal_timer.queue_free()
	)
	add_child(reveal_timer)
	reveal_timer.start()

func _format_time(time_dict):
	if not time_dict or not time_dict.has("day"):
		return ""
	var hour = "%02d" % time_dict.hour
	var minute = "%02d" % time_dict.minute
	var month = "%02d" % (time_dict.month if time_dict.has("month") else 5)	
	var day = "%02d" % time_dict.day
	return "%s:%s, %s/%s" % [hour, minute, month, day]
