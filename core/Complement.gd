extends Reference
class_name Complement


# One Complement of a Sentence.
# A Sentence may have multiple Complements and must have at least one,
# and they may be things or qualities. (or 'group' if we ever support it)


var concept_name : String = ''  # eg: "you", "crab"
var negated : bool = false


var is_quality : bool setget ,get_is_quality
var is_thing : bool setget ,get_is_thing


func _to_string() -> String:  # for debugging purposes
	return "%s(%s%s)" % [
#		self.get_class(),  # == "Reference"
		'Complement',
		'not ' if self.negated else '',
		self.concept_name,
	]


func to_pretty_string() -> String:
	return ("%s%s" % [
		'not ' if self.negated else '',
		self.concept_name,
	]).to_upper()



################################################################################

func get_is_quality() -> bool:
	return Words.is_quality(self.concept_name)

func get_is_thing() -> bool:
	return Words.is_thing(self.concept_name)
