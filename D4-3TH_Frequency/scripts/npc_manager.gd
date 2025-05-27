## NPCManager: Only registers NPCs.
## HOW TO USE:
## - Call NPCManager.register_all_npcs(npcs) from your main scene's _ready().
## - Place as Autoload singleton or attach to your main scene.

extends Node

var all_npcs: Array = []

func _ready():
	print("NPCManager: Initialized.")

# Called once at game start; pass all NPC nodes
func register_all_npcs(npcs: Array):
	all_npcs = npcs
	# No need to manage active/sleeping lists, as NPCs are self-managing their idle/action cycle
	print("NPCManager: Registered %d total NPCs." % all_npcs.size())

# These functions are kept as stubs for clarity that they are no longer used.
func request_talk(npc_requester):
	print("NPCManager: (OLD/DISABLED) '%s' requested to talk. Ignoring." % npc_requester.name)
	pass

func npc_went_to_sleep(npc):
	print("NPCManager: (OLD/DISABLED) '%s' attempted to go to sleep. Sleep system removed." % npc.name)
	pass

func npc_woke_up(npc):
	print("NPCManager: (OLD/DISABLED) '%s' attempted to wake up. Sleep system removed." % npc.name)
	pass
