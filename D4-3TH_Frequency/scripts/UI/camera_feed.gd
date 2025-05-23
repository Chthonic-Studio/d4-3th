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
	{ "id": "storage", "name": "Storage Room", "scene": "res://scenes/storage_room.tscn" },
	{ "id": "entrance", "name": "Entrance", "scene": "res://scenes/entrance.tscn" },
	{ "id": "creature", "name": "Creature Containment", "scene": "res://scenes/creature.tscn" }
]

@export var subviewports: Array[SubViewport] = []
@export var feed_name_label: Label = null

signal main_feed_changed(current_main_index: int, feed_metadata: Dictionary)

var _feed_scene_instances := [] # Store scene instances for each feed slot

func _ready():
	assert(subviewports.size() == 6, "Assign all 6 SubViewports in the inspector!")
	if not feed_name_label:
		feed_name_label = $CameraFeedRect/FeedNameLabel
	_load_all_feeds()
	update_feed_label()
	connect("main_feed_changed", Callable(self, "on_main_feed_changed"))

func _load_all_feeds():
	_feed_scene_instances.clear()
	for i in FEEDS.size():
		var viewport = subviewports[i]
		for child in viewport.get_children():
			child.queue_free()
		var scene = load(FEEDS[i].scene)
		var instance = scene.instantiate()
		viewport.add_child(instance)
		_feed_scene_instances.append(instance)
	_update_feed_activity()

func swap_feed(small_feed_index: int) -> void:
	assert(small_feed_index > 0 and small_feed_index < 6, "Feed index out of range!")
	var temp_scene = _feed_scene_instances[0]
	var temp_meta = FEEDS[0]
	_feed_scene_instances[0] = _feed_scene_instances[small_feed_index]
	_feed_scene_instances[small_feed_index] = temp_scene
	FEEDS[0] = FEEDS[small_feed_index]
	FEEDS[small_feed_index] = temp_meta

	for i in FEEDS.size():
		var viewport = subviewports[i]
		for child in viewport.get_children():
			child.queue_free()
		viewport.add_child(_feed_scene_instances[i])
	_update_feed_activity()
	emit_signal("main_feed_changed", 0, FEEDS[0])

func _update_feed_activity():
	for i in FEEDS.size():
		var scene_instance = _feed_scene_instances[i]
		scene_instance.process_mode = Node.PROCESS_MODE_INHERIT if i == 0 else Node.PROCESS_MODE_DISABLED

func get_main_feed_index() -> int:
	return 0

func get_scene_instance(feed_index: int) -> Node:
	return _feed_scene_instances[feed_index]

func get_feed_metadata(feed_index: int) -> Dictionary:
	return FEEDS[feed_index]

func _on_small_feed_1_pressed():
	swap_feed(1)
func _on_small_feed_2_pressed():
	swap_feed(2)
func _on_small_feed_3_pressed():
	swap_feed(3)
func _on_small_feed_4_pressed():
	swap_feed(4)
func _on_small_feed_5_pressed():
	swap_feed(5)

func update_feed_label():
	if feed_name_label:
		feed_name_label.text = get_feed_metadata(0).name
		
func on_main_feed_changed(current_main_index: int, feed_metadata: Dictionary):
	update_feed_label()

## -- EXTENSIONS --
## - Use get_scene_instance(0) for the current main feed's scene (for event/NPC logic).
## - Listen to main_feed_changed signal to react to feed changes (UI, events, etc).
