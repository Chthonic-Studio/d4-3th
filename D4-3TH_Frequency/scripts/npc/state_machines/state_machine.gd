## Resource: State machine for NPCs. Expand with states/logic as needed.
extends Resource
class_name StateMachine

@export var state: String = "idle" # e.g., "idle", "patrolling", "sabotaging"
@export var state_data: Dictionary = {}
