## Holds generic and contextual dialogue lines for NPC-to-NPC talking.
## HOW TO USE:
## - Call NPCDialoguePool.get_random_dialogue(context: String = "") to get a random dialogue array (alternating lines for two NPCs).
## - Inject contextual lines by extending the POOL or using EventsManager flags.

extends Node

var GENERIC_DIALOGUES = [
	["How's your shift?", "Quiet so far."],
	["Did you see the new orders?", "Yeah, looks like another late night."],
	["Coffee at the mess after this?", "Count me in."],
	["These hallways give me the creeps.", "You get used to it... or not."],
]

var CONTEXTUAL_DIALOGUES = {
	"entity_weakness_sound": [
		["Did you hear that the Beasts are weak to sound?", "Yeah, HQ just confirmed it!"],
	],
}

# Returns an array of two or more lines (alternating speakers)
func get_random_dialogue(context: String = "") -> Array:
	# If context flag present, use contextual dialogues
	if context != "" and CONTEXTUAL_DIALOGUES.has(context):
		var pool = CONTEXTUAL_DIALOGUES[context]
		return pool[randi() % pool.size()]
	# Otherwise, use generic pool
	var pool = GENERIC_DIALOGUES
	return pool[randi() % pool.size()]

# Example of adding contextual dialogue based on EventManager flag
func update_contextual_dialogues():
	if EventsManager.get_flag("discovered_weakness_sound"):
		CONTEXTUAL_DIALOGUES["entity_weakness_sound"] = [
			["Did you hear that the Beasts are weak to sound?", "Yeah, HQ just confirmed it!"],
		]
