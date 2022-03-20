extends Reference
class_name Sentence

#   _____            _
#  / ____|          | |
# | (___   ___ _ __ | |_ ___ _ __   ___ ___
#  \___ \ / _ \ '_ \| __/ _ \ '_ \ / __/ _ \
#  ____) |  __/ | | | ||  __/ | | | (_|  __/
# |_____/ \___|_| |_|\__\___|_| |_|\___\___|
#
#
# A Sentence of the Game Rules.
# May be a Statement (what we're used to) or a Condition (useful).
#
# Examples:
#
# - LAEC IS YOU
# - VOTE IS PUSH AND OPEN
#   → VOTE IS PUSH
#   → VOTE IS OPEN
# - URN AND DOOR IS CLOSE
#   → URN IS CLOSE
#   → DOOR IS CLOSE
# - NOT PHI AND TV IS WEAK
#   → (NOT PHI) IS WEAK
#   → TV IS WEAK
# - FRANCE HAS PHI
#
#
# Known Limitations:
# - Only one verb is allowed
# 	- FRANCE IS YOU AND HAS PHI
#   	→ FRANCE IS YOU
#
#
# See also `tests/Sentence.test.gd`.
# See also `GRAMMAR.md`


# Due to a bug in Godot, we can't use class_name (on windows)
const Epithet = preload("res://core/Epithet.gd")
const Attribute = preload("res://core/Attribute.gd")
const Item = preload("res://addons/laec-is-you/entity/Item.gd")


# We also use this class to check a sentence's validity.
# Build a Sentence from a list of Items, and check this property afterwards,
# to see if the sentence makes any sense grammatically.
# If this property is false, the other properties should be ignored,
# as they may not be set, and if they are they will be meaningless.
var is_valid := false  # prefer reading from is_valid_statement

# Perhaps move to the Statement semantics ?
# Statements: effective rules (usually written on the map)
# Conditions: similar grammar, but interpreted as a condition
var is_valid_statement := false setget ,get_is_valid_statement
func get_is_valid_statement():
	return is_valid


# Conditions have less stringent constraints.
# We use conditions in achievements.
# Valid conditions include:
# - THING
# - 3 THING
# - 42 THING
# - 1 3 3 7 THING
# - 4 THING IS QUALITY
var is_valid_condition := false


var subjects : Array  # of Subject
var verb : Verb
var complements : Array  # of Complement


# The list of Items composing this sentence
# This is useful to lit up the words and remove "embedded" sentences,
# like NOT BABA IS YOU not also yielding BABA IS YOU.
# This value is garbage and unreliable when the sentence is not valid.
var items_used : Array  # of Item


#   _____           _       _ _          _   _
#  / ____|         (_)     | (_)        | | (_)
# | (___   ___ _ __ _  __ _| |_ ______ _| |_ _  ___  _ __
#  \___ \ / _ \ '__| |/ _` | | |_  / _` | __| |/ _ \| '_ \
#  ____) |  __/ |  | | (_| | | |/ / (_| | |_| | (_) | | | |
# |_____/ \___|_|  |_|\__,_|_|_/___\__,_|\__|_|\___/|_| |_|
#
#


func _to_string():
	return "Sentence(%s %s %s)" % [
		self.subjects,
		self.verb,
		self.complements,
	]


func to_pretty_string() -> String:
	var s = ""

	if self.subjects:
		for i in range(self.subjects.size()):
			if i > 0:
				s += ' and '
			var subject = self.subjects[i]
			s += subject.to_pretty_string()

	if self.verb:
		if not s.empty():
			s += ' '
		s += self.verb.to_pretty_string()

	if self.complements:
		if not s.empty():
			s += ' '
		for i in range(self.complements.size()):
			if i > 0:
				s += ' and '
			var complement = self.complements[i]
			s += complement.to_pretty_string()

	return s.to_upper()

################################################################################

func are_items_text(items:Array) -> bool:
	for item in items:
		if not item.is_text:
			return false
	return true

################################################################################

