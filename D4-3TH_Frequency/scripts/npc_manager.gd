## Responsible for all NPC tracking, spawning, movement, and state changes.
## HOW TO USE:
## - Call NPCManager.spawn_npc() to create a new NPC in a given location.
## - Call NPCManager.move_npc_to_room() to teleport an NPC between rooms/background.
## - Use NPCManager.set_npc_role()/set_npc_personality() to change attributes via code/events.
## - NPCs should register/unregister themselves for tracking on _ready() and _exit_tree().

extends Node

signal npc_spawned(npc)

# Preload all NPC scene variants
const NPC_SCENES = [
	preload("res://scenes/npc.tscn"),
	preload("res://scenes/npc2.tscn"),
	preload("res://scenes/npc3.tscn"),
]

# Preload all available personality/role/state_machine resources
const PERSONALITIES = [
	preload("res://scripts/npc/personality_roamer.tres"),
	# preload("res://scripts/npc/personality_aggressive.tres"),
	# Add more as needed
]
const NORMAL_ROLE = preload("res://scripts/npc/normal_role.tres")
const ENTITY_ROLE = preload("res://scripts/npc/entity_role.tres")
const REBEL_ROLE = preload("res://scripts/npc/rebel_role.tres")
const DEFAULT_STATE_MACHINE = preload("res://scripts/npc/state_machines/sm_idle.tres")

var npcs: Array = []
var npcs_by_room: Dictionary = {}


# Call this ONCE at game start to generate all NPCs
func spawn_all_npcs_at_game_start():
	# How-and-where-to-use: Call from GameManager after setup, before gameplay
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	_clear_all_npcs()
	
	# Distribution: 8 background, 3 common, 2 barracks, 2 entrance
	# Room IDs must match FEEDS ids (background is special)
	var spawn_plan = [
		{ "room_id": "background", "count": 8 },
		{ "room_id": "common", "count": 3 },
		{ "room_id": "barracks", "count": 2 },
		{ "room_id": "entrance", "count": 2 },
	]
	
	for plan in spawn_plan:
		var room_id = plan.room_id
		var count = plan.count
		for i in count:
			var npc_scene = NPC_SCENES[rng.randi_range(0, NPC_SCENES.size()-1)]
			var personality = PERSONALITIES[rng.randi_range(0, PERSONALITIES.size()-1)]
			var role = NORMAL_ROLE
			var state_machine = DEFAULT_STATE_MACHINE.duplicate()
			var spawn_point = _pick_spawn_point(room_id, rng)
			spawn_npc(
				room_id,
				npc_scene,
				personality,
				role,
				state_machine,
				spawn_point
			)

func spawn_npc(room_id: String, npc_scene: PackedScene, personality: Resource, role: Resource, state_machine: Resource, spawn_point: Node2D = null) -> Node:
	var npc = npc_scene.instantiate()
	npc.personality = personality
	npc.role = role
	npc.state_machine = state_machine
	npc.current_room_id = room_id
	npc.name = "NPC_%s_%s" % [room_id, str(randi())]
	# Set position
	if spawn_point:
		npc.global_position = spawn_point.global_position
	# Add to correct scene tree (room's root)
	_add_npc_to_room_scene(npc, room_id)
	npcs.append(npc)
	if not npcs_by_room.has(room_id):
		npcs_by_room[room_id] = []
	npcs_by_room[room_id].append(npc)
	emit_signal("npc_spawned", npc)
	return npc

# Returns a random spawn point for the given room, searching inside the current room scene instance
func _pick_spawn_point(room_id: String, rng: RandomNumberGenerator) -> Node2D:
	var camera_feed_manager = EventsManager.camera_feed
	if not camera_feed_manager:
		push_error("CameraFeedManager not available!")
		return null
	var room_scene = camera_feed_manager.get_feed_scene_instance(room_id)
	if not room_scene:
		push_error("Room scene for %s not loaded yet!" % room_id)
		return null

	var points := []
	var group_name = "spawn_%s" % room_id
	_find_spawn_points_recursive(room_scene, group_name, points)

	if points.size() > 0:
		return points[rng.randi_range(0, points.size() - 1)]
	return null

# Recursively finds all nodes in a group under a given node
func _find_spawn_points_recursive(node: Node, group_name: String, points: Array) -> void:
	if node.is_in_group(group_name):
		points.append(node)
	for c in node.get_children():
		if c is Node:
			_find_spawn_points_recursive(c, group_name, points)
			
# Finds the root scene node for a given room_id ("background" is special)
func _find_scene_root_for_room(room_id: String) -> Node:
	if room_id == "background":
		return get_tree().get_root().get_node("mainUI/background") # Adjust as needed
	else:
		var camera_feed = EventsManager.camera_feed if EventsManager.has_method("get_scene_instance") else null
		if camera_feed:
			var feed_index = -1
			for i in range(camera_feed.FEEDS.size()):
				if camera_feed.FEEDS[i].id == room_id:
					feed_index = i
					break
			if feed_index >= 0:
				return camera_feed.get_scene_instance(feed_index)
	return null

# Adds the NPC as a child to the room's scene instance (inside the correct viewport)
func _add_npc_to_room_scene(npc: Node, room_id: String):
	var camera_feed_manager = EventsManager.camera_feed
	if not camera_feed_manager:
		push_error("CameraFeedManager not available!")
		return
	var room_scene = camera_feed_manager.get_feed_scene_instance(room_id)
	if room_scene:
		room_scene.add_child(npc)
	else:
		push_error("Room scene for %s not loaded yet!" % room_id)

# Utility to clear all NPCs (for reset)
func _clear_all_npcs():
	for npc in npcs:
		if is_instance_valid(npc):
			npc.queue_free()
	npcs.clear()
	npcs_by_room.clear()
