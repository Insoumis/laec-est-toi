extends Reference
class_name Epithet

# May be before (prefix) or after (suffix) the noun in the subject.

var concept := Words.UNDEFINED  # one of Words.EPITHET_XXX
var negated := false


func _to_string() -> String:
	return "Epithet(%s)" % to_pretty_string()


func to_pretty_string() -> String:
	return ("%s%s" % [
		'not ' if self.negated else '',
		self.concept,
	]).to_upper()

