extends VBoxContainer

@onready var sender_label = $message_sender
@onready var body_label = $message_body

signal reveal_complete

var reveal_speed := 0.03 # seconds per character
var reveal_timer = null
var pending_message = null
var reveal_index := 0
var did_reveal := false

func _ready() -> void:
	pass

func defineLabels() -> void:
	sender_label = $message_sender
	body_label = $message_body

# Add 'reveal_instantly' param, default false
func setup(message: Dictionary, reveal_instantly := false):
	if sender_label == null:
		defineLabels()
	else:
		pass
	var sender = message.get("sender", "???")
	var time_string = _format_time(message.get("date", {}))
	var body = message.get("body", "")
	var full_text = "[%s] %s" % [time_string, body]

	sender_label.text = sender

	if sender == "Player":
		body_label.text = full_text
		self.add_theme_color_override("bg_color", Color(0.1, 0.2, 0.5, 0.2))
	else:
		if reveal_instantly:
			body_label.text = full_text
			emit_signal("reveal_complete", self)
		else:
			body_label.text = ""
			call_deferred("_reveal_word_by_word", full_text)
		self.add_theme_color_override("bg_color", Color(0.2, 0.2, 0.2, 0.2))

	# Forward voice modulation to GameManager (for BottomPanel)
	if message.has("voice_modulation"):
		GameManager.set_voice_modulation_value(message["voice_modulation"])

func prepare_reveal(full_text: String):
	pending_message = full_text
	did_reveal = false
	body_label.text = "" 

func trigger_reveal():
	if pending_message and not did_reveal:
		_reveal_word_by_word(pending_message)
		did_reveal = true

func _reveal_word_by_word(full_text):
	if reveal_timer:
		reveal_timer.stop()
		reveal_timer.queue_free()
		
	body_label.text = ""
	var chars = full_text.split("")
	reveal_index = 0
	
	reveal_timer = Timer.new()
	reveal_timer.wait_time = reveal_speed
	reveal_timer.one_shot = false
	
	add_child(reveal_timer)
	
	reveal_timer.timeout.connect(func():
		if reveal_index < chars.size():
			body_label.text += chars[reveal_index]
			reveal_index += 1
		else:
			reveal_timer.stop()
			reveal_timer.queue_free()
			reveal_timer = null
			emit_signal("reveal_complete", self)
	)
	reveal_timer.start()
	

func _format_time(time_dict):
	if not time_dict or not time_dict.has("day"):
		return ""
	var hour = "%02d" % time_dict.hour
	var minute = "%02d" % time_dict.minute
	var month = "%02d" % (time_dict.month if time_dict.has("month") else 5)	
	var day = "%02d" % time_dict.day
	return "%s:%s, %s/%s" % [hour, minute, month, day]

func is_revealing() -> bool:
	return reveal_timer != null	