# Careful, the used_items will be shallow entities created by this method,
# not actual nodes in the Level scene !
func from_string(sentence_string:String):
	sentence_string = sentence_string.strip_edges()
	var items := Array()
	for word in sentence_string.split(' '):
		var item = Item.new()
		item.is_text = true
		item.concept_name = word
		items.append(item)
	return from_items(items)

# Hand-crafted parser, since we don't have lexer/parser generation from ANTLR,
# not any gdscript bindings for liboost.  (would they work in HTML exports?)
# Not a static factory, but could be.  (requires shenanigans, so this is fine)
# This is not meant to be run more than once.  (would need a reset() method)
func from_items(items:Array):
	assert(are_items_text(items))  # dev paranoia
	if not are_items_text(items):
		return

	# Commented 'cause conditions may be shorter
	# (BABA is a valid condition I think?)
#	var items_amount = items.size()
#	if 3 > items_amount:
#		return

	var items_left := items.duplicate()
	
	# I. Subject(s)

	var has_consumed_at_least_one_subject := false
	var first_subject := true
	var keep_finding_subjects := true

	while keep_finding_subjects:

		var and_consumption := Consumption.new(items_left)
		if not first_subject:
			and_consumption = consume_and(items_left)
			if not and_consumption.has_happened():
				break

		var subject_consumption := consume_subject(and_consumption.items_after)

		if subject_consumption.has_happened():
			has_consumed_at_least_one_subject = true
			items_left = subject_consumption.items_after
			if and_consumption.has_happened():
				self.items_used += and_consumption.items_consumed
			self.items_used += subject_consumption.items_consumed
		else:
			keep_finding_subjects = false

		first_subject = false

	if not has_consumed_at_least_one_subject:
		return  # Sentences require at least one subject

	self.is_valid_condition = true

	# II. Verb

	var verb_consumption := consume_verb(items_left)
	var verb_concept := Words.UNDEFINED

	if not verb_consumption.has_happened():
		return  # Statements require a verb
	else:
		verb_concept = verb_consumption.items_consumed[0].concept_name
		items_left = verb_consumption.items_after
		self.items_used += verb_consumption.items_consumed


	# III. Complement(s)

	var complements_filter = {'is_thing': true}
	if Words.VERB_IS == verb_concept:
		complements_filter = {}

	var verb_requires_complement := true  # always, for now
	var has_consumed_at_least_one_complement = false
	var keep_finding_complements = true
	var first_complement = true

	while keep_finding_complements:

		var and_consumption = Consumption.new(items_left)
		if not first_complement:
			and_consumption = consume_and(items_left)
			if not and_consumption.has_happened():
				break

		var complement_consumption = consume_complement(
			and_consumption.items_after, complements_filter
		)

		if complement_consumption.has_happened():
			has_consumed_at_least_one_complement = true
			items_left = complement_consumption.items_after
			if and_consumption.has_happened():
				self.items_used += and_consumption.items_consumed
			self.items_used += complement_consumption.items_consumed
		else:
			keep_finding_complements = false

		first_complement = false

	if verb_requires_complement and not has_consumed_at_least_one_complement:
		# We could not find any complement to consume → GTFO
		return

	# Everything checks out, it seems — let's tag this sentence as valid
	self.is_valid = true


################################################################################

#   _____                                      _   _
#  / ____|                                    | | (_)
# | |     ___  _ __  ___ _   _ _ __ ___  _ __ | |_ _  ___  _ __
# | |    / _ \| '_ \/ __| | | | '_ ` _ \| '_ \| __| |/ _ \| '_ \
# | |___| (_) | | | \__ \ |_| | | | | | | |_) | |_| | (_) | | | |
#  \_____\___/|_| |_|___/\__,_|_| |_| |_| .__/ \__|_|\___/|_| |_|
#                                       | |
#                                       |_|
# We eat the bits of sentences.  Makes backtracking easier.
#
# These advance the parser cursor (via the returned Consumption),
# AND
# they set the various self properties of this Sentence, as relevant.
#
# In here we assume that all provided items are is_text already.
# Probably best, for perf, to only check all items for is_text once.
# We do that in from_items()
# We can still use assert(are_items_text(items)) everywhere if you'd rather.
#

