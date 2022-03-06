extends Reference
class_name Action
#class_name AbstractAction <-- probly a good idea here


# Actions are defined in res://core/actions/
# We have, for now:
# - Pass
# - Move
# - Undo


func to_string() -> String:
	assert(false, "Override me!")
	return '?'
