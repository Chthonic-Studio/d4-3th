## Manages camera feed logic, swapping, and scene loading for the security camera system.
## Add this script as a node named "CameraFeedManager" under your mainUI scene.
## 
## How to use:
## - Assign CameraFeedManager as a node in your main UI scene.
## - Assign five ViewportContainers (or similar nodes) for feeds in the inspector or via code.
## - CameraFeedUI or other scripts can call swap_feed(), get_active_feed_id(), etc.
## - NPCManager and EventManager can query which feed is active and get scene instances for logical checks.
##
## Camera feeds are defined by FEEDS; you can easily update display names or scene paths there.

extends Node

## ---- FEED METADATA ----
## List of all feeds and their associated metadata.
## Update the scene paths if you change your camera feed scenes
const FEEDS := [
	{ "id": "common", "name": "Common Room", "scene": "res://scenes/common_room.tscn" },
	{ "id": "barracks", "name": "Barracks", "scene": "res://scenes/barracks.tscn" },
	{ "id": "storage", "name": "Storage Room", "scene": "res://scenes/storage_room.tscn" },
	{ "id": "entrance", "name": "Entrance", "scene": "res://scenes/entrance.tscn" },
	{ "id": "creature", "name": "Creature Containment", "scene": "res://scenes/creature.tscn" }
]

## ---- EXPORTS FOR UI INTEGRATION ----
var main_feed_viewport: Viewport = null
var small_feed_viewports: Array[Viewport] = []

## ---- SIGNALS ----
signal feed_swapped(big_feed_id: String, prev_feed_id: String)
signal feed_scene_loaded(feed_id: String, scene_instance: Node)

## ---- INTERNAL STATE ----
var _big_feed_id: String = FEEDS[0].id
var _feed_scene_instances := {}  # feed_id: scene instance
var _feed_viewports := {}        # feed_id: Viewport

var _feeds_loaded := 0

## Called when the node is added to the scene.
func _ready():
	# Initial assignment: first feed is big, the rest are small (order as in FEEDS)
	_init_feed_viewports()
	_load_all_feeds()
	connect("feed_scene_loaded", Callable(self, "_on_feed_scene_loaded"))
	
func register_viewports(main_feed: Viewport, small_feeds: Array[Viewport]):
	main_feed_viewport = main_feed
	small_feed_viewports = small_feeds
	_init_feed_viewports()
	_load_all_feeds()

func _init_feed_viewports():
	_feed_viewports.clear()
	_feed_viewports[FEEDS[0].id] = main_feed_viewport
	for i in range(1, FEEDS.size()):
		if i-1 < small_feed_viewports.size():
			_feed_viewports[FEEDS[i].id] = small_feed_viewports[i-1]
## ---- PUBLIC API ----

## Returns the current big feed's id (as string, e.g. "common").
func get_active_feed_id() -> String:
	return _big_feed_id

## Returns all feed metadata (for UI labeling, etc.).
func get_all_feeds() -> Array:
	return FEEDS

## Returns feed metadata for a given id.
func get_feed_metadata(feed_id: String) -> Dictionary:
	for feed in FEEDS:
		if feed.id == feed_id:
			return feed
	return {}

## Returns the scene instance currently loaded for a given feed.
func get_feed_scene_instance(feed_id: String) -> Node:
	return _feed_scene_instances.get(feed_id, null)

## Returns the Viewport for a given feed.
func get_feed_viewport(feed_id: String) -> Viewport:
	return _feed_viewports.get(feed_id, null)

## Swaps the big feed with the one specified by target_feed_id.
## Will emit feed_swapped(big_feed_id, prev_feed_id).
func swap_feed(target_feed_id: String) -> void:
	if target_feed_id == _big_feed_id:
		return 
	# Find index in FEEDS
	var old_big = _big_feed_id
	_big_feed_id = target_feed_id
	_update_viewport_assignments()
	emit_signal("feed_swapped", _big_feed_id, old_big)

## Returns true if the feed is currently the big feed.
func is_feed_active(feed_id: String) -> bool:
	return _big_feed_id == feed_id

## Reloads all feed scenes (useful if you need a hard reset).
func reload_all_feeds():
	_free_all_scenes()
	_load_all_feeds()

## ---- INTERNAL METHODS ----

## Loads all scenes into their respective Viewports (main + small).
func _load_all_feeds():
	for i in FEEDS.size():
		var feed = FEEDS[i]
		var feed_id = feed.id
		var viewport = _feed_viewports.get(feed_id, null)
		if viewport:
			var scene = load(feed.scene)
			if scene:
				var scene_instance = scene.instantiate()
				viewport.add_child(scene_instance)
				_feed_scene_instances[feed_id] = scene_instance
				emit_signal("feed_scene_loaded", feed_id, scene_instance)
	# Set only big feed to "active" (unpaused); pause others if desired
	_update_feed_activity()

## Removes all scene instances from Viewports (for reload/reset).
func _free_all_scenes():
	for feed_id in _feed_scene_instances.keys():
		var instance = _feed_scene_instances[feed_id]
		if instance and instance.is_inside_tree():
			instance.queue_free()
	_feed_scene_instances.clear()
	
func _on_feed_scene_loaded(feed_id, scene_instance):
	_feeds_loaded += 1
	if _feeds_loaded == FEEDS.size():
		# All feeds are loaded, safe to spawn NPCs now
		NPCManager.spawn_all_npcs_at_game_start()

## Updates which Viewports are assigned to the main and small feeds.
func _update_viewport_assignments():
	# By default, main_feed_viewport is always the "big" feed
	# Swap scene contents accordingly (for performance, only main is unpaused)
	_update_feed_activity()

## Sets the "active" state for each feed (main feed unpaused, others paused or black).
func _update_feed_activity():
	for feed in FEEDS:
		var feed_id = feed.id
		var scene_instance = _feed_scene_instances.get(feed_id, null)
		if scene_instance:
			scene_instance.process_mode = Node.PROCESS_MODE_INHERIT if feed_id == _big_feed_id else Node.PROCESS_MODE_DISABLED
			# For extra realism, you could show a "BLACK" screen on small feeds, or a static image.
			# Otherwise, they'll just be static/frozen.

## ---- EXTENSION HOOKS ----

## Call this from NPCManager when an NPC needs to know its scene instance for a feed.
## Call this from EventManager to check if a feed is currently the main feed before triggering player-view-only events.

## ---- HOW-AND-WHERE-TO-USE ----

## Connect your CameraFeedUI buttons to call swap_feed(feed_id) when a feed is clicked.
## Query get_active_feed_id() to know which feed is currently "big".
## Use get_feed_scene_instance(feed_id) for NPC logic or event checks.
## Optionally connect to feed_swapped signal for UI or game logic hooks.
