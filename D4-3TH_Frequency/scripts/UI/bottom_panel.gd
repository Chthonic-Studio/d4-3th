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

# BOOLEANS #
var replyOn : bool = false
var listenOn : bool = false
var micOn : bool = false
var powerOn : bool = false

# FREQUENCY NUMBERS
# Store current digits (initialize to the initial display)
var signal_digits: Array = [1, 0, 0, 1]

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
