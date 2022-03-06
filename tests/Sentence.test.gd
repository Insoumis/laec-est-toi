# THIS TEST IS DISABLED
# We disabled WAT until it works again
#extends WAT.Test

# Unit tests for sentence detection.
# Will Glomp for Pocky!

#const Item = preload("res://addons/laec-is-you/entity/Item.gd")
#
#func test_sentences() -> void:
#
#	var s : Sentence
#
#	var expectations = [
#		{
#			'sentence': 'baba is you',
#			'valid': true,
#			'valid_condition': true,
#			'subjects': ['baba'],
#			'subjects_negated': [false],
#			'verb': 'is',
#			'complements': ['you'],
#			'complements_negated': [false],
#		},
#		{
#			'sentence': 'baba and france is you',
#			'valid': true,
#			'valid_condition': true,
#			'subjects': ['baba', 'france'],
#			'subjects_negated': [false, false],
#			'verb': 'is',
#			'complements': ['you'],
#			'complements_negated': [false],
#		},
#		{
#			'sentence': 'baba and not france is you and not push',
#			'valid': true,
#			'valid_condition': true,
#			'subjects': ['baba', 'france'],
#			'subjects_negated': [false, true],
#			'verb': 'is',
#			'complements': ['you', 'push'],
#			'complements_negated': [false, true],
#		},
#		{
#			'sentence': 'not not not not france is not not not you',
#			'valid': true,
#			'valid_condition': true,
#			'subjects': ['france'],
#			'subjects_negated': [false],
#			'verb': 'is',
#			'complements': ['you'],
#			'complements_negated': [true],
#			'items_used_amount': 10,
#		},
#		{
#			'sentence': 'not france is you',
#			'valid': true,
#			'valid_condition': true,
#			'subjects': ['france'],
#			'subjects_negated': [true],
#			'verb': 'is',
#			'complements': ['you'],
#			'complements_negated': [false],
#			'items_used_amount': 4,
#		},
#		{
#			'sentence': 'france and spain and germany and italy and not bank is win',
#			'valid': true,
#			'valid_condition': true,
#			'subjects': ['france', 'spain', 'germany', 'italy', 'bank'],
#			'subjects_negated': [false, false, false, false, true],
#			'verb': 'is',
#			'complements': ['win'],
#			'complements_negated': [false],
#			'items_used_amount': 12,
#		},
#		{
#			'sentence': 'baba is you and',
#			'valid': true,
#			'valid_condition': true,
#			'subjects': ['baba'],
#			'subjects_negated': [false],
#			'verb': 'is',
#			'complements': ['you'],
#			'complements_negated': [false],
#			'items_used_amount': 3,
#		},
#		{
#			'sentence': 'baba',
#			'valid': false,
#			'valid_condition': true,
#			'subjects': ['baba'],
#			'subjects_negated': [false],
#			'items_used_amount': 1,
#		},
#		{
#			'sentence': '7 anar',
#			'valid': false,
#			'valid_condition': true,
#			'subjects': ['anar'],
#			'subjects_negated': [false],
#			'complements': [],
#			'complements_negated': [],
#			'items_used_amount': 2,
#		},
#		{
#			'sentence': 'anar on france is win',
#			'valid': true,
#			'valid_condition': true,
#			'subjects': ['anar'],
#			'subjects_negated': [false],
#			'subjects_on_thing': ['france'],
#			'subjects_on_not_thing': [false],
#			'subjects_not_on_thing': [false],
#			'complements': ['win'],
#			'complements_negated': [false],
#			'items_used_amount': 5,
#		},
#		{
#			'sentence': 'anar on not france is not win',
#			'valid': true,
#			'valid_condition': true,
#			'subjects': ['anar'],
#			'subjects_negated': [false],
#			'subjects_on_thing': ['france'],
#			'subjects_on_not_thing': [true],
#			'subjects_not_on_thing': [false],
#			'complements': ['win'],
#			'complements_negated': [true],
#			'items_used_amount': 7,
#		},
#		{
#			'sentence': 'people make justice',
#			'valid': true,
#			'valid_condition': true,
#			'subjects': ['people'],
#			'subjects_negated': [false],
##			'subjects_on_thing': [],
##			'subjects_on_not_thing': [],
##			'subjects_not_on_thing': [],
#			'complements': ['justice'],
#			'complements_negated': [false],
#			'items_used_amount': 3,
#		},
#	]
#
#	for expectation in expectations:
#		s = Sentence.new()
#		var items := Array()
#		for word in expectation['sentence'].split(' '):
#			var item = Item.new()
#			item.is_text = true
#			item.concept_name = word
#			items.append(item)
#		s.from_items(items)
#
#		if expectation['valid_condition']:
#			asserts.is_true(
#				s.is_valid_condition,
#				"Sentence `%s` is valid condition." % [expectation['sentence']]
#			)
#		else:
#			asserts.is_false(
#				s.is_valid_condition,
#				"Sentence `%s` is not valid condition." % [expectation['sentence']]
#			)
#
#		if expectation['valid']:
#			asserts.is_true(s.is_valid, "Sentence `%s` is valid." % [expectation['sentence']])
##			if not s.is_valid:
##				continue
#		else:
#			asserts.is_false(s.is_valid, "Sentence `%s` is not valid." % [expectation['sentence']])
##			continue
#
#		if s.is_valid or s.is_valid_condition:
#			var actual_subjects := Array()
#			var actual_subjects_negated := Array()
#			var actual_subjects_on_things := Array()
#			var actual_subjects_not_on_things := Array()
#			var actual_subjects_on_not_things := Array()
#			for subject in s.subjects:
#				actual_subjects.append(subject.concept_name)
#				actual_subjects_negated.append(subject.negated)
#				actual_subjects_on_things.append(subject.on_thing)
#				actual_subjects_on_not_things.append(subject.on_not_thing)
#				actual_subjects_not_on_things.append(subject.not_on_thing)
#			asserts.is_equal(expectation['subjects'], actual_subjects, "Subjects are detected.")
#			asserts.is_equal(expectation['subjects_negated'], actual_subjects_negated, "Subjects' negations are detected.")
#			if expectation.has('subjects_on_thing'):
#				asserts.is_equal(expectation['subjects_on_thing'], actual_subjects_on_things, "Subjects' ON are detected.")
#			if expectation.has('subjects_on_not_thing'):
#				asserts.is_equal(expectation['subjects_on_not_thing'], actual_subjects_on_not_things, "Subjects' ON NOT are detected.")
#			if expectation.has('subjects_not_on_thing'):
#				asserts.is_equal(expectation['subjects_not_on_thing'], actual_subjects_not_on_things, "Subjects' NOT ON are detected.")
#
#
#		if expectation.has('verb') and s.is_valid:
#			asserts.is_equal(s.verb.concept_name, expectation['verb'], "Verb is detected.")
#		if expectation.has('complements' and s.is_valid):
#			var actual_complements := Array()
#			var actual_complements_negated := Array()
#			for complement in s.complements:
#				actual_complements.append(complement.concept_name)
#				actual_complements_negated.append(complement.negated)
#			asserts.is_equal(expectation['complements'], actual_complements, "Complements are detected.")
#			asserts.is_equal(expectation['complements_negated'], actual_complements_negated, "Complements' negations are detected.")
#
#		if expectation.has('items_used_amount'):
#			asserts.is_equal(
#				expectation['items_used_amount'],
#				s.items_used.size(),
#				"Correct amount of items used."
#			)
		
#		if expectation.has('subjects_on_thing'):
#			asserts.is_equal(
#				expectation['items_used_amount'],
#				s.items_used.size(),
#				"Correct amount of items used."
#			)
			

