## Attach to NPC scene.
## Handles state machine, role, personality, and registration with NPCManager.

extends Node2D

@export var personality: Resource
@export var role: Resource
@export var state_machine: Resource
@export var current_room_id: String = "background"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Register/unregister with NPCManager
func _ready():
	# Register with manager if needed (already handled by NPCManager, but safe)
	if not NPCManager.npcs.has(self):
		NPCManager.npcs.append(self)
	if not NPCManager.npcs_by_room.has(current_room_id):
		NPCManager.npcs_by_room[current_room_id] = []
	NPCManager.npcs_by_room[current_room_id].append(self)

func _process(delta):
	if state_machine:
		# Example: play animation matching state, if it exists
		if animated_sprite.sprite_frames.has_animation(state_machine.state):
			animated_sprite.play(state_machine.state)
		else:
			animated_sprite.play("idle")

func _exit_tree():
	if NPCManager.npcs.has(self):
		NPCManager.npcs.erase(self)
	if NPCManager.npcs_by_room.has(current_room_id):
		NPCManager.npcs_by_room[current_room_id].erase(self)
