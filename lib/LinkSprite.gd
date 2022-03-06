extends Sprite
class_name LinkSprite


#  _      _       _     _____            _ _
# | |    (_)     | |   / ____|          (_) |
# | |     _ _ __ | | _| (___  _ __  _ __ _| |_ ___
# | |    | | '_ \| |/ /\___ \| '_ \| '__| | __/ _ \
# | |____| | | | |   < ____) | |_) | |  | | ||  __/
# |______|_|_| |_|_|\_\_____/| .__/|_|  |_|\__\___|
#                            | |
#                            |_|
# Sprite that positions, rotates and scales itself
# in order to be a "link" between two global positions.
# Useful to draw lines between two points.

# FIXME

var left_position := Vector2.LEFT
var right_position := Vector2.RIGHT
var local_left_x := -1.0
var local_right_x := 1.0

var rekt : Rect2

func _init():
	self.centered = true

func _ready():
	rekt = get_rect()

func _process(delta):
	__reposition_between(
		left_position,
		right_position,
		Vector2(rekt.size.x * local_left_x * 0.5, 0),
		Vector2(rekt.size.x * local_right_x * 0.5, 0)
	)

func __reposition_between(
		global_a: Vector2, global_b: Vector2,
		local_a: Vector2, local_b: Vector2,
		scale_y := 1.0,
		is_mirrored := false
	):
	"""
	local_a: In local referential, coordinates of the point A
	local_b: In local referential, coordinates of the point B
	global_a: In global referential, coordinates of point A
	global_b: In global referential, coordinates of point B
	
	This makes sure the local A and B points are positioned respectively
	at the global A and B, by affine transforms on the sprite.
	"""
	assert(local_a.y == 0) # not supported atm, adds complexity
	assert(local_b.y == 0)
	
	# maybe rewrite this cleanly using matrices (transforms)
	
#	var is_mirrored = global_a.x > global_b.x
	
	var gab = (global_b - global_a)
	var lab = (local_b - local_a) # hello, gab from the lab !
	
	# POSITION
	assert(is_centered())  # not supported yet
	var global_m = 0.5 * (global_a + global_b)
	set_global_position(global_m)
	
	# ROTATION
	# rotated(self.get_global_rotation())
	var angle_straight_to_global = Vector2(1,0).angle_to(gab)
	var effect_rotation = angle_straight_to_global
	if is_mirrored:
		effect_rotation += 0.5 * TAU
	set_global_rotation(effect_rotation)
	
	# SCALE
	var scale_x = gab.length() / lab.length()
	set_global_scale(Vector2(scale_x, scale_y))
	
	# STUP&FLIP H
	set_flip_h(is_mirrored)