func consume_subject(items:Array) -> Consumption:
	var consumption := Consumption.new(items)
	if not items:
		return consumption

	var subject := Subject.new()

	var quantifier_consumption := consume_subject_quantifier(
		items,
		subject
	)
	var prefixes_consumption := consume_subject_epithet_prefixes(
		quantifier_consumption.items_after,
		subject
	)
#	var body_consumption := consume_subject_topic(  # or noun?
	var body_consumption := consume_subject_body(
		prefixes_consumption.items_after,
		subject
	)
	if not body_consumption.has_happened():
		return consumption
	
#	var suffix_consumption := consume_subject_epithet_suffix(
#		items,
#		subject
#	)

#	var attributes_consumption = consume_subject_attributes(
#		body_consumption.items_after,
#		subject
#	)
	var attributes_consumption = consume_subject_attributes(
		body_consumption.items_after,
		subject
	)
	
	self.subjects.append(subject)
	consumption.advance_by(quantifier_consumption)
	consumption.advance_by(prefixes_consumption)
	consumption.advance_by(body_consumption)
#	consumption.advance_by(suffix_consumption)
	consumption.advance_by(attributes_consumption)
	
	return consumption


func consume_subject_epithet_prefixes(items:Array, subject:Subject) -> Consumption:
	var consumption := Consumption.new(items)
	var first_epithet := true
	var keep_finding_epithets := true

	while keep_finding_epithets:

		var and_consumption := Consumption.new(consumption.items_after)
		if not first_epithet:
			and_consumption = consume_and(consumption.items_after)
			if not and_consumption.has_happened():
				keep_finding_epithets = false
				break

		var epithet_consumption := consume_subject_epithet_prefix(
			and_consumption.items_after, subject
		)

		if epithet_consumption.has_happened():
			if and_consumption.has_happened():
				consumption.advance_by(and_consumption)
			consumption.advance_by(epithet_consumption)
		else:
			keep_finding_epithets = false
			break  # for good measure

		first_epithet = false

	return consumption


func consume_subject_epithet_prefix(items:Array, subject:Subject) -> Consumption:
	var consumption := Consumption.new(items)
	if not items:
		return consumption
	
	var was_negated := false
	var nots_consumption = consume_nots(items)
	if nots_consumption.has_happened():
		was_negated = nots_consumption.has_consumed_odd_amount()
	
	var has_epithet := false
	var cursor := 0
	var item_concept : String = items[cursor].get_concept_name()
	if item_concept in Words.EPITHET_PREFIXES:
		var epithet = Epithet.new()
		epithet.concept = item_concept
		epithet.negated = was_negated
		subject.epithets_prefixes.append(epithet)
		### DEPRECATED #
		#subject.prefix_negated = was_negated
		#subject.prefix = item_concept
		################
		has_epithet = true
	
	if has_epithet:
		if nots_consumption.has_happened():
			consumption.advance_by(nots_consumption)
		consumption.happen_once()
	
	return consumption


func consume_subject_attributes(items:Array, subject:Subject) -> Consumption:
	var consumption := Consumption.new(items)
	var first_attribute := true
	var keep_finding_attributes := true

	while keep_finding_attributes:

		var and_consumption := Consumption.new(consumption.items_after)
		if not first_attribute:
			and_consumption = consume_and(consumption.items_after)
			if not and_consumption.has_happened():
				keep_finding_attributes = false
				break

		var attribute_consumption := consume_subject_attribute(
			and_consumption.items_after, subject
		)

		if attribute_consumption.has_happened():
			if and_consumption.has_happened():
				consumption.advance_by(and_consumption)
			consumption.advance_by(attribute_consumption)
		else:
			keep_finding_attributes = false
			break  # for good measure

		first_attribute = false

	return consumption


