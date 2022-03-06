class_name Directions

# The 6 directions to neighbors in a pointy-topped regular hexagon lattice.

# ## top/bottom vs up/down
# We use top/bottom in the filenames, because we had to choose,
# and up/down _could_ be used for the Z axis.
# We provide aliases for now, as constants.

# Right now these constants are strings, which is not optimal.
# Moving to cell (Vector2) constants is one of the long term goals.
# See STRINGS, and get_direction_string() that is an effort in this direction.
const LEFT = 'left'
const RIGHT = 'right'
const TOP_RIGHT = 'top_right'
const UP_RIGHT = TOP_RIGHT
const TOP_LEFT = 'top_left'
const UP_LEFT = TOP_LEFT
const BOTTOM_RIGHT = 'bottom_right'
const DOWN_RIGHT = BOTTOM_RIGHT
const BOTTOM_LEFT = 'bottom_left'
const DOWN_LEFT = BOTTOM_LEFT
const TOP = 'top'
const UP = TOP
const BOTTOM = 'bottom'
const DOWN = BOTTOM
const NONE = 'none'


const STRINGS = {
	RIGHT: 'right',
	TOP_RIGHT: 'top_right',
	TOP_LEFT: 'top_left',
	LEFT: 'left',
	BOTTOM_LEFT: 'bottom_left',
	BOTTOM_RIGHT: 'bottom_right',
}


const CHARACTERS = {
	RIGHT: '6',
	TOP: '8',
	TOP_RIGHT: '9',
	TOP_LEFT: '7',
	LEFT: '4',
	BOTTOM_LEFT: '1',
	BOTTOM: '2',
	BOTTOM_RIGHT: '3',
}


const AVAILABLE = [
	LEFT,
	RIGHT,
	TOP_RIGHT,
	UP_RIGHT,
	TOP_LEFT,
	UP_LEFT,
	BOTTOM_RIGHT,
	DOWN_RIGHT,
	BOTTOM_LEFT,
	DOWN_LEFT,
	TOP,
	UP,
	BOTTOM,
	DOWN,
]

const USED_DIRECTIONS = [
	LEFT,
	RIGHT,
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_RIGHT,
	BOTTOM_LEFT,
]

const ANGLE_STEP = TAU / 12.0  # Twelvth of a circle

#static func get_direction_from_xy_vector(direction_vector: Vector2) -> String:?
static func get_direction_from_vector(direction_vector: Vector2) -> String:
	var angle = direction_vector.angle()
	
	if (angle > -1 * ANGLE_STEP) and (angle < 1 * ANGLE_STEP):
		return RIGHT
	elif (angle > 1 * ANGLE_STEP) and (angle < 3 * ANGLE_STEP):
		return DOWN_RIGHT
	elif (angle > 3 * ANGLE_STEP) and (angle < 5 * ANGLE_STEP):
		return DOWN_LEFT
	elif (angle > 5 * ANGLE_STEP) or (angle < -5 * ANGLE_STEP):
		return LEFT
	elif (angle > -3 * ANGLE_STEP) and (angle < -1 * ANGLE_STEP):
		return UP_RIGHT
	elif (angle > -5 * ANGLE_STEP) and (angle < -3 * ANGLE_STEP):
		return UP_LEFT
	
	return RIGHT

const JOYSTICK_ANGLE_STEP = TAU / 36.0  # Twelvth of a circle

static func get_joystick_direction_from_vector(direction_vector: Vector2) -> String:
	var angle = direction_vector.angle()
	
	if (angle > -2 * JOYSTICK_ANGLE_STEP) and (angle < 2 * JOYSTICK_ANGLE_STEP):
		return RIGHT
	elif (angle > 2 * JOYSTICK_ANGLE_STEP) and (angle < 9 * JOYSTICK_ANGLE_STEP):
		return DOWN_RIGHT
	elif (angle > 9 * JOYSTICK_ANGLE_STEP) and (angle < 16 * JOYSTICK_ANGLE_STEP):
		return DOWN_LEFT
	elif (angle > 16 * JOYSTICK_ANGLE_STEP) or (angle < -16 * JOYSTICK_ANGLE_STEP):
		return LEFT
	elif (angle > -9 * JOYSTICK_ANGLE_STEP) and (angle < -2 * JOYSTICK_ANGLE_STEP):
		return UP_RIGHT
	elif (angle > -16 * JOYSTICK_ANGLE_STEP) and (angle < -9 * JOYSTICK_ANGLE_STEP):
		return UP_LEFT
	
	return RIGHT


