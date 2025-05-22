extends NinePatchRect

@onready var scroll = $dialogueScroll
@onready var vbox = $dialogueScroll/dialogueVbox
@onready var reply_vbox = $replyContainer/replyVbox
@onready var toggle_dialogue_button = $"../../closeDialogueUI"
@onready var bottom_panel = $"../../BottomPanel"

var MessageBubble = preload("res://scenes/message_bubble.tscn")
var ReplyOption = preload("res://scenes/reply_option.tscn")

var last_conditions_met := false # Track previous state to avoid redundant calls

var pending_reply_options = []

var frequency_id = null

func _ready():
	DialogueManager.connect("message_added", Callable (self, "_on_message_added"))
	DialogueManager.connect("reply_options_changed", Callable (self, "_on_reply_options_changed"))
	DialogueManager.connect("dialogue_started", Callable(self, "_on_dialogue_started"))
	GameManager.connect("frequency_changed_dialogue", Callable(self, "_update_dialogue_visibility"))
	GameManager.connect("listen_toggled", Callable(self, "_update_dialogue_visibility"))
	GameManager.connect("reply_conditions_changed", Callable(self, "_on_conditions_changed"))
	bottom_panel.connect("dialogue_conditions_possibly_changed", Callable(self, "_on_conditions_changed"))
	# Call _on_conditions_changed on player toggling switches or changing frequency
	toggle_dialogue_button.pressed.connect(_on_toggle_dialogue_pressed)
	toggle_dialogue_button.tooltip_text = "Show/Hide dialogue"
	self.visible = false

func _on_dialogue_started(frequency_id):
	if frequency_id == GameManager.current_frequency:
		show_for_frequency(frequency_id)
	_on_conditions_changed()

# --- NEW: Centralized check for all dialogue conditions and UI visibility ---
func _on_conditions_changed(_a = null, _b = null):
	var current_freq = GameManager.current_frequency
	var listen_on = GameManager.listenOn
	var reply_on = GameManager.replyOn
	
	# Check for active/pending/waiting dialogue for this frequency
	var status: String = ""
	if DialogueManager.frequency_pending_dialogue.has(current_freq):
		status = EventsManager.get_dialogue_status(DialogueManager.frequency_pending_dialogue[current_freq])
	elif DialogueManager.active_dialogues.has(current_freq):
		status = "active"
	elif DialogueManager.waiting_timers.has(current_freq):
		status = "waiting"
	else:
		status = "off"
	
	var conditions_met = (frequency_id == current_freq and listen_on and reply_on and (status == "onStandby" or status == "active" or status == "waiting"))
	
	# Track previous conditions_met state for interruption logic
	var was_met = last_conditions_met
	last_conditions_met = conditions_met
	
	# Only show UI if all conditions met
	self.visible = conditions_met
	
	# Handle dialogue activation/resume/interruption
	if conditions_met:
		if status == "onStandby":
			DialogueManager.try_activate_dialogue(current_freq)
		elif status == "waiting":
			DialogueManager.try_resume_waiting_dialogue(current_freq)
	else:
		# Only interrupt if transitioning from visible to not visible
		if was_met and DialogueManager.active_dialogues.has(current_freq):
			DialogueManager.interrupt_active_dialogue(current_freq)
		self.visible = false

	# Pause/resume time as a fallback
	if self.visible and status == "active":
		if TimeManager:
			TimeManager.stop()
	else:
		if TimeManager:
			TimeManager.start()

func _populate_history():
	for child in vbox.get_children():
		child.queue_free()
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
	bubble.connect("reveal_complete", Callable(self, "_on_bubble_reveal_complete"))
	_scroll_to_bottom()

func _on_reply_options_changed(msg_freq_id, options):
	if msg_freq_id != frequency_id: return
	for child in reply_vbox.get_children():
		child.queue_free()
	pending_reply_options = options
	# Do NOT add reply buttons here!

func _on_bubble_reveal_complete():
	# Only show reply options now
	for child in reply_vbox.get_children():
		child.queue_free()
	var can_reply = GameManager.replyOn and GameManager.micOn and GameManager.listenOn
	for i in range(pending_reply_options.size()):
		var opt = pending_reply_options[i]
		var reply = ReplyOption.instantiate()
		reply.setup(opt.text, can_reply)
		var idx = i
		reply.pressed.connect(func():
			var can_reply_now = GameManager.replyOn and GameManager.micOn and GameManager.listenOn
			if can_reply_now:
				DialogueManager.choose_reply(frequency_id, idx)
		)
		reply_vbox.add_child(reply)

func _scroll_to_bottom():
	await get_tree().process_frame # Ensures layout is updated
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func show_for_frequency(id):
	frequency_id = id
	_populate_history()
	_on_conditions_changed()

func _update_dialogue_visibility():
	var current_freq = GameManager.current_frequency
	var listen_on = GameManager.listenOn
	
	# Only visible if on the right frequency and Listen is ON
	if frequency_id == current_freq and listen_on:
		self.visible = true
		for bubble in vbox.get_children():
			if bubble.has_method("trigger_reveal"):
				bubble.trigger_reveal()
	else:
		self.visible = false

func _on_toggle_dialogue_pressed():
	# Only allow hiding if no active dialogue
	if DialogueManager.is_dialogue_active(frequency_id):
	# Optionally show a message or play a sound
		toggle_dialogue_button.tooltip_text = "Cannot close dialogue while a conversation is active!"
		return
	# Toggle visibility
	toggle_dialogue_button.tooltip_text = "Show/Hide dialogue"
	self.visible = not self.visible
