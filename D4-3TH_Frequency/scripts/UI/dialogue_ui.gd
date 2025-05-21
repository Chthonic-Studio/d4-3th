extends NinePatchRect

@onready var scroll = $dialogueScroll
@onready var vbox = $dialogueScroll/dialogueVbox
@onready var reply_vbox = $replyContainer/replyVbox

var MessageBubble = preload("res://scenes/message_bubble.tscn")
var ReplyOption = preload("res://scenes/reply_option.tscn")

var frequency_id = null

func _ready():
	DialogueManager.connect("message_added", Callable (self, "_on_message_added"))
	DialogueManager.connect("reply_options_changed", Callable (self, "_on_reply_options_changed"))
	GameManager.connect("frequency_changed_dialogue", Callable(self, "_update_dialogue_visibility"))
	GameManager.connect("listen_toggled", Callable(self, "_update_dialogue_visibility"))

func _populate_history():
	vbox.clear()
	var history = DialogueManager.get_message_history(frequency_id)
	for msg in history:
		var bubble = MessageBubble.instantiate()
		bubble.setup(msg)
		vbox.add_child(bubble)
	_scroll_to_bottom()

func _on_message_added(msg_freq_id, msg):
	if msg_freq_id != frequency_id: return
	var bubble = MessageBubble.instantiate()
	bubble.setup(msg)
	vbox.add_child(bubble)
	_scroll_to_bottom()

func _on_reply_options_changed(msg_freq_id, options):
	if msg_freq_id != frequency_id: return
	reply_vbox.clear()
	# Check toggles from BottomPanel
	var can_reply = GameManager.replyOn and GameManager.micOn
	for i in range(options.size()):
		var opt = options[i]
		var reply = ReplyOption.instantiate()
		reply.setup(opt.text, can_reply)
		reply.connect("pressed", func():
			if can_reply:
				DialogueManager.choose_reply(frequency_id, i)
			else:
				# Optionally show a popup/tooltip
				pass
		)
		reply_vbox.add_child(reply)

func _scroll_to_bottom():
	await get_tree().process_frame # Ensures layout is updated
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func show_for_frequency(id):
	frequency_id = id
	_populate_history()
	_update_dialogue_visibility()

func _update_dialogue_visibility():
	var current_freq = GameManager.current_frequency
	var listen_on = GameManager.listenOn
	# Only visible if on the right frequency and Listen is ON
	if frequency_id == current_freq and listen_on:
		self.visible = true
	else:
		self.visible = false
