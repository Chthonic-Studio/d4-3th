extends Resource
class_name NPCStateMachine

@export var state: String = "idle" # "idle", "moving", "patrolling", "talking", "sleeping", "attacking", "shooting"
@export var state_data: Dictionary = {} 
