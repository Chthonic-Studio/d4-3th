extends VBoxContainer

@onready var label_nodes = [
	$FrequencyListHbox1/frequency1,
	$FrequencyListHbox1/frequency2,
	$FrequencyListHbox1/frequency3,
	$FrequencyListHbox1/frequency4,
	$FrequencyListHbox1/frequency5,
	$FrequencyListHbox2/frequency6,
	$FrequencyListHbox2/frequency7,
	$FrequencyListHbox2/frequency8,
	$FrequencyListHbox2/frequency9,
	$FrequencyListHbox2/frequency10,
	$FrequencyListHbox3/frequency11,
	$FrequencyListHbox3/frequency12,
	$FrequencyListHbox3/frequency13,
	$FrequencyListHbox3/frequency14,
	$FrequencyListHbox3/frequency15,
	$FrequencyListHbox4/frequency16,
	$FrequencyListHbox4/frequency17,
	$FrequencyListHbox4/frequency18,
	$FrequencyListHbox4/frequency19,
	$FrequencyListHbox4/frequency20,
	$FrequencyListHbox5/frequency21,
	$FrequencyListHbox5/frequency22,
	$FrequencyListHbox5/frequency23,
	$FrequencyListHbox5/frequency24,
	$FrequencyListHbox5/frequency25,
	$FrequencyListHbox6/frequency26,
	$FrequencyListHbox6/frequency27,
	$FrequencyListHbox6/frequency28,
	$FrequencyListHbox6/frequency29,
	$FrequencyListHbox6/frequency30
]

@onready var button_nodes = [
	$FrequencyListHbox1/frequency1/frequency1Button,
	$FrequencyListHbox1/frequency2/frequency2Button,
	$FrequencyListHbox1/frequency3/frequency3Button,
	$FrequencyListHbox1/frequency4/frequency4Button,
	$FrequencyListHbox1/frequency5/frequency5Button,
	$FrequencyListHbox2/frequency6/frequency6Button,
	$FrequencyListHbox2/frequency7/frequency7Button,
	$FrequencyListHbox2/frequency8/frequency8Button,
	$FrequencyListHbox2/frequency9/frequency9Button,
	$FrequencyListHbox2/frequency10/frequency10Button,
	$FrequencyListHbox3/frequency11/frequency11Button,
	$FrequencyListHbox3/frequency12/frequency12Button,
	$FrequencyListHbox3/frequency13/frequency13Button,
	$FrequencyListHbox3/frequency14/frequency14Button,
	$FrequencyListHbox3/frequency15/frequency15Button,
	$FrequencyListHbox4/frequency16/frequency16Button,
	$FrequencyListHbox4/frequency17/frequency17Button,
	$FrequencyListHbox4/frequency18/frequency18Button,
	$FrequencyListHbox4/frequency19/frequency19Button,
	$FrequencyListHbox4/frequency20/frequency20Button,
	$FrequencyListHbox5/frequency21/frequency21Button,
	$FrequencyListHbox5/frequency22/frequency22Button,
	$FrequencyListHbox5/frequency23/frequency23Button,
	$FrequencyListHbox5/frequency24/frequency24Button,
	$FrequencyListHbox5/frequency25/frequency25Button,
	$FrequencyListHbox6/frequency26/frequency26Button,
	$FrequencyListHbox6/frequency27/frequency27Button,
	$FrequencyListHbox6/frequency28/frequency28Button,
	$FrequencyListHbox6/frequency29/frequency29Button,
	$FrequencyListHbox6/frequency30/frequency30Button
]

var shown_frequency_id: int = -1
var active_frequency_id: int = -1

@onready var active_frequency_button = $"../../../FrequencyInfoContainer/NinePatchRect/currentFrequency"
@onready var frequency_data_scroll = $"../../../FrequencyInfoContainer/NinePatchRect/FrequencyInfoScrollCont/FrequencyInfoVbox"
var frequency_data_scene = preload("res://scenes/frequency_data.tscn")

var frequencies: Array = []

func _ready():
	GameManager.connect("frequencies_updated", Callable(self, "update_frequency_list"))
	GameManager.connect("active_frequency_changed", Callable(self, "_on_active_frequency_changed"))
	active_frequency_button.pressed.connect(_on_go_to_active_frequency_button_pressed)
	update_frequency_list(GameManager.frequencies)
	for idx in range(button_nodes.size()):
		button_nodes[idx].pressed.connect(func(): _on_frequency_button_pressed(idx))
			
func _on_active_frequency_changed(new_id: int):
	shown_frequency_id = new_id
	_show_frequency_data(new_id)
	_update_active_button()

func _update_active_button():
	active_frequency_button.visible = (shown_frequency_id != GameManager.current_frequency)

func _on_go_to_active_frequency_button_pressed():
	_show_frequency_data(GameManager.current_frequency)

func _show_frequency_data(freq_id: int):
	shown_frequency_id = freq_id
	var freq = GameManager.get_frequency_by_id(freq_id)
	# Clear old data entries...
	for c in frequency_data_scroll.get_children():
		c.queue_free()
	if freq:
		for entry in freq.get("data_entries", []):
			var data_label = frequency_data_scene.instantiate()
			data_label.text = str(entry)
			frequency_data_scroll.add_child(data_label)
	else:
		var data_label = frequency_data_scene.instantiate()
		data_label.text = "No active channel on this frequency"
		frequency_data_scroll.add_child(data_label)
	_update_active_button()

func sort_ascending(a, b):
	if a["id"] < b["id"]:
		return true
	return false
	
func update_frequency_list(new_frequencies: Array) -> void:
	frequencies = new_frequencies  # Store for access from other functions
	frequencies.sort_custom(sort_ascending)
	for i in range(label_nodes.size()):
		if i < frequencies.size():
			var freq = frequencies[i]
			label_nodes[i].text = str(freq["id"])
			match freq["status"]:
				"ONLINE":
					label_nodes[i].modulate = Color(0.2, 1.0, 0.2)
				"OFFLINE":
					label_nodes[i].modulate = Color(1, 1, 1)
				"COMPROMISED":
					label_nodes[i].modulate = Color(1, 0.1, 0.1)
			label_nodes[i].visible = true
			button_nodes[i].visible = true
		else:
			label_nodes[i].visible = false
			button_nodes[i].visible = false

func _on_frequency_button_pressed(idx):
	if idx >= frequencies.size(): return
	var freq = frequencies[idx]
	_show_frequency_data(freq["id"])

func show_frequency_data(freq: Dictionary):
	# Clear old data entries
	for c in frequency_data_scroll.get_children():
		c.queue_free()
	# Add current known entries
	for entry in freq.get("data_entries", []):
		var data_label = frequency_data_scene.instantiate()
		data_label.text = str(entry)
		frequency_data_scroll.add_child(data_label)

func add_discovered_data(freq_idx: int, entry: String):
	if freq_idx >= frequencies.size(): return
	var freq = frequencies[freq_idx]
	if not freq.has("data_entries"):
		freq["data_entries"] = [str(freq["id"])]
	freq["data_entries"].append(entry)
