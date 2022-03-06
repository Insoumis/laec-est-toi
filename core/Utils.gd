#extends Reference
# We never instantiate this class,
# it's just a bunch of static methods.


static func reposition_sprite_with_flip_between(
		sprite, scale_y, is_mirrored,
		local_a, local_b,
		global_a, global_b
	): # :]
	"""
	
	"""
	assert(local_a.y == 0) # not supported atm, adds complexity
	assert(local_b.y == 0)
	
	# maybe rewrite this cleanly using matrices (transforms)
	
#	var is_mirrored = global_a.x > global_b.x
	
	var gab = (global_b - global_a)
	var lab = (local_b - local_a) # hello, gab from the lab !
	
	# POSITION
	assert(sprite.is_centered())
	var global_m = 0.5 * (global_a + global_b)
	sprite.set_global_position(global_m)
	
	# ROTATION
	# rotated(self.get_global_rotation())
	var angle_straight_to_global = Vector2(1,0).angle_to(gab)
	var rotation = angle_straight_to_global
	if is_mirrored:
		rotation += 0.5 * TAU
	sprite.set_global_rotation(rotation)
	
	# SCALE
	var scale_x = gab.length() / lab.length()
	sprite.set_global_scale(Vector2(scale_x, scale_y))
	
	# STUP&FLIP H
	sprite.set_flip_h(is_mirrored)

