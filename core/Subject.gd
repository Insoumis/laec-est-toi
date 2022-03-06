extends Reference
class_name Subject

# One Subject of a Sentence.
# A Sentence may have multiple Subjects

var concept_name : String = ''  # eg: baba
var negated : bool = false  # concept_negated more accurately

var quantifier := Quantifier.new()

# Eg: LONELY
var epithets_prefixes := Array()  # of Epithet
#var epithets_suffixes := Array()  # of Epithet
# deprecated
var prefix : String = ''  # eg: lonely
var prefix_negated : bool = false

# deprecated
#var not_on_thing : bool = false
#var on_thing : String = ''  # thing concept we're ON
#var on_not_thing : bool = false
############
# Use attributes instead
var attributes := Array()  # of Attribute

var is_thing : bool setget ,get_is_thing


func get_is_thing() -> bool:
	return Words.is_noun(self.concept_name)


func has_epithet(epithet_concept: String) -> bool:
	if self.prefix == epithet_concept:
		return true
	for epithet in self.epithets_prefixes:
		if epithet.concept == epithet_concept:
			return true  # negation does not matter here
	return false


func _to_string() -> String:  # for debugging purposes
	return "%s(%s%s%s%s)" % [
#		self.get_class(),  # == "Reference"
		'Subject',
		'not ' if self.prefix_negated else '',
		self.prefix + (' ' if self.prefix else ''),
		'not ' if self.negated else '',
		self.concept_name,
	]


func to_pretty_string() -> String:
	return ("%s%s%s%s" % [
		'not ' if self.prefix_negated else '',
		self.prefix + (' ' if self.prefix else ''),
		'not ' if self.negated else '',
		self.concept_name,
	]).to_upper()

