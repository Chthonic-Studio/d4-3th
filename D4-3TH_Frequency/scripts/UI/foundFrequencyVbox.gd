extends VBoxContainer

@onready var found_freq_vbox = self
var found_frequency_scene = preload("res://scenes/foundFrequency.tscn") 

const FREQUENCIES_PER_HBOX = 5

var found_frequencies: Array = []
var active_frequency_id: int = -1

@onready var button = $"../../foundList"

func _ready():
	GameManager.connect("found_frequencies_updated", Callable(self, "update_found_frequency_list"))
	GameManager.connect("active_frequency_changed", Callable(self, "_on_active_frequency_changed"))
	update_found_frequency_list()

func _on_active_frequency_changed(new_id: int):
	active_frequency_id = new_id
	_update_active_highlight()

func update_found_frequency_list():
	# Remove old HBoxes/children
	for child in found_freq_vbox.get_children():
		child.queue_free()
	found_frequencies = GameManager.found_frequencies.duplicate()
	found_frequencies.sort_custom(_sort_ascending)

	# Create new HBoxes as needed
	var hbox: HBoxContainer = null
	for i in range(found_frequencies.size()):
		if i % FREQUENCIES_PER_HBOX == 0:
			hbox = HBoxContainer.new()
			found_freq_vbox.add_child(hbox)

		var freq = found_frequencies[i]
		var freq_btn = found_frequency_scene.instantiate()
		freq_btn.set_frequency_data(freq)
		button.pressed.connect(func():
			_on_found_frequency_button_pressed(freq["id"])
		)
		hbox.add_child(freq_btn)

	# Highlight if needed
	_update_active_highlight()

func _on_found_frequency_button_pressed(freq_id: int):
	# Show info or select as needed
	GameManager.signal_number_changed(freq_id)
	_update_active_highlight()

func _update_active_highlight():
	# Optionally, update the visual highlight for the active frequency
	for hbox in found_freq_vbox.get_children():
		for freq_btn in hbox.get_children():
			if freq_btn.has_method("set_active"):
				freq_btn.set_active(freq_btn.frequency_id == active_frequency_id)

static func _sort_ascending(a, b):
	return a["id"] < b["id"]
