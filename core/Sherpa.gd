extends AnimatedSprite

#   _____ _
#  / ____| |
# | (___ | |__   ___ _ __ _ __   __ _
#  \___ \| '_ \ / _ \ '__| '_ \ / _` |
#  ____) | | | |  __/ |  | |_) | (_| |
# |_____/|_| |_|\___|_|  | .__/ \__,_|
#                        | |
#                        |_|
# 
# Hints where to play next.
# Disappears when the solution is not followed anymore.

# Exports (once we have figured out sane defaults)
export var guide_through_solution := true
export var dampen := 0.001
export var strength := 0.15
export var vivacity := 1.0
export var buzzness := Vector2(20.0, 10.0)
export var maximum_speed := 3.0
export var uturn_intent := 1.38
export var swirly_strength := 0.06
export var swirly_spin := 1.9  # turns per second

# aka "speed" and "mass" in one messy variable
var inertia := Vector2.ZERO

# -1: not following solution anymore
# else: index of the expected move in the solution
var following_solution_step := 0


# Parent Level whose solution we guide along
var level


# May overflow, increases with _process()
var time := 0.0  # seconds
var time_of_last_flip := 0.0  # seconds


# Position in XY where the sherpa should somewhat be.
# This is static, it changes about every turn, we add the bzz orbit on the spot
var target_position: Vector2


func _ready():
	self.level = find_parent_level()
	if self.guide_through_solution:
		# We don't really need all of these, the last one is enough, right?
#		self.level.connect("after_action_moved", self, "on_moved")
#		self.level.connect("after_action_passed", self, "on_passed")
#		self.level.connect("after_action_undoed", self, "on_undoed")
		self.level.connect("after_action_executed", self, "on_actioned")
	update_position()


func _process(delta):
	self.time += delta
	
	# Very basic bee dance, infinite loop
	var moving_target = self.target_position + self.buzzness * Vector2(
		sin(self.time * self.vivacity),
		sin(self.time * self.vivacity * 2.0)
	)
	var intent = (moving_target - self.position).normalized()
	# We want the sherpa to correct its trajectory faster if it's going away from the target
	var dot = self.inertia.dot(intent)
	if dot < 0:
		intent *= self.uturn_intent
	self.inertia += intent * self.strength
	self.inertia = self.inertia + self.swirly_strength * Vector2(
		cos(self.time * self.swirly_spin),
		sin(self.time * self.swirly_spin)
	)
	
	self.inertia = self.inertia.clamped(self.maximum_speed)
	self.inertia = self.inertia * (1.0 - self.dampen)
	
	self.position += self.inertia
	
	if self.time_of_last_flip + 0.618 <= self.time:
		if self.inertia.x < 0:
			if not self.flip_h:
				self.time_of_last_flip = self.time
			self.flip_h = true
		else:
			if self.flip_h:
				self.time_of_last_flip = self.time
			self.flip_h = false


func update_position():
	if self.following_solution_step < 0:
		return
	
	if self.following_solution_step >= self.level.solution_a.length():
		return
	
	var next_action_char = self.level.solution_a[self.following_solution_step]
	
	if self.level.CHARS_DOWN_LEFT.has(next_action_char):
		hint_move(Directions.DOWN_LEFT)
	elif self.level.CHARS_DOWN.has(next_action_char):
		hint_move(Directions.DOWN)
	elif self.level.CHARS_DOWN_RIGHT.has(next_action_char):
		hint_move(Directions.DOWN_RIGHT)
	elif self.level.CHARS_LEFT.has(next_action_char):
		hint_move(Directions.LEFT)
	elif self.level.CHARS_PASS.has(next_action_char):
		hint_pass()
	elif self.level.CHARS_RIGHT.has(next_action_char):
		hint_move(Directions.RIGHT)
	elif self.level.CHARS_UP_LEFT.has(next_action_char):
		hint_move(Directions.UP_LEFT)
	elif self.level.CHARS_UP.has(next_action_char):
		hint_move(Directions.UP)
	elif self.level.CHARS_UP_RIGHT.has(next_action_char):
		hint_move(Directions.UP_RIGHT)
	elif self.level.CHARS_UNDO.has(next_action_char):
		hint_undo()
	else:
		breakpoint  # unrecognized char?   PoM


func find_first_item_that_is_you():
	if not self.level:
		return null
	var yous = self.level.get_items_that_are_you()
	if not yous:
		return null
	return yous[0]


func hint_pass():
	var you = find_first_item_that_is_you()
	if not you:
		return
	set_target_position(self.level.cell_lattice.cell_to_pixel(you.cell_position))


# "Tout ce que tu peux imaginer, ça a déjà été fait."
# > Mais bien sûr…

func hint_undo():
	# move towards the undo button
	
	if not self.level:
		return
	if not self.level.undo_gui_button:
		return
	
	# Nope
#	print_debug(self.level.undo_gui_button.rect_global_position)
#	print_debug(self.level.undo_gui_button.rect_position)
#	print_debug(self.level.undo_gui_button.get_global_transform().get_origin())
#	print_debug(self.get_tree().get_root().get_visible_rect())
	
	# Perhaps this'll work ; perhaps not
	var sz = self.get_tree().get_root().get_visible_rect().size
	set_target_position(
		Vector2(
			sz.x * -0.5,
			sz.y * 0.5
		)
		+
		# half the button
		Vector2(
			64.0 + 8.0,
			-64 - 3.0
		)
	)


func hint_move(direction):
	if not self.level:
		return
	var you = find_first_item_that_is_you()
	if not you:
		return
	var adj = HexagonalLattice.find_adjacent_cell_position(
		you.cell_position,
		self.level.coerce_item_direction(you, direction)
	)
	set_target_position(self.level.cell_lattice.cell_to_pixel(adj))


func set_target_position(xy_position: Vector2):
	self.target_position = xy_position


func appear():
	var you = find_first_item_that_is_you()
	if you:
		self.position = you.position
	self.playing = true	
	self.visible = true


func disappear():
	# Will bug on very large maps: the bee will may not get out of the screen
	set_target_position(self.position.normalized() * 5000.0)
	var _c = get_tree().create_timer(5.0).connect("timeout", self, "do_disappear")


func do_disappear():
	self.visible = false
	self.playing = false	


func is_shown() -> bool:
	return self.visible


func on_actioned(action):
	if self.following_solution_step < 0:
		return
	
	if self.following_solution_step >= self.level.solution_a.length():
		return
	
	if (
		(action is PassAction)
		and
		(self.following_solution_step == 0)
		and
		not is_shown()
	):
		appear()
		update_position()
		return
	
	if action.to_string() == self.level.solution_a[self.following_solution_step]:
		self.following_solution_step += 1
	else:
		#print("Stopped following the sherpa.")
		self.following_solution_step = -1
		disappear()
	
	update_position()


#func on_moved(_direction):
#	pass
#
#
#func on_passed():
#	pass
#
#
#func on_undoed():
#	pass


func find_parent_level():
	var Level = load("res://addons/laec-is-you/entity/Level.gd")
	var p = get_parent()
	while p:
		if p is Level:
			return p
		p = p.get_parent()
	return null
