extends Reference
class_name CheapTrigo


# This is not as efficient as a simple sin()
# See the benchmark
# Well ; it was worth a try !  :]


const DEFAULT_PRECISION := 32
const QUARTER_TURN := 0.25 * TAU


# precision (int) => { angle => value }
const cache_for_sin := Dictionary()


static func cheap_sin(angle, precision := DEFAULT_PRECISION):
	assert(precision > 0, "Nope.  This is the amount of slices.")
	assert(precision >= 4, "values below this are meaningless")
	if precision <= 0:
		precision = DEFAULT_PRECISION
	
	# note: fmod always returns >= 0, which is useful to us
	angle = fmod(angle, TAU)
	angle = stepify(angle, TAU / precision)
	
	if cache_for_sin.has(precision):
		if cache_for_sin[precision].has(angle):
			return cache_for_sin[precision][angle]
	else:
		cache_for_sin[precision] = Dictionary()
	
	var computed_sin = sin(angle)
	cache_for_sin[precision][angle] = computed_sin
	return computed_sin


static func cheap_cos(angle, precision := DEFAULT_PRECISION):
	return cheap_sin(angle + QUARTER_TURN, precision)
