## Handles menu interaction (Chat, Look At, Torture, Interrogate) and triggers DialogueManager.
## HOW-AND-WHERE-TO-USE:
## - Attach to the entity Node2D under creature.tscn (not the root "room").
## - In your main scene or CameraFeedRect, connect the entity menu panel's `interaction_selected(action: String)` signal to this script's `interact(action: String)` method.

extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D # Adjust path if needed

func interact(action: String):
	# This method should be connected to the menu panel's interaction_selected signal
	match action:
		"chat":
			_start_dialogue("entity_chat")
		"look":
			_start_dialogue("entity_look")
		"torture":
			_start_dialogue("entity_torture")
		"interrogate":
			_start_dialogue("entity_interrogate")
		_:
			print("Unknown action: %s" % action)
	# Optionally change animation here
	_play_action_animation(action)

func _start_dialogue(dialogue_id: String):
	# Use DialogueManager, frequency_id is 1001 for the entity
	if DialogueManager:
		DialogueManager.start_dialogue(1001, dialogue_id)
	else:
		print("DialogueManager not found!")

func _play_action_animation(action: String):
	# Optionally switch animations based on action
	match action:
		"torture", "interrogate":
			if animated_sprite.sprite_frames.has_animation("distressed"):
				animated_sprite.play("distressed")
		"chat", "look":
			if animated_sprite.sprite_frames.has_animation("idle"):
				animated_sprite.play("idle")
		_:
			animated_sprite.play("idle")
