## Resource: Role for NPCs. Create resources in the editor for each type.
extends Resource
class_name Role

@export var id: String = "normal" # e.g., "normal", "rebel", "entity"
@export var description: String = ""
