## This script manages the 5 small feeds + 1 main feed, handles swapping, and loads feed scenes.
## HOW TO USE:
## - Attach this script to the CameraFeed (MarginContainer) node.
## - Assign the 6 SubViewport nodes (not SubViewportContainers) in the inspector, in order: [main, small1, ..., small5].
## - Connect each small feed button's pressed() signal to the respective _on_small_feed_X_pressed() function.
## - To get the current main feed's metadata: get_feed_metadata(0)
## - To get the current main feed's scene instance: get_scene_instance(0)
## - Listen to the "main_feed_changed" signal for UI or logic reactions when the main feed changes.

extends MarginContainer

var FEEDS := [
	{ "id": "main", "name": "Main Feed", "scene": "res://scenes/common_room.tscn" }, # Main starts at common room
	{ "id": "common", "name": "Common Room", "scene": "res://scenes/common_room.tscn" },
	{ "id": "barracks", "name": "Barracks", "scene": "res://scenes/barracks.tscn" },
	{ "id": "storage", "name": "Storage Room", "scene": "res://scenes/storage.tscn" },
	{ "id": "entrance", "name": "Entrance", "scene": "res://scenes/entrance.tscn" },
	{ "id": "creature", "name": "Creature Containment", "scene": "res://scenes/creature.tscn" }
]

@export var subviewports: Array[SubViewport] = []
@export var feed_name_label: Label = null

signal main_feed_changed(current_main_index: int, feed_metadata: Dictionary)

var _feed_scene_instances := [] # Store scene instances for each feed slot
var feed_room_indices := [0, 1, 2, 3, 4, 5]
var _feeds_loaded := {}

func _ready():
	assert(subviewports.size() == 6, "Assign all 6 SubViewports in the inspector!")
	if not feed_name_label:
		feed_name_label = $CameraFeedRect/FeedNameLabel
		feed_name_label.text = "Common Room"
	_load_all_feeds()
	connect("feed_scene_loaded", Callable(self, "_on_feed_scene_loaded"))
	update_feed_label()
	connect("main_feed_changed", Callable(self, "on_main_feed_changed"))
	EventsManager.register_camera_feed(self)

func _load_all_feeds():
	_feed_scene_instances.clear()
	for i in FEEDS.size():
		var viewport = subviewports[i]
		for child in viewport.get_children():
			child.queue_free()
		var room_idx = feed_room_indices[i]
		if room_idx == -1:
			# Show blackout overlay
			var label = Label.new()
			label.text = "CAMERA ACTIVE"
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			viewport.add_child(label)
			_feed_scene_instances.append(label)
		else:
			var scene = load(FEEDS[room_idx].scene)
			var instance = scene.instantiate()
			viewport.add_child(instance)
			_feed_scene_instances.append(instance)
	_update_feed_activity()
	GameManager.spawn_npcs()

func swap_feed(small_feed_index: int) -> void:
	assert(small_feed_index > 0 and small_feed_index < 6, "Feed index out of range!")

	# Restore previous main to its small feed (if needed)
	var prev_main_room = feed_room_indices[0]
	for i in range(1, FEEDS.size()):
		if feed_room_indices[i] == -1:
			# Restore previous room to this small feed
			var viewport = subviewports[i]
			for child in viewport.get_children():
				child.queue_free()
			var instance = load(FEEDS[prev_main_room].scene).instantiate()
			viewport.add_child(instance)
			_feed_scene_instances[i] = instance
			feed_room_indices[i] = prev_main_room

	# Which room is currently in the main and the clicked slot
	var clicked_room = feed_room_indices[small_feed_index]

	# In main feed: remove old, add new
	var main_viewport = subviewports[0]
	for child in main_viewport.get_children():
		child.queue_free()
	var new_main_scene = load(FEEDS[clicked_room].scene).instantiate()
	main_viewport.add_child(new_main_scene)
	_feed_scene_instances[0] = new_main_scene

	# In clicked small feed: remove old, add blackout overlay
	var small_viewport = subviewports[small_feed_index]
	for child in small_viewport.get_children():
		child.queue_free()
	var label = Label.new()
	label.text = "CAMERA ACTIVE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	small_viewport.add_child(label)
	_feed_scene_instances[small_feed_index] = label

	# Update mapping
	feed_room_indices[0] = clicked_room
	feed_room_indices[small_feed_index] = -1

	_update_feed_activity()
	emit_signal("main_feed_changed", 0, FEEDS[clicked_room])
	update_feed_label()

func _update_feed_activity():
	for i in FEEDS.size():
		var scene_instance = _feed_scene_instances[i]
		scene_instance.process_mode = Node.PROCESS_MODE_INHERIT if i == 0 else Node.PROCESS_MODE_DISABLED

func get_main_feed_index() -> int:
	return 0

func get_scene_instance(feed_index: int) -> Node:
	return _feed_scene_instances[feed_index]

func get_feed_metadata(feed_index: int) -> Dictionary:
	var room_idx = feed_room_indices[feed_index]
	if room_idx == -1:
		return {"id": "blackout", "name": "Blackout", "scene": ""}
	return FEEDS[room_idx]

func _on_small_feed_1_pressed():
	swap_feed(1)
	# feed_name_label.text = "Common Room"
func _on_small_feed_2_pressed():
	swap_feed(2)
	# feed_name_label.text = "Barracks"
func _on_small_feed_3_pressed():
	swap_feed(3)
	# feed_name_label.text = "Storage Room"
func _on_small_feed_4_pressed():
	swap_feed(4)
	# feed_name_label.text = "Entrance"
func _on_small_feed_5_pressed():
	swap_feed(5)
	# feed_name_label.text = "Creature Containment"

func update_feed_label():
	if feed_name_label:
		feed_name_label.text = get_feed_metadata(0).name

## Returns the scene instance for a given room_id (e.g., "common", "barracks", etc.)
func get_feed_scene_instance(room_id: String) -> Node:
	for i in range(FEEDS.size()):
		var room_idx = feed_room_indices[i]
		if room_idx != -1 and FEEDS[room_idx].id == room_id:
			return _feed_scene_instances[i]
	return null
		
func on_main_feed_changed(current_main_index: int, feed_metadata: Dictionary):
	update_feed_label()

func _on_feed_scene_loaded(feed_id, scene_instance):
	_feeds_loaded[feed_id] = true
	# Only spawn after all needed feeds are loaded
	var all_needed = ["common", "barracks", "entrance"] # Add any others you use for NPCs
	if all_needed.all(func(id): return _feeds_loaded.has(id)):
		NPCManager.spawn_all_npcs_at_game_start()

## Returns true if the given room id is currently in the main feed slot.
func is_room_in_main_feed(room_id: String) -> bool:
	var main_room_index = feed_room_indices[0]
	return FEEDS[main_room_index].id == room_id
	
## Returns the id of the room currently in the main feed.
func get_current_main_room_id() -> String:
	var main_room_index = feed_room_indices[0]
	return FEEDS[main_room_index].id
