extends MarginContainer

@onready var signal_integrity = $BottomPanelRect/signalIntegrity
@onready var voice_modulation = $BottomPanelRect/voiceModulation
@onready var transponder_signature = $BottomPanelRect/transponderSignature

@onready var signalNumber1 = $BottomPanelRect/signalNumber1
@onready var signalNumber1_button = $BottomPanelRect/signalNumber1/signalNumber1_Button
@onready var signalNumber2 = $BottomPanelRect/signalNumber2
@onready var signalNumber2_button = $BottomPanelRect/signalNumber2/signalNumber2_Button
@onready var signalNumber3 = $BottomPanelRect/signalNumber3
@onready var signalNumber3_button = $BottomPanelRect/signalNumber3/signalNumber3_Button
@onready var signalNumber4 = $BottomPanelRect/signalNumber4
@onready var signalNumber4_button = $BottomPanelRect/signalNumber4/signalNumber4_Button

@onready var error_rate = $BottomPanelRect/errorRate
@onready var latency = $BottomPanelRect/latency

@onready var reply_button = $BottomPanelRect/replyButton
@onready var listen_button = $BottomPanelRect/listenButton
@onready var mic_button = $BottomPanelRect/micButton
@onready var power_button = $BottomPanelRect/powerButton

@onready var frequency_list_vbox = $BPanel_LeftRect/FrequencyListContainer/FrequencyListRect/FrequencyListVBox
@onready var found_frequency_list_vbox = $BPanel_LeftRect/FrequencyListContainer/FrequencyListRect/FoundFrequencyScroll
@onready var known_button = $BPanel_LeftRect/FrequencyListContainer/FrequencyListRect/knownList
@onready var found_button = $BPanel_LeftRect/FrequencyListContainer/FrequencyListRect/foundList
var showing_known_list := true

# BOOLEANS #
var replyOn : bool = false
var listenOn : bool = false
var micOn : bool = false
var powerOn : bool = false

# FREQUENCY NUMBERS
# Store current digits (initialize to Command Center)
var signal_digits: Array = [1, 0, 0, 1]

var signal_timer: Timer
var error_timer: Timer
var latency_timer: Timer
var transponder_timer: Timer

var current_freq: Variant = null
var transponder_anim_time := 0.0
var transponder_dots_step := 1
var transponder_animating := false

# IMAGES #
@onready var flipSwitchOn = preload("res://assets/images/FlipSwitchOn.png")
@onready var flipSwitchOff = preload("res://assets/images/FlipSwitchOff.png")
@onready var flipSwitch2On = preload("res://assets/images/FlipSwitch2On.png")
@onready var flipSwitch2Off = preload("res://assets/images/FlipSwitch2Off.png")
@onready var powerButton = preload("res://assets/images/PowerButton.png")


func _ready():

	reply_button.connect("pressed", Callable(self, "toggleReply"))
	listen_button.connect("pressed", Callable(self, "toggleListen"))
	mic_button.connect("pressed", Callable(self, "toggleMic"))
	
	# Connect buttons to increment functions
	signalNumber1_button.pressed.connect(increment_signal_digit.bind(0))
	signalNumber2_button.pressed.connect(increment_signal_digit.bind(1))
	signalNumber3_button.pressed.connect(increment_signal_digit.bind(2))
	signalNumber4_button.pressed.connect(increment_signal_digit.bind(3))
	# Initialize display
	update_signal_numbers_display()
	frequency_changed()

	voice_modulation.text = "INACTIVE"
	transponder_signature.text = "INACTIVE"

	GameManager.connect("frequency_changed", Callable(self, "_on_frequency_changed"))
	listen_button.connect("pressed", Callable(self, "_on_listen_toggled"))
	
	known_button.pressed.connect(show_known_list)
	found_button.pressed.connect(show_found_list)
	show_known_list()
	
	
func toggleReply():
	print("Toggling Reply")
	replyOn = not replyOn
	reply_button.texture_normal = flipSwitch2On if replyOn else flipSwitch2Off
	AudioManager.play_sfx(preload("res://assets/sfx/comm_mode_switch.mp3"))

func toggleListen():
	print("Toggling Listen")
	listenOn = not listenOn
	listen_button.texture_normal = flipSwitch2On if listenOn else flipSwitch2Off
	AudioManager.play_sfx(preload("res://assets/sfx/comm_mode_switch.mp3"))
	
func toggleMic():
	print("Toggling Mic")
	micOn = not micOn
	mic_button.texture_normal = flipSwitchOn if micOn else flipSwitchOff
	AudioManager.play_sfx(preload("res://assets/sfx/mic_switch.mp3"))
	
func increment_signal_digit(index: int) -> void:
	signal_digits[index] = (signal_digits[index] + 1) % 10
	update_signal_numbers_display()
	frequency_changed()
	AudioManager.play_sfx(preload("res://assets/sfx/signal_button.mp3"))

