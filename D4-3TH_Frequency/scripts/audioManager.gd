extends Node

## audioManager.gd
## Handles all audio playback: SFX, radio/music, and voice/comms

# Play a sound effect
# audioManager.play_sfx(preload("res://audio/beep.ogg"))

# Play radio/music, with optional fade-in
# audioManager.play_music(preload("res://audio/radio_theme.ogg"), 1.0, 2.0)

# Play a comms/voice line
# audioManager.play_voice(preload("res://audio/voice_clip.ogg"))

# Adjust volumes (0.0 = mute, 1.0 = max)
# audioManager.set_music_volume(0.5)

# Audio buses (set up in Godot Audio panel: "Master", "SFX", "Music", "Voice")
@export var sfx_bus_name : String = "SFX"
@export var music_bus_name : String = "Radio"
@export var voice_bus_name : String = "Comms"
@export var player_bus_name : String = "Player"

# Audio Players
var sfx_players : Array[AudioStreamPlayer] = []
var music_player : AudioStreamPlayer = null
var voice_player : AudioStreamPlayer = null
var player_player : AudioStreamPlayer = null

# Configuration
@export var sfx_channels : int = 8 # Number of overlapping SFX allowed

func _ready():
	# Create SFX players
	for i in range(sfx_channels):
		var sfx = AudioStreamPlayer.new()
		sfx.bus = sfx_bus_name
		add_child(sfx)
		sfx_players.append(sfx)
	# Create music/radio player
	music_player = AudioStreamPlayer.new()
	music_player.bus = music_bus_name
	add_child(music_player)
	# Create comms player
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = voice_bus_name
	add_child(voice_player)
	# Create player's player
	player_player = AudioStreamPlayer.new()
	player_player.bus = player_bus_name
	add_child(player_player)

# --- SFX ---
func play_sfx(sfx_stream: AudioStream, volume: float = 1.0):
	for sfx in sfx_players:
		if !sfx.playing:
			sfx.stream = sfx_stream
			sfx.volume_db = linear_to_db(volume)
			sfx.play()
			return
	# If all channels are busy, force play on the first one (optional)
	sfx_players[0].stop()
	sfx_players[0].stream = sfx_stream
	sfx_players[0].volume_db = linear_to_db(volume)
	sfx_players[0].play()

# --- Music/Radio ---
func play_music(music_stream: AudioStream, volume: float = 1.0, fade_in: float = 0.0):
	if fade_in > 0:
		_fade_audio(music_player, music_stream, volume, fade_in)
	else:
		music_player.stop()
		music_player.stream = music_stream
		music_player.volume_db = linear_to_db(volume)
		music_player.play()

func stop_music(fade_out: float = 0.0):
	if fade_out > 0:
		_fade_out_audio(music_player, fade_out)
	else:
		music_player.stop()

# --- Voice/Comms ---
func play_voice(voice_stream: AudioStream, volume: float = 1.0):
	voice_player.stop()
	voice_player.stream = voice_stream
	voice_player.volume_db = linear_to_db(volume)
	voice_player.play()

func stop_voice():
	voice_player.stop()

# --- Volume Controls ---
func set_sfx_volume(volume: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(sfx_bus_name), linear_to_db(volume))

func set_music_volume(volume: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(music_bus_name), linear_to_db(volume))

func set_voice_volume(volume: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(voice_bus_name), linear_to_db(volume))

# --- Helpers ---
func linear_to_db(volume: float) -> float:
	if volume <= 0.0:
		return -80.0 # mute
	return 20.0 * log(volume) / log(10)

# --- Optional: Fade-in and Fade-out ---
func _fade_audio(player: AudioStreamPlayer, stream: AudioStream, target_volume: float, duration: float):
	player.stop()
	player.stream = stream
	player.volume_db = -80.0
	player.play()
	var tween = create_tween()
	tween.tween_property(player, "volume_db", linear_to_db(target_volume), duration)

func _fade_out_audio(player: AudioStreamPlayer, duration: float):
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -80.0, duration)
	tween.connect("finished", Callable(player, "stop"))
