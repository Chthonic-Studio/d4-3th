extends MarginContainer

@onready var menu_panel = $CameraFeedRect/MenuPanel
@onready var entity_node = $CameraFeedRect/MainFeedContainer/MainFeedViewport/Creature/Entity

func _ready():
	menu_panel.connect("interaction_selected", Callable(entity_node, "interact"))
