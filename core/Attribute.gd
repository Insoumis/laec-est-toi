extends Reference
#class_name Attribute

#          _   _        _ _           _
#     /\  | | | |      (_) |         | |
#    /  \ | |_| |_ _ __ _| |__  _   _| |_ ___
#   / /\ \| __| __| '__| | '_ \| | | | __/ _ \
#  / ____ \ |_| |_| |  | | |_) | |_| | ||  __/
# /_/    \_\__|\__|_|  |_|_.__/ \__,_|\__\___|
#
# Eg: ON BABA, FACING WALL
# 
# Suffixed to a noun in a sentence, usually (always) the noun of a subject.
# 
# Ideas:
# Perhaps we'll also allow attributes to nouns of sentence complements later.
# 	→ What sense does this make:  BABA IS KEKE ON BABA  ?

var preposition_negated := false
var preposition : String  # "on", "facing", etc.  One of Words.PREPOSITION_XXXX

var noun_negated := false
var noun : String  # complement of the preposition, ie: "baba" in "keke on baba"


func to_pretty_string(uppercase := true) -> String:
	var s := ""
	if self.preposition:
		s += 'not ' if self.preposition_negated else ''
		s += self.preposition
	if self.noun:
		s += ' ' if s else ''
		s += 'not ' if self.noun_negated else ''
		s += self.noun
	return s.to_upper() if uppercase else s

