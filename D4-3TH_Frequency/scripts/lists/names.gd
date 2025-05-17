extends Node

const MALE_FIRST_NAMES = [
	"John", "Alex", "David", "Victor", "Sergei", "Kenji", "Carlos", "Ivan"
	# ...etc
]
const FEMALE_FIRST_NAMES = [
	"Anna", "Maria", "Sofia", "Elena", "Yuki", "Tatiana", "Gabriela", "Sara"
	# ...etc
]
const LAST_NAMES = [
	"Smith", "Ivanov", "Garcia", "Kowalski", "Tanaka", "Dubois", "Müller", "Kim"
	# ...etc
]

# Utility function for random gender selection
func get_random_operator_name() -> String:
	var gender = ["male", "female"].pick_random()
	return get_random_name(gender)

func get_random_name(gender:String="male") -> String:
	var first_name = MALE_FIRST_NAMES.pick_random() if gender == "male" else FEMALE_FIRST_NAMES.pick_random()
	var last_name = LAST_NAMES.pick_random()
	return "%s %s" % [first_name, last_name]
