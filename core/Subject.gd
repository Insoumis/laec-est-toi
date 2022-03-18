extends Reference
class_name Subject

# One Subject of a Sentence.
# A Sentence may have multiple Subjects.

var concept_name : String = ''  # eg: baba
var negated : bool = false  # concept_negated more accurately

# Quantities are only used in conditions
var quantifier := Quantifier.new()

# Eg: LONELY
var epithets_prefixes := Array()  # of Epithet
#var epithets_suffixes := Array()  # of Epithet

# deprecated, use epithets above instead
var prefix : String = ''  # eg: lonely
var prefix_negated : bool = false
############

# Eg: WITH XXXX
var attributes := Array()  # of Attribute

# shorthand sugar
var is_thing : bool setget set_is_thing, get_is_thing


func set_is_thing(_value: bool):
	printerr("Sentence.is_thing is READ ONLY")
	breakpoint


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
	return "%s(%s)" % [
#		self.get_class(),  # == "Reference"
		'Subject',
		to_pretty_string(),
	]


func to_pretty_string() -> String:
	var ps := ""
	for epithet in self.epithets_prefixes:
		ps += "%s " % [epithet.to_pretty_string()]
	ps += 'not ' if self.negated else ''
	ps += "%s" % [self.concept_name]
	for attribute in self.attributes:
		ps += " %s" % [attribute.to_pretty_string()]
	
	return ps.to_upper()
#	return ("%s%s%s%s" % [
#		'not ' if self.prefix_negated else '',
#		self.prefix + (' ' if self.prefix else ''),
#		'not ' if self.negated else '',
#		self.concept_name,
#	]).to_upper()