func consume_subject_attribute(items:Array, subject:Subject) -> Consumption:
	var consumption := Consumption.new(items)
	if not items:
		return consumption
	
	var preposition_negated := false
	var prepo_nots_consumption := consume_nots(items)
	if prepo_nots_consumption.has_happened():
		preposition_negated = prepo_nots_consumption.has_consumed_odd_amount()
	
	var prepo_consumption := consume_preposition(prepo_nots_consumption.items_after)
	if not prepo_consumption.has_happened():
		return consumption  # preposition is required (for now?)
	
	var noun_negated := false
	var noun_nots_consumption := consume_nots(prepo_consumption.items_after)
	if noun_nots_consumption.has_happened():
		noun_negated = noun_nots_consumption.has_consumed_odd_amount()
	
	var noun_consumption := consume_noun(noun_nots_consumption.items_after)
	if not noun_consumption.has_happened():
		return consumption  # noun is required (for now?)
	
	consumption.advance_by(prepo_nots_consumption)
	consumption.advance_by(prepo_consumption)
	consumption.advance_by(noun_nots_consumption)
	consumption.advance_by(noun_consumption)
	
	var attribute = Attribute.new()
	attribute.preposition_negated = preposition_negated
	attribute.preposition = prepo_consumption.items_consumed[0].get_concept_name()
	attribute.noun_negated = noun_negated
	attribute.noun = noun_consumption.items_consumed[0].get_concept_name()
	subject.attributes.append(attribute)
	
	return consumption


#func consume_subject_on_suffix(items:Array, subject:Subject) -> Consumption:
#	breakpoint  # method unused anymore
#
#	var consumption = Consumption.new(items)
#	var amount_of_items = items.size()
#	if (not items) or (2 > amount_of_items) :
#		return consumption
#
#	var cursor := 0
#	var not_on_thing := false
#	while items[cursor].is_operator_not():
#		not_on_thing = not not_on_thing
#		cursor += 1
#		if cursor >= amount_of_items:
#			return consumption
#
#	if 2 + cursor > amount_of_items:
#		return consumption
#
#	var on_item = items[cursor]
#	if not on_item.is_text_concept(Words.OPERATOR_ON):
#		return consumption
#	cursor += 1
#
#	var on_not_thing := false
#	while items[cursor].is_operator_not():
#		on_not_thing = not on_not_thing
#		cursor += 1
#		if cursor >= amount_of_items:
#			return consumption
#
#	var piled_thing = items[cursor]
#	if not piled_thing.is_text_thing():
#		return consumption
#	cursor += 1
#
#	subject.on_thing = piled_thing.concept_name
#	subject.not_on_thing = not_on_thing
#	subject.on_not_thing = on_not_thing
#
#	consumption.items_consumed = items.slice(0, cursor-1)  # inclusive /!.
#	if cursor < items.size():
#		consumption.items_after = items.slice(cursor, items.size()-1)
#
#	return consumption


func consume_subject_quantifier(items:Array, subject:Subject) -> Consumption:
	var consumption = Consumption.new(items)
	if not items:
		return consumption

	var cursor := 0

	# I. Match diversity
	var diversity = Words.DIVERSITY_ANY
	# …

	# II. Negate quantity perhaps
	var negated = false
#	var start := cursor
	var amount_of_items = items.size()
	while items[cursor].is_operator_not():
		negated = not negated
		cursor += 1
		if cursor >= amount_of_items:
			# Bunch of NOTs at the end of the sentence → skip
			return consumption

	# III. Match quantities
	var amount := 0
	var consumed_amount := 0
	while items[cursor+consumed_amount].is_quantity():
		amount = ( amount * 10 ) + items[cursor+consumed_amount].to_quantity()  # 13 37 → 167 /!.
		consumed_amount += 1
		if cursor+consumed_amount >= amount_of_items:
			# Just a bunch of numbers without subject
			break  # carry on, it's a valid condition

	# IV. Default to ONE but only if no quantity has matched, to allow ZERO
	if 0 == consumed_amount and 0 == amount:
		amount = 1

	# V. Output
	if 0 < consumed_amount:
		consumption.items_consumed = items.slice(  # inclusive
			0,
			cursor + consumed_amount - 1
		)
		if consumed_amount < items.size():
			consumption.items_after = items.slice(  # inclusive
				cursor + consumed_amount,
				items.size() - 1
			)

		subject.quantifier.negated = negated

	subject.quantifier.amount = amount
	subject.quantifier.diversity = diversity

	return consumption


