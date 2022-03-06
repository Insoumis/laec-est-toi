extends Reference
class_name Condition

var sentence : Sentence

#var subject : Subject
#var verb : Verb
#var complement : Complement


func _to_string():
	if not self.sentence:
		return "Condition(UNDEFINED)"
	return "Condition(%s %s %s)" % [
		self.sentence.subjects,
		self.sentence.verb,
		self.sentence.complement
	]


func from_string(condition_string):
	var __sentence = Sentence.new()
	
	__sentence.from_string(condition_string)
	
	if not __sentence.is_valid_condition:
		printerr('Invalid sentence in condition : %s' % [sentence])
	
	self.sentence = __sentence


func is_validated_by_level(level) -> bool:
	if not self.sentence:
		printerr("Condition has no sentence! %s" % self)
		return false
	if not self.sentence.subjects:
		printerr("Condition has no subjects! %s" % self)
		return false
	
	if not self.sentence.verb:
		# I. QUANTITY THING
		# 
		# We may have no-verb conditions, such as:
		# - 3 laec
		# - three laec (unsupported right now)
		
		var all_subjects_validated = true
		for subject in self.sentence.subjects:
			var subject_validated = false
			
			var amount_found = 0
			for thing in level.get_things_matching_subject(subject, true):
				# filter thing by prefix, first
				# …
				amount_found += 1
			
			if subject.quantifier.negated:
				if amount_found < subject.quantifier.amount:
					subject_validated = true
			else:
				if amount_found >= subject.quantifier.amount:
					subject_validated = true
			
			if not subject_validated:
				all_subjects_validated = false
		
		return all_subjects_validated
		
	else:
		# II. THING IS …
		if not self.sentence.complements:
			printerr("Condition has a verb but no complement(s): %s" % self)
			return false
		
		# III. THING IS THING
		# makes no sense as a condition
		
		# IV. THING IS QUALITY
		#     THING IS NOT QUALITY
		#     4 THING IS QUALITY
		#     NOT 3 THING IS NOT QUALITY
		var all_subjects_validated = true
		for subject in self.sentence.subjects:
			var subject_validated = false
			var all_complements_validated = true
			for complement in self.sentence.complements:
				if not Words.is_quality(complement.concept_name):
					printerr("Ignoring complement `%s' since it is not a quality." % [
						complement
					])
					continue
				
				var complement_validated = false
				
				var things = level.get_specific_things_with_qualities(
					subject.concept_name,
					{
						complement.concept_name: not complement.negated,
					}
				)
				var amount_found = things.size()
				
				if subject.quantifier.negated:
					if amount_found < subject.quantifier.amount:
						complement_validated = true
				else:
					if amount_found >= subject.quantifier.amount:
						complement_validated = true
				
				if not complement_validated:
					all_complements_validated = false
			
			subject_validated = all_complements_validated
			
			if not subject_validated:
				all_subjects_validated = false
		
		if all_subjects_validated:
			return true
	
	return false
