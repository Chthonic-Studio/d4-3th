## Attach to MenuPanel.
## Handles expand/collapse (on mouse enter/exit) and emits interaction_selected(action) on button press.
extends PanelContainer

signal interaction_selected(action: String)

@onready var vbox = $VBoxContainer
@onready var button_chat = $VBoxContainer/ButtonChat
@onready var button_look = $VBoxContainer/ButtonLook
@onready var button_torture = $VBoxContainer/ButtonTorture
@onready var button_interrogate = $VBoxContainer/ButtonInterrogate

func _ready():
	button_chat.pressed.connect(func(): _on_action_pressed("chat"))
	button_look.pressed.connect(func(): _on_action_pressed("look"))
	button_torture.pressed.connect(func(): _on_action_pressed("torture"))
	button_interrogate.pressed.connect(func(): _on_action_pressed("interrogate"))
	mouse_entered.connect(_expand)
	mouse_exited.connect(_collapse)
	_collapse()

func _on_action_pressed(action: String):
	emit_signal("interaction_selected", action)
	_collapse()

func _expand():
	vbox.visible = true
	self.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _collapse():
	vbox.visible = false