func consume_subject_body(items: Array, subject: Subject) -> Consumption:
	var consumption = Consumption.new(items)
	if not items:
		return consumption

	var negated = false
	var start := 0
	var amount_of_items = items.size()
	while items[start].is_operator_not():
		negated = not negated
		start += 1
		if start >= amount_of_items:
			# Bunch of NOTs at the end of the sentence → skip
			return consumption

	if items[start].is_thing:
		subject.negated = negated
		subject.concept_name = items[start].get_concept_name()

		consumption.items_consumed = items.slice(0, start)
		if start < items.size() - 1:
			consumption.items_after = items.slice(start + 1, items.size() - 1)

	return consumption


func consume_noun(items: Array) -> Consumption:
	var consumption = Consumption.new(items)
	if not items:
		return consumption
	
	if items[0].is_text_noun():
		consumption.happen_once()
	
	return consumption


func consume_preposition(items: Array) -> Consumption:
	var consumption = Consumption.new(items)
	if not items:
		return consumption
	
	if not items[0].is_text:
		return consumption
	
	if items[0].get_concept_name() in Words.PREPOSITIONS:
		consumption.happen_once()
	
	return consumption


func consume_nots(items: Array) -> Consumption:
	var consumption = Consumption.new(items)
	if not items:
		return consumption
	
	var cursor := 0
	while cursor < items.size() and items[cursor].is_concept(Words.OPERATOR_NOT):
		consumption.happen_once()
		cursor += 1
	
	return consumption


func consume_and(items: Array) -> Consumption:
	var consumption = Consumption.new(items)
	if not items:
		return consumption

	var item : Item = items[0]
	if item.is_concept(Words.OPERATOR_AND):
		consumption.items_consumed.append(item)
		if 1 < items.size():
			consumption.items_after = items.slice(1, items.size() - 1)

	return consumption


func consume_verb(items: Array) -> Consumption:
	var consumption = Consumption.new(items)
	if not items:
		return consumption

	var item : Item = items[0]
	var item_concept = item.get_concept_name()
	if Words.VERBS.has(item_concept):
		var found_verb = Verb.new()
		found_verb.concept_name = item_concept
		self.verb = found_verb

		consumption.items_consumed.append(item)
		if 1 < items.size():
			consumption.items_after = items.slice(1, items.size() - 1)

	return consumption


func consume_complement(items:Array, filters:Dictionary) -> Consumption:
	var consumption = Consumption.new(items)
	if not items:
		return consumption

	var complement = Complement.new()

	var body_consumption := consume_complement_body(
		items,
		complement,
		filters
	)

	if body_consumption.has_happened():
		self.complements.append(complement)
		consumption.items_consumed = (
#			prefix_consumption.items_consumed
#			+
			body_consumption.items_consumed
		)
		consumption.items_after = body_consumption.items_after

	return consumption


func consume_complement_body(items:Array, complement:Complement, filters:Dictionary) -> Consumption:
	var consumption = Consumption.new(items)
	if not items:
		return consumption

	var negated = false
	var start := 0
	var amount_of_items = items.size()
	while items[start].is_operator_not():
		negated = not negated
		start += 1
		if start >= amount_of_items:
			return consumption

	var item : Item = items[start]
	if (
		(item.is_thing or item.is_quality)
		and
		does_item_match_filters(item, filters)
	):
		complement.negated = negated
		complement.concept_name = items[start].get_concept_name()

		consumption.items_consumed = items.slice(0, start)
		if start < items.size() - 1:
			consumption.items_after = items.slice(start + 1, items.size() - 1)

	return consumption


