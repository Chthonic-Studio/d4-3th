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
var waiting_for_reveal := false
var last_bubble_with_reply: Node = null

var frequency_id = null

func _ready():
	DialogueManager.connect("message_added", Callable (self, "_on_message_added"))
	DialogueManager.connect("reply_options_changed", Callable (self, "_on_reply_options_changed"))
	DialogueManager.connect("dialogue_started", Callable(self, "_on_dialogue_started"))
	GameManager.connect("frequency_changed_dialogue", Callable(self, "_update_dialogue_visibility"))
	GameManager.connect("listen_toggled", Callable(self, "_update_dialogue_visibility"))
	GameManager.connect("reply_conditions_changed", Callable(self, "_on_conditions_changed"))
	GameManager.connect("active_frequency_changed", Callable(self, "_on_active_frequency_changed"))
	bottom_panel.connect("dialogue_conditions_possibly_changed", Callable(self, "_on_conditions_changed"))
	# Call _on_conditions_changed on player toggling switches or changing frequency
	toggle_dialogue_button.pressed.connect(_on_toggle_dialogue_pressed)
	toggle_dialogue_button.tooltip_text = "Show/Hide dialogue"
	self.visible = false

func _on_dialogue_started(frequency_id):
	if frequency_id == GameManager.current_frequency:
		show_for_frequency(frequency_id)
	self.visible = true
	_on_conditions_changed()

func _on_active_frequency_changed(new_id: int):
	show_for_frequency(new_id)

func _on_conditions_changed(_a = null, _b = null):
	var current_freq = GameManager.current_frequency
	var listen_on = GameManager.listenOn
	var reply_on = GameManager.replyOn
	var status: String = ""
	if frequency_id == null:
		frequency_id = GameManager.current_frequency
	
	if DialogueManager.frequency_pending_dialogue.has(current_freq):
		var pending = DialogueManager.frequency_pending_dialogue[current_freq]
		var pending_id = pending if pending is String else pending.get("id", "")
		status = EventsManager.get_dialogue_status(pending_id)
	elif DialogueManager.active_dialogues.has(current_freq):
		status = "active"
	elif DialogueManager.waiting_timers.has(current_freq):
		status = "waiting"
	else:
		status = "off"
	
	print("DIALOGUE UI: freq_id=%s current_freq=%s listen=%s reply=%s status=%s" % [str(frequency_id), str(current_freq), str(listen_on), str(reply_on), status])
	
	var conditions_met = (frequency_id == current_freq and listen_on and reply_on and (status == "onStandby" or status == "active" or status == "waiting"))
	var was_met = last_conditions_met
	last_conditions_met = conditions_met
	self.visible = conditions_met
	
	if conditions_met:
		if status == "onStandby":
			print("DIALOGUE UI: Trying to activate dialogue for freq %s" % str(current_freq))
			DialogueManager.try_activate_dialogue(current_freq)
		elif status == "waiting":
			DialogueManager.try_resume_waiting_dialogue(current_freq)
	else:
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
		bubble.setup(msg, true) # reveal_instantly = true for history
		vbox.add_child(bubble)
	_scroll_to_bottom()

func _on_message_added(msg_freq_id, msg):
	print("MESSAGE ADDED: freq_id=%s, msg=%s" % [str(msg_freq_id), str(msg)])
	if msg_freq_id != frequency_id: return
	var bubble = MessageBubble.instantiate()
	bubble.setup(msg) # <-- default is reveal_instantly = false
	vbox.add_child(bubble)
	bubble.connect("reveal_complete", Callable(self, "_on_bubble_reveal_complete").bind(bubble))
	_scroll_to_bottom()
	
	# --- Get current reply options for this message and update UI ---
	var current_node = null
	if DialogueManager.active_dialogues.has(frequency_id):
		var active = DialogueManager.active_dialogues[frequency_id]
		var node_id = active["current_node"]
		var tree_id = active["tree_id"]
		var tree = DialogueManager.dialogue_data.get(tree_id, {})
		if tree.has(node_id):
			current_node = tree[node_id]
	if current_node and current_node.has("replies"):
		var options = []
		for reply in current_node["replies"]:
			if DialogueManager._check_conditions(reply):
				options.append(reply)
		_on_reply_options_changed(frequency_id, options)
	else:
		_on_reply_options_changed(frequency_id, [])

func _on_reply_options_changed(msg_freq_id, options):
	if msg_freq_id != frequency_id:
		return
	_clear_reply_options() # Always clear first
	pending_reply_options = options

	if options.size() == 0:
		return

	# Setup for new reply options:
	if vbox.get_child_count() > 0:
		last_bubble_with_reply = vbox.get_child(vbox.get_child_count() - 1)
		if last_bubble_with_reply:
			# Disconnect previous (avoid stacking signals)
			last_bubble_with_reply.disconnect("reveal_complete", Callable(self, "_on_bubble_reveal_complete")) if last_bubble_with_reply.is_connected("reveal_complete", Callable(self, "_on_bubble_reveal_complete")) else null
			last_bubble_with_reply.connect("reveal_complete", Callable(self, "_on_bubble_reveal_complete"))
	else:
		last_bubble_with_reply = null

	# Hide reply options until reveal complete
	for child in reply_vbox.get_children():
		child.visible = false

func _show_reply_options():
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
	# Now show the buttons
	for child in reply_vbox.get_children():
		child.visible = true

func _on_bubble_reveal_complete(bubble):
	if last_bubble_with_reply and last_bubble_with_reply == bubble:
		_show_reply_options()

func _scroll_to_bottom():
	await get_tree().process_frame # Ensures layout is updated
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func show_for_frequency(id):
	frequency_id = id
	_populate_history()
	_on_conditions_changed()
	_clear_reply_options()

func _clear_reply_options():
	for child in reply_vbox.get_children():
		child.queue_free()
	pending_reply_options = []

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
	if not self.visible:
		self.visible = true
		toggle_dialogue_button.tooltip_text = "Show/Hide dialogue"
		return
	var check_freq_id = frequency_id if frequency_id != null else GameManager.current_frequency
	if check_freq_id != null and DialogueManager.is_dialogue_active(check_freq_id) and _is_message_revealing():
		toggle_dialogue_button.tooltip_text = "Cannot close dialogue while a message is revealing!"
		return
	self.visible = not self.visible
	toggle_dialogue_button.tooltip_text = "Show/Hide dialogue"
	

func _is_message_revealing() -> bool:
	for bubble in vbox.get_children():
		if bubble.has_method("is_revealing") and bubble.is_revealing():
			return true
	return false