#static func get_direction_xy_vector(direction: String) -> Vector2: ?
static func get_direction_vector(direction: String) -> Vector2:
	if RIGHT == direction:
		return Vector2.RIGHT
	elif DOWN_RIGHT == direction:
		return Vector2(0.5, 0.866)
	elif DOWN == direction:
		return Vector2.DOWN
	elif DOWN_LEFT == direction:
		return Vector2(-0.5, 0.866)
	elif LEFT == direction:
		return Vector2.LEFT
	elif UP_LEFT == direction:
		return Vector2(-0.5, -0.866)
	elif UP == direction:
		return Vector2.UP
	elif UP_RIGHT == direction:
		return Vector2(0.5, -0.866)
	
	assert(false, "Unknown direction `%s'." % direction)
	return Vector2.ZERO


static func get_rotation(direction: String) -> float:
	if RIGHT == direction:
		return 0.0
	elif DOWN_RIGHT == direction:
		return ANGLE_STEP * 2.0
	elif DOWN == direction:
		return ANGLE_STEP * 3.0
	elif DOWN_LEFT == direction:
		return ANGLE_STEP * 4.0
	elif LEFT == direction:
		return ANGLE_STEP * 6.0
	elif UP_LEFT == direction:
		return ANGLE_STEP * 8.0
	elif UP == direction:
		return ANGLE_STEP * 9.0
	elif UP_RIGHT == direction:
		return ANGLE_STEP * 10.0
	
	assert(false, "Unknown direction `%s'." % direction)
	return 0.0


static func inverse(direction: String) -> String:
	if RIGHT == direction:
		return LEFT
	elif DOWN_RIGHT == direction:
		return UP_LEFT
	elif DOWN == direction:
		return UP
	elif DOWN_LEFT == direction:
		return UP_RIGHT
	elif LEFT == direction:
		return RIGHT
	elif UP_LEFT == direction:
		return DOWN_RIGHT
	elif UP == direction:
		return DOWN
	elif UP_RIGHT == direction:
		return DOWN_LEFT
	
	assert(false, "Unknown direction `%s'." % direction)
	return RIGHT


static func coerce_to_left_or_right(direction: String) -> String:
	if RIGHT == direction:
		return RIGHT
	elif DOWN_RIGHT == direction:
		return RIGHT
	elif DOWN == direction:
		return RIGHT
	elif DOWN_LEFT == direction:
		return LEFT
	elif LEFT == direction:
		return LEFT
	elif UP_LEFT == direction:
		return LEFT
	elif UP == direction:
		return LEFT
	elif UP_RIGHT == direction:
		return RIGHT
	
	assert(false, "Unknown direction `%s'." % direction)
	return RIGHT


static func to_cell(direction) -> Vector2:
	if RIGHT == direction:
		return Vector2(1, 0)
	elif DOWN_RIGHT == direction:
		return Vector2(0, 1)
	elif DOWN_LEFT == direction:
		return Vector2(-1, 1)
	elif LEFT == direction:
		return Vector2(-1, 0)
	elif UP_LEFT == direction:
		return Vector2(0, -1)
	elif UP_RIGHT == direction:
		return Vector2(1, -1)

	breakpoint
	return Vector2(1, 0)


static func from_cell(direction: Vector2):
	if Vector2(1, 0) == direction:
		return RIGHT
	elif Vector2(0, 1) == direction:
		return DOWN_RIGHT
	elif Vector2(-1, 1) == direction:
		return DOWN_LEFT
	elif Vector2(-1, 0) == direction:
		return LEFT
	elif Vector2(0, -1) == direction:
		return UP_LEFT
	elif Vector2(1, -1) == direction:
		return UP_RIGHT
	
	breakpoint
	return RIGHT


static func build_directions_index() -> Dictionary:
	return {
		RIGHT: Array(),
		LEFT: Array(),
		UP_LEFT: Array(),
		UP_RIGHT: Array(),
		DOWN_LEFT: Array(),
		DOWN_RIGHT: Array(),
	}


# start using this so we can move to Vector2 constants
static func as_string(direction) -> String:
	return get_direction_string(direction)


static func get_direction_string(direction) -> String:
	if not STRINGS.has(direction):
		breakpoint
		return STRINGS[RIGHT]
	return STRINGS[direction]


static func from_string(direction_string):
	# Update me once we've moved away from string directions
	return direction_string
