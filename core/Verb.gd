extends Reference
class_name Verb


# In the beginning was The Verb.


var concept_name : String


func _to_string() -> String:  # for debugging purposes
	return "%s(%s)" % [
#		self.get_class(),  # == "Reference"
		'Verb',
		self.concept_name,
	]


func to_pretty_string() -> String:
	return ("%s" % [
		self.concept_name,
	]).to_upper()


func is_word(concept: String) -> bool:
	return self.concept_name == concept
