class_name Words

# Essentially a database of the terminal symbols of our grammar.
# Except for the _things_, to make adding new things easy.
# 
# Could also be a Resource, in the usual Godot fashion,
# but it might be a little less convenient, so this is fine.
# 
# Here's some documentation about the intended meaning of these words :
# https://framagit.org/laec-is-you/laec-is-you/-/wikis/en/02.-Game-Rules
# 
# The choice of String (instead of the more performant Integer)
# for these constants stems from first-day KISS.
# If it becomes a bottleneck, sorry about that.
# 
# A good try to re-architect all this would be to create at least one file per
# word, and figure out how to orchestrate everything.
# 
# 
# Hello, curious reader !   I wish you a good day !  ;)

# Semantics
# ---------
# 
# SUBJECT VERB COMPLEMENT
# See docs/GRAMMAR.en.md


const UNDEFINED := 'undefined'


const VERB_IS := 'is'
const VERB_HAS := 'has'
const VERB_MAKE := 'make'

const VERBS := [
	VERB_IS,
	VERB_HAS,
	VERB_MAKE,
]


const OPERATOR_AND := 'and'
const OPERATOR_NOT := 'not'

const OPERATORS := [
	OPERATOR_AND,
	OPERATOR_NOT,
]


const PREPOSITION_ON := 'on'
const PREPOSITION_WITH := 'with'

const PREPOSITIONS := [
	PREPOSITION_ON,
	PREPOSITION_WITH,
]


const QUALITY_YOU := 'you'
const QUALITY_WIN := 'win'
const QUALITY_DEFEAT := 'defeat'
const QUALITY_STOP := 'stop'
const QUALITY_PUSH := 'push'
const QUALITY_PULL := 'pull'
const QUALITY_SINK := 'sink'
const QUALITY_VOID := 'void'
const QUALITY_WEAK := 'weak'
const QUALITY_OPEN := 'open'
const QUALITY_SHUT := 'shut'
const QUALITY_HOT := 'hot'
const QUALITY_MELT := 'melt'
const QUALITY_MOVE := 'move'
const QUALITY_POET := 'poet'
const QUALITY_YODA := 'yoda'
const QUALITY_MORE := 'more'
const QUALITY_BOOM := 'boom'
# … #AddQuality and update the QUALITIES const below as well.

const QUALITIES := [
	QUALITY_YOU,
	QUALITY_WIN,
	QUALITY_DEFEAT,
	QUALITY_STOP,
	QUALITY_PUSH,
	QUALITY_PULL,
	QUALITY_SINK,
	QUALITY_VOID,
	QUALITY_WEAK,
	QUALITY_OPEN,
	QUALITY_SHUT,
	QUALITY_HOT,
	QUALITY_MELT,
	QUALITY_MOVE,
	QUALITY_POET,
	QUALITY_YODA,
	QUALITY_MORE,
	QUALITY_BOOM,
	# … #AddQuality
]


const EPITHET_PREFIX_LONELY := 'lonely'

const EPITHET_PREFIXES := [
	EPITHET_PREFIX_LONELY,
]

# Perhaps someday we'll want suffixes as well
#const EPITHET_SUFFIX_COOL := 'cool'  # baba cool is you  X]


# I don't think we use those yet.  Do we?
const DIVERSITY_ANY := 'any'
const DIVERSITY_ALL := 'all'

const DIVERSITIES := [
	DIVERSITY_ANY,
	DIVERSITY_ALL,
]


#const SYNTH_TEXT := "text"
#const SYNTH_EMPTY := "empty"
#const SYNTH_ALL := "all"

const SYNTHS := [
#	SYNTH_TEXT,
#	SYNTH_EMPTY,
#	SYNTH_ALL,
]


static func is_verb(concept: String) -> bool:
	return VERBS.has(concept)

static func is_operator(concept: String) -> bool:
	return OPERATORS.has(concept)

static func is_preposition(concept: String) -> bool:
	return PREPOSITIONS.has(concept)

static func is_quality(concept: String) -> bool:
	return QUALITIES.has(concept)

static func is_diversity(concept: String) -> bool:
	return DIVERSITIES.has(concept)

static func is_epithet_prefix(concept: String) -> bool:
	return EPITHET_PREFIXES.has(concept)

static func is_quantity(concept: String) -> bool:
	return concept.is_valid_integer()

static func is_noun(concept: String) -> bool:
	return not (
		is_verb(concept)
		or
		is_operator(concept)
		or
		is_preposition(concept)
		or
		is_quality(concept)
		or
		is_epithet_prefix(concept)
		or
		is_diversity(concept)
		or
		is_quantity(concept)
	)


# Things are "physical" nouns, ie. not "synthetic" nouns.
static func is_thing(concept: String) -> bool:
	return is_noun(concept) && not is_synth(concept)


static func is_synth(concept: String) -> bool:
	return SYNTHS.has(concept)
	

static func to_quantity(concept: String) -> int:
	assert(is_quantity(concept))
	return concept.to_int()

