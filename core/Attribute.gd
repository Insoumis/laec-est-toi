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
var preposition : String  # "on", "facing", etc.

var noun_negated := false
var noun : String  # complement of the preposition, ie: "baba" in "keke on baba"