################################################################################

func does_item_match_filters(item:Item, filters:Dictionary) -> bool:
	for filter_property in filters:
		if item.get(filter_property) != filters[filter_property]:
			return false
	return true

################################################################################


func contains_sentence(other_sentence:Sentence) -> bool:
	for item in other_sentence.items_used:
		if not self.items_used.has(item):
			return false
	return true


func uses_concept(concept) -> bool:
	# TODO: prefixes, quantifiers, etc.
	for complement in self.complements:
		if complement.concept_name == concept:
			return true
	for subject in self.subjects:
		if subject.concept_name == concept:
			return true
	return false


func uses_any_concept(concepts: Array) -> bool:
	var any_was_used := false
	for concept in concepts:
		if uses_concept(concept):
			any_was_used = true
			break
	return any_was_used


func has_complement_quality(quality_concept) -> bool:
	for complement in self.complements:
		if complement.concept_name == quality_concept:
			return true
	return false


#  _____            _
# |  __ \          | |
# | |  | |_   _ ___| |_ _   _
# | |  | | | | / __| __| | | |
# | |__| | |_| \__ \ |_| |_| |
# |_____/ \__,_|___/\__|\__, |
#                        __/ |
#                       |___/

################################################################################
# The Regex approach.
# Why yes:
# → closest thing to ebnf
# → less code to maintain
# → nih, dry, kiss, etc.
# Why not:
# → we also need to keep track of items used  /!.
# → would require multiple regexes (kind of ok though)

# BABA AND CRAB IS YOU
# BABA IS YOU AND CRAB
# BABA IS YOU AND HAS NOT CRAB
# → BABA IS YOU
# → BABA HAS NOT CRAB
# BABA IS YOU AND NOT CRAB
# BABA NOT CRAB IS YOU => NOT CRAB IS YOU

#func from_string(sentence_string:String):
#	var sentence_regex = RegEx.new()
#	sentence_regex.compile(
#		"^" +
#		"(?<prefix_full>(?<prefix_negation>(?:not )+|)(?<prefix>lonely) |)" +
#		"(?<things>" +
#			"(?<thing_negation>(?:not )+|)(?<thing>[a-z]+)" +
#		")" +
#		" +" +
#		"(?<verb>%s)" % [array_join(VERBS, '|')] +
#		" +" +
#		"(?<complements>.+)" +
##		"(?<complements>(?:" +
##			"(?: and )?" +
##			"(?<quality>[a-z]+)" +
##		")+)" +
#		"$"
#	)
#
#	var result = sentence_regex.search(sentence_string)
#	if not result:
#		return
#
#	prints('prefix_full', result.get_string('prefix_full'))
#	prints('prefix_negation', result.get_string('prefix_negation'))
#	prints('prefix', result.get_string('prefix'))
#	prints('thing_negation', result.get_string('thing_negation'))
#	prints('thing', result.get_string('thing'))
#	prints('verb', result.get_string('verb'))
#	prints('qualities', result.get_string('qualities'))
#	prints('quality', result.get_string('quality'))
#	prints('complements', result.get_string('complements'))
#
#	print(result.strings)
#
##	var complements_regex = RegEx.new()
##	complements_regex.compile(
##		"^(?:([a-z]+)(?: and )?)+$"
##	)
##	var complements_result = complements_regex.search(result.get_string('complements'))
##	if not complements_result:
##		return
#
#	self.complements = result.get_string('complements').split(' and ')
#	if not complements:
#		return
#
##	for i in range(self.complements)
#
##	print(complements_result.strings)
##	self.complements = complements_result.strings
##	self.complements.pop_front()
#
#	self.is_valid = true
#	self.verb = result.get_string('verb')
#	self.subjects_prefix = result.get_string('prefix')
#
#
#
#func array_join(arr : Array, glue : String = '') -> String:
#	var string : String = ''
#	for index in range(0, arr.size()):
#		string += str(arr[index])
#		if index < arr.size() - 1:
#			string += glue
#	return string