func update_signal_numbers_display() -> void:
	signalNumber1.text = str(signal_digits[0])
	signalNumber2.text = str(signal_digits[1])
	signalNumber3.text = str(signal_digits[2])
	signalNumber4.text = str(signal_digits[3])

func frequency_changed() -> void:
	var signal_id = int("%d%d%d%d" % signal_digits)
	GameManager.signal_number_changed(signal_id)

func _on_frequency_changed(freq_id: int):
	current_freq = null
	for freq in GameManager.frequencies:
		if freq["id"] == freq_id:
			current_freq = freq
			break
	print("Frequency changed, found:", current_freq)
	if current_freq == null:
		_reset_stat_ui()
		_stop_all_stat_timers()
	else:
		_start_stat_updates()
		_update_stat_ui(true)

func _reset_stat_ui():
	signal_integrity.value = 0
	error_rate.value = 0
	latency.value = 0
	transponder_signature.text = "INACTIVE"
	# etc. for any other UI elements
	
func _stop_all_stat_timers():
	if signal_timer: signal_timer.stop(); signal_timer.queue_free(); signal_timer = null
	if error_timer: error_timer.stop(); error_timer.queue_free(); error_timer = null
	if latency_timer: latency_timer.stop(); latency_timer.queue_free(); latency_timer = null
	if transponder_timer: transponder_timer.stop(); transponder_timer.queue_free(); transponder_timer = null

func _on_listen_toggled():
	_start_stat_updates()
	_update_stat_ui(true)

func _start_stat_updates():
	_stop_all_stat_timers()
	if current_freq:
		print("Starting timers for frequency:", current_freq["id"])
	else:
		print("Not starting timers, no valid freq")
	# Always start signal integrity timer
	signal_timer = Timer.new()
	signal_timer.wait_time = 0.2
	signal_timer.one_shot = false
	signal_timer.connect("timeout", Callable(self, "_update_signal_integrity"))
	add_child(signal_timer)
	signal_timer.start()
	# Only start others if Listen is ON
	if listenOn and current_freq:
		error_timer = Timer.new()
		error_timer.wait_time = 0.2
		error_timer.one_shot = false
		error_timer.connect("timeout", Callable(self, "_update_error_rate"))
		add_child(error_timer)
		error_timer.start()
		latency_timer = Timer.new()
		latency_timer.wait_time = 0.2
		latency_timer.one_shot = false
		latency_timer.connect("timeout", Callable(self, "_update_latency"))
		add_child(latency_timer)
		latency_timer.start()
		_start_transponder_signature()
	else:
		error_rate.value = 0
		latency.value = 0
		transponder_signature.text = "INACTIVE"
		transponder_animating = false

func _update_signal_integrity():
	if not current_freq: return
	var r = current_freq["signal_integrity_range"]
	signal_integrity.value = randi_range(r[0], r[1])

func _update_error_rate():
	if not current_freq or not listenOn: error_rate.value = 0; return
	var r = current_freq["error_rate_range"]
	error_rate.value = randi_range(r[0], r[1])

func _update_latency():
	if not current_freq or not listenOn: latency.value = 0; return
	var r = current_freq["latency_range"]
	latency.value = randi_range(r[0], r[1])

func _start_transponder_signature():
	transponder_animating = true
	transponder_dots_step = 1
	var tr = current_freq["transponder_dots_range"]
	transponder_anim_time = randf_range(tr[0], tr[1])
	transponder_signature.text = "."
	if transponder_timer:
		transponder_timer.stop()
		transponder_timer.queue_free()
	transponder_timer = Timer.new()
	transponder_timer.wait_time = 0.2
	transponder_timer.one_shot = false
	transponder_timer.connect("timeout", Callable(self, "_update_transponder_signature"))
	add_child(transponder_timer)
	transponder_timer.start()

func _update_transponder_signature():
	if not current_freq or not listenOn:
		transponder_signature.text = "INACTIVE"
		transponder_timer.stop()
		return
	transponder_anim_time -= 0.2
	if transponder_anim_time <= 0.0:
		transponder_signature.text = str(current_freq["transponder_signature"])
		transponder_timer.stop()
		transponder_animating = false
		return
	transponder_dots_step += 1
	if transponder_dots_step > 3:
		transponder_dots_step = 1
	transponder_signature.text = ".".repeat(transponder_dots_step)

func _update_stat_ui(reset := false):
	if reset:
		if not listenOn:
			error_rate.value = 0
			latency.value = 0
			transponder_signature.text = "INACTIVE"
			
func show_known_list():
	frequency_list_vbox.visible = true
	found_frequency_list_vbox.visible = false
	showing_known_list = true
	# Optional: Update button visuals to indicate active tab
	known_button.disabled = true
	found_button.disabled = false

func show_found_list():
	frequency_list_vbox.visible = false
	found_frequency_list_vbox.visible = true
	showing_known_list = false
	known_button.disabled = false
	found_button.disabled = true
