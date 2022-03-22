tool
extends Node2D
#class_name Item  # tempting, but no  (windows!)

#  _____ _
# |_   _| |
#   | | | |_ ___ _ __ ___
#   | | | __/ _ \ '_ ` _ \
#  _| |_| ||  __/ | | | | |
# |_____|\__\___|_| |_| |_|
#
#
# Items are the main entities in the game.
# 
# It handles:
# - its flags, that the level will set when spending a turn.
# - its appearance, from its flags
# 
# 
# Make sure there are images:
# - `<thing>_0.png`
# - `<thing>_1.png`
# - `<thing>_2.png`
# - `text_<thing>_0.png`
# - `text_<thing>_1.png`
# - `text_<thing>_2.png`
# in the directory `sprites/items`.
# See there for a more complete description of what is supported.
# 

# This is relevant only for things.
# Always set this to true for operators, qualities, prepositions and verbs.
export(bool) var is_text := false

# Describe the concept of this item.
# Only one of these may be set.
# If somehow multiple are provided, behavior is undefined.
# Right now pretty much any keyword can be used
# as long as there are icons for it.
# - sprites/items/<name>.png
# - sprites/items/text_<name>.png
# 
# Constraints:
# 1. Please only use a single word, lowercase, no diacritics.
# 2. Numbers are allowed (bogoss69), but raw numbers (42) are reserved.
# 3. MUST match `^[a-z0-9]*[a-z][a-z0-9]*$`, in other words.
# 4. MUST NOT contain the word "color", "left", "right", "top", or "bottom".
export(String) var concept_name := ''

# Emitted when one of the above properties change, (todo?)
#signal concept_changed

var concept_full: String setget set_concept_full, get_concept_full

func set_concept_full(value):
	assert(not "Implemented")  # we could write to concept_name and is_text
func get_concept_full() -> String:
	return ("text_" if self.is_text else "") + get_concept_name()

# Read-only concept flags.
# In this class, use the fully qualified self.is_xxx
# instead of the shortcut is_xxx, to trigger setgets.
var is_thing setget set_is_thing, get_is_thing
var is_operator setget set_is_operator, get_is_operator
var is_quality setget set_is_quality, get_is_quality

# Items that are being destroyed are still in the scene tree a while,
# but should not be registered onto the lattice anymore.  This helps.
var latticeability := true


#  _____                                   ______                       _
# |  __ \                                 |  ____|                     | |
# | |__) | __ __ _  __ _ _ __ ___   __ _  | |__  __  ___ __   ___  _ __| |_ ___
# |  ___/ '__/ _` |/ _` | '_ ` _ \ / _` | |  __| \ \/ / '_ \ / _ \| '__| __/ __|
# | |   | | | (_| | (_| | | | | | | (_| | | |____ >  <| |_) | (_) | |  | |_\__ \
# |_|   |_|  \__,_|\__, |_| |_| |_|\__,_| |______/_/\_\ .__/ \___/|_|   \__|___/
#                   __/ |                             | |
#                  |___/                              |_|
# 
# Below are exports for the ItemWizard.
# The level makers ought not change these values themselves.
# 

# Hold the real cell position (axial coords system)
export(Vector2) var cell_position := Vector2.ZERO setget set_cell_position, get_cell_position

# Tile position in the awkward offset-mode coordinates system, as used by the TileMap.
export(Vector2) var tile_position := Vector2.ZERO setget set_tile_position, get_tile_position

# The direction this Item is facing.
# The direction is changed when Items move or are moved.
export(String) var direction := Directions.RIGHT

# Internal counter for animation poses
# Why is this an export?  Was it a sort of pickling attempt?  Do we care about this?
export(int) var animation_state := 0


# State | Qualities flags.
# 
# Best not write to those values yourself, because
# they will be reset by the sentences on each turn.
# These are export()s for the Item Wizard, not for the Game Master.
# This way the Item Wizard can write into these values as well.
# 
# We are using hardcoded and not "dynamic" qualities,
# which would be more convenient when adding new qualities,
# but slower at runtime, unless we start generating gdscript.
# 
# Also, if each Quality could have its own class file…
# We'd have even more flexible levels, and we'd flatten the effort to add new.
# If you fee like experimenting with a refacto of these, go for it !
# 
# Do ping me, 'cause I'm thinking about it too, a year later.
# Probably for v2 though, after the early 2022 release in v1.
# 
# Also, using properties like this is a bad design.  Reflection -_-
export(bool) var is_you := false
export(bool) var is_win := false
export(bool) var is_defeat := false
export(bool) var is_stop := false
export(bool) var is_sink := false
export(bool) var is_void := false
export(bool) var is_push := false
export(bool) var is_pull := false
export(bool) var is_open := false
export(bool) var is_shut := false
export(bool) var is_weak := false
export(bool) var is_hot := false
export(bool) var is_melt := false
export(bool) var is_move := false
export(bool) var is_poet := false
export(bool) var is_genie := false
export(bool) var is_yoda := false
export(bool) var is_more := false
export(bool) var is_boom := false

export(bool) var is_lit := true setget set_lit
export(bool) var is_ignored := false setget set_ignored

# When this Item is destroyed, it will release its stuffing (HAS verb)
var stuffing := Array()  # of things' concept names (String)


onready var ignored_animation := $IgnoredAnimatedSprite


#   _______     __                                   _ _          _   _
#  / /  __ \    \ \                                 | (_)        | | (_)
# | || |  | | ___| |_ __   ___  _ __ _ __ ___   __ _| |_ ______ _| |_ _  ___  _ __
# | || |  | |/ _ \ | '_ \ / _ \| '__| '_ ` _ \ / _` | | |_  / _` | __| |/ _ \| '_ \
# | || |__| |  __/ | | | | (_) | |  | | | | | | (_| | | |/ / (_| | |_| | (_) | | | |
# | ||_____/ \___| |_| |_|\___/|_|  |_| |_| |_|\__,_|_|_/___\__,_|\__|_|\___/|_| |_|
#  \_\          /_/
#

func reset_properties():
	reset_qualities()
	reset_gui_overlay()
	reset_stuffing()


func reset_qualities():
	self.is_you = false
	self.is_win = false
	self.is_stop = false
	self.is_push = false
	self.is_pull = false
	self.is_defeat = false
	self.is_sink = false
	self.is_void = false
	self.is_open = false
	self.is_shut = false
	self.is_weak = false
	self.is_hot = false
	self.is_melt = false
	self.is_move = false
	self.is_poet = false
	self.is_genie = false
	self.is_yoda = false
	self.is_more = false
	self.is_boom = false


func reset_gui_overlay():
	if self.is_text:
		self.is_lit = false
	else:
		self.is_lit = true
	self.is_ignored = false


func reset_stuffing():
	self.stuffing.clear()


func to_pickle():
	return {
		'is_you': self.is_you,
		'is_win': self.is_win,
		'is_stop': self.is_stop,
		'is_push': self.is_push,
		'is_pull': self.is_pull,
		'is_defeat': self.is_defeat,
		'is_sink': self.is_sink,
		'is_void': self.is_void,
		'is_open': self.is_open,
		'is_shut': self.is_shut,
		'is_weak': self.is_weak,
		'is_hot': self.is_hot,
		'is_melt': self.is_melt,
		'is_move': self.is_move,
		'is_poet': self.is_poet,
		'is_genie': self.is_genie,
		'is_yoda': self.is_yoda,
		'is_more': self.is_more,
		'is_boom': self.is_boom,
		
		'is_lit': self.is_lit,
		'is_text': self.is_text,
		
		'stuffing': self.stuffing,
		
		'concept_name': self.concept_name,
		
#		'position': self.position,
		'cell_position': self.cell_position,
		'tile_position': self.tile_position,
		
		'direction': self.direction,
		'animation_state': self.animation_state,
	}


func from_pickle(rick):
	for property in rick.keys():
		#prints("[%s] set"%name, property, rick[property])
		self.set(property, rick[property])


func copy_from_item(item):
	from_pickle(item.to_pickle())
	self.position = item.position


#   _____      _
#  / ____|    | |
# | (___   ___| |_ _   _ _ __
#  \___ \ / _ \ __| | | | '_ \
#  ____) |  __/ |_| |_| | |_) |
# |_____/ \___|\__|\__,_| .__/
#                       | |
#                       |_|

func _ready():
	ready()


func ready():
	if Engine.editor_hint:
		snap_to_grid()
	reposition()
	get_sprite().frame = randi() % 3
	update_sprite()
	update_particles()
	# Do NOT rename the node here, or the Editor will not select
	# the appropriate node after duplication in the scene tree.
	#rename()


func _enter_tree():
	enter_tree()


func enter_tree():
	pass  # override me


func _exit_tree():
	exit_tree()


func exit_tree():
	pass  # override me


#   _____
#  / ____|                         /\
# | (___   ___ ___ _ __   ___     /  \__      ____ _ _ __ ___ _ __   ___  ___ ___
#  \___ \ / __/ _ \ '_ \ / _ \   / /\ \ \ /\ / / _` | '__/ _ \ '_ \ / _ \/ __/ __|
#  ____) | (_|  __/ | | |  __/  / ____ \ V  V / (_| | | |  __/ | | |  __/\__ \__ \
# |_____/ \___\___|_| |_|\___| /_/    \_\_/\_/ \__,_|_|  \___|_| |_|\___||___/___/
#
#
# Since Items instances ought not move between Levels,
# and will always have the same Level all along their lifecycle,
# we decided to inject the level in the Item, for convenience.
# 
# We could inject it upon instantiation in Game.spawn_item(),
# but we also have Items from the Level scene that need injection,
# and their _ready code runs before the level, since they're children of it.
# Lots of lifecycle refacto (although I'd like it).
# Se we fetch it from the scene and memoize it, as a fallback.

var level setget set_level, get_level


func set_level(new_level):
	assert(new_level)
	level = new_level   # not self.level, setget


func get_level():
	if level:  # not self.level (setget!)
		return level
	
	var LevelType = load("res://addons/laec-is-you/entity/Level.gd")  # ~cyclic
	
	var found := false
	var parent := get_parent()
	while parent:
		if parent is LevelType:
			level = parent
		parent = parent.get_parent()

	# Live Editor does not have a level (for now)
#	assert(level, "Level was not found in the scene.")
#	assert(is_instance_valid(level), "Level is invalid.")
	
	return level


func get_scene_viewport():
	var parent = self
	while parent and not (parent is Viewport):
		parent = parent.get_parent()
	assert(parent is Viewport, "Scene viewport was not found.")
	return parent


func get_cells_map():
#	var cell_map = get_scene_viewport().find_node('HexagonalTileMap', true, false)
	var cell_map = get_level().find_node('HexagonalTileMap', true, false)
	return cell_map


#          _   _        _ _           _
#     /\  | | | |      (_) |         | |
#    /  \ | |_| |_ _ __ _| |__  _   _| |_ ___  ___
#   / /\ \| __| __| '__| | '_ \| | | | __/ _ \/ __|
#  / ____ \ |_| |_| |  | | |_) | |_| | ||  __/\__ \
# /_/    \_\__|\__|_|  |_|_.__/ \__,_|\__\___||___/
#
# 

func show_read_only_notice(concept_name, concept_example, value):
	printerr(
		"Don't set is_%s to %s. Consider it read-only.\n" % [
			concept_name, value
		] +
		"Instead, set %s_name to a String, like '%s'." % [
			concept_name, concept_example
		]
	)

func set_is_thing(value):
	show_read_only_notice('thing', 'baba', value)

func get_is_thing():
	if not self.concept_name:
		return false
	return Words.is_noun(self.concept_name)
# probably wrong, careful
#	return not (
#		Words.OPERATORS.has(self.concept_name)
#		or
#		Words.QUALITIES.has(self.concept_name)
#	)

func set_is_operator(value):
	show_read_only_notice('operator', 'is', value)

func get_is_operator():
	return Words.OPERATORS.has(concept_name)

func set_is_quality(value):
	show_read_only_notice('quality', 'you', value)

func get_is_quality():
	return Words.QUALITIES.has(concept_name)

func set_lit(lit):
	is_lit = lit
	update_salience(lit)

func set_ignored(ignored):
	is_ignored = ignored
	if self.ignored_animation:
		self.ignored_animation.visible = is_ignored

func is_text_thing() -> bool:
	return (
		self.is_text
		and
		self.is_thing
	)

func is_text_noun() -> bool:
	if not self.is_text:
		return false
	if self.is_thing:
		return true
#	if self.is_synthetic_thing:  # EMPTY?
#		return true
	return false

func is_real_thing(concept:='', any_but:=false) -> bool:
	if self.is_text:
		return false
	if not self.is_thing:
		return false
	if '' == concept:
		return not any_but
	if any_but:
		return not is_concept(concept)
	return is_concept(concept)

func is_text_concept(concept: String) -> bool:
	return (
		self.is_text
		and 
		is_concept(concept)
	)

func is_real_concept(concept: String) -> bool:
	return (
		(not self.is_text)
		and 
		is_concept(concept)
	)

func is_concept(concept: String) -> bool:
	return get_concept_name() == concept

func is_operator_and() -> bool:
	return is_text_concept(Words.OPERATOR_AND)

func is_operator_not() -> bool:
	return is_text_concept(Words.OPERATOR_NOT)

func is_preposition_on() -> bool:
	return is_text_concept(Words.PREPOSITION_ON)

func is_quantity() -> bool:
	return Words.is_quantity(get_concept_name())

func to_quantity() -> int:
	return Words.to_quantity(get_concept_name())

func has_quality(quality: String) -> bool:
	"""
	We are trying to deprecate usage of Item.is_xxxx in favor of this.
	quality: one of Words.QUALITY_XXXX
	"""
	# Once we've removed all usages of is_xxxx properties,
	# we can use another (faster) way than reflection in here.
	assert(Words.QUALITIES.has(quality))
	var s = "is_%s" % quality
	assert(s in self, "The quality `%s` is undefined in Item." % [quality])
	return get(s)


#  _   _
# | \ | |
# |  \| | __ _ _ __ ___   ___
# | . ` |/ _` | '_ ` _ \ / _ \
# | |\  | (_| | | | | | |  __/
# |_| \_|\__,_|_| |_| |_|\___|
#
#

func rename() -> void:
	self.name = (
		get_concept_name().capitalize()
		+
		('Text' if self.is_text else '')
	)

func get_concept_name() -> String:
	if self.concept_name:
		return self.concept_name
	return 'undefined'  # here be trolls


#           _      _
#     /\   | |    | |
#    /  \  | | ___| |__   ___ _ __ ___  _   _
#   / /\ \ | |/ __| '_ \ / _ \ '_ ` _ \| | | |
#  / ____ \| | (__| | | |  __/ | | | | | |_| |
# /_/    \_\_|\___|_| |_|\___|_| |_| |_|\__, |
#                                        __/ |
#                                       |___/
# 
# Perhaps a wiser transmutation would be to destroy the 
# 
func qualify(quality_name):
	var n = "is_%s" % quality_name
	assert(n in self, "The quality `%s` is undefined in Item." % [quality_name])
	if n in self:
		set(n, true)

func transmute(thing_name):
	self.concept_name = thing_name
	update_sprite()
	rename()

func stuff_with(thing_name):
	self.stuffing.append(thing_name)


#
#     /\
#    /  \   _ __  _ __   ___  __ _ _ __ __ _ _ __   ___ ___
#   / /\ \ | '_ \| '_ \ / _ \/ _` | '__/ _` | '_ \ / __/ _ \
#  / ____ \| |_) | |_) |  __/ (_| | | | (_| | | | | (_|  __/
# /_/    \_\ .__/| .__/ \___|\__,_|_|  \__,_|_| |_|\___\___|
#          | |   | |
#          |_|   |_|


onready var sprite : AnimatedSprite = $AnimatedSprite


func get_sprite() -> AnimatedSprite:
	return sprite


func update_aesthetics() -> void:
	update_sprite()
	update_salience()
	update_particles()


func update_sprite(refresh_frames := true) -> void:
	var concept = get_concept_name()
	var sprite = get_sprite()
	var current_shiver_frame = sprite.get_frame()
	var flip_h = false
	if refresh_frames:
#		var sf = SpriteFramesFactory.get_for_concept(concept, self.is_text)
		var sf = AtlasSpriteFramesFactory.get_for_concept(concept, self.is_text)
		sprite.set_sprite_frames(sf)
	var animation_name_raw = get_sprite_frame_animation_name()
	var animation_name = animation_name_raw
	if (animation_name.find("right") >= 0) and (direction.find("left") >= 0):
		flip_h = true
	if (animation_name.find("left") >= 0) and (direction.find("right") >= 0):
		flip_h = true
	if not sprite.get_sprite_frames().has_animation(animation_name):
		animation_name = "%s_%d" % [animation_name_raw, animation_state]
	if not sprite.get_sprite_frames().has_animation(animation_name):
		animation_name = "%s_0" % [animation_name_raw]
	if not sprite.get_sprite_frames().has_animation(animation_name):
		printerr("No animation `%s' found for item `%s'" % [animation_name, concept])
	sprite.play(animation_name)
	sprite.set_frame(current_shiver_frame)  # what if it's too big?
	sprite.flip_h = flip_h
	
	if not self.level:
		return
	if not self.level.is_ready:
		yield(self.level, "ready")  # level is parent in tree, not ready yet
	var color = self.level.get_color_for_concept(concept, self.is_text)
	sprite.modulate = color


func update_particles() -> void:
	$WinParticles.emitting = self.is_win


func update_salience(is_increase=null) -> void:
	if null == is_increase:
		is_increase = is_lit
	if is_increase:
		self.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		var darker = 0.9
		self.modulate = Color(darker, darker, darker, 0.7)


func raise_dust() -> void:
#	yield(get_tree().create_timer(0.08), "timeout")
	get_tree().create_timer(0.08).connect(
		"timeout", self, "__raise_dust"
	)


func __raise_dust() -> void:
	# We use many emitters because emission happens faster
	# than the emitters' lifecycle, and it's faster to do this
	# than to make our own particle emitter.
	# Refactor at will (especially for water movement customization!)
	# A good idea would be to extend the CpuParticlesEmitter.
	var emittor = $MoveParticles1
	if emittor.emitting:
		emittor = $MoveParticles2
	if emittor.emitting:
		emittor = $MoveParticles3
	if emittor.emitting:
		emittor = $MoveParticles4
	if emittor.emitting:
		emittor = $MoveParticles5
	if emittor.emitting:
		emittor = $MoveParticles6
	emittor.direction = -1 * Directions.get_direction_vector(self.direction)
	emittor.emitting = true
	emittor.restart()


func animate_destruction() -> void:
	$DestructionParticles.restart()


func get_animation_name(flip_h = false) -> String:
	# probably deprecated
	var dir: String = self.direction
	if flip_h:
		if dir.find("left") >= 0:
			dir = dir.replace("left", "right")
		elif dir.find("right") >= 0:
			dir = dir.replace("right", "left")
	return "%s_%d" % [
		dir, self.animation_state
	]


func get_sprite_frame_animation_name() -> String:
	var pool_item = ItemsPool.get_item_by_concept_full(self.concept_full)
	var animation_name = pool_item.get_animation_prefix_for(direction)
	return animation_name


func advance_animation(and_update := false) -> void:
	var old_animation_state = self.animation_state
	self.animation_state = (self.animation_state + 1)
	if not get_sprite().get_sprite_frames().has_animation(
			get_sprite_frame_animation_name() + "_" + str(self.animation_state)
		):
		self.animation_state = 0
	if self.animation_state != old_animation_state and and_update:
		update_sprite()
		


func animate_spawn(apparition_delay:=0.0) -> void:
	self.visible = false
	# yielding is a crutch, here, replace it if you can
	yield(get_tree().create_timer(apparition_delay), "timeout")
	self.visible = true


#   _____
#  / ____|
# | (___  _ __   __ _  ___ ___
#  \___ \| '_ \ / _` |/ __/ _ \
#  ____) | |_) | (_| | (_|  __/
# |_____/| .__/ \__,_|\___\___|
#        | |
#        |_|


func is_on_lattice() -> bool:
	return self.latticeability

func is_latticeable() -> bool:
	return self.latticeability

func set_latticeability(latticeability: bool):
	self.latticeability = latticeability

func set_cell_position(new_cell_position: Vector2) -> void:
	tile_position = HexagonalLattice.tile_from_cell(new_cell_position)

func get_cell_position() -> Vector2:
	return HexagonalLattice.cell_from_tile(tile_position)

func set_tile_position(new_tile_position: Vector2) -> void:
	tile_position = new_tile_position

func get_tile_position() -> Vector2:
	return tile_position

# This crutch allowed us to use Ysort.
# Z-indices don't work well with inherited scenes in Dialogs.
# Oddly enough, this stopped working along the way,
# and this method is not triggered anymore.  Not sure why.
# See reposition_on_tile()
#func set_position(new_position: Vector2):
#	print("Setting position of item %s" % [name])
#	return .set_position(
#		new_position
#		+
#		Vector2(0, 0.001 * get_z_salience())
#	)


# Guess and set the cell/tile position from the XY cartesian world Node2D position.
# possibly a bad name ; perhaps infer_position_from_xy ?
func infer_position(teleport := false) -> void:
	snap_to_grid()
	reposition(teleport)


func reposition(teleport := false) -> void:
	var tile_map = get_cells_map()
	if not tile_map:
		printerr("No TileMap found, skipping reposition()…")
		return
	reposition_on_tile(self.tile_position, teleport)


func reposition_on_tile(tile: Vector2, teleport := false) -> void:
	var tile_map = get_cells_map()
	if not tile_map:
		printerr("No TileMap found, skipping reposition_on_tile()…")
		return
	var target_position = tile_map.map_to_world(tile)
	target_position.y += 0.001 * get_z_salience()  # z-index crutch
	if teleport:
		stop_tween_position()
		self.position = target_position
	else:
		tween_position(target_position)


func pretend_to_move(direction):
	var cell_map = get_cells_map()
	if not cell_map:
		printerr("No Cell Map found, skipping pretend_to_move()…")
		return
	var target_cell = HexagonalLattice.find_adjacent_tile_position(
		self.tile_position,
		direction
	)
	var target_position = cell_map.map_to_world(
		target_cell
	)
	target_position = self.position + (target_position - self.position) * 0.5
	tween_position(target_position)

func stop_tween_position():
	$Tween.stop(self, 'position')

func tween_position_change(target_position):
	# deprecated
	return tween_position(target_position)

func tween_position(target_position):
	$Tween.interpolate_property(
		self,  # object
		'position',  # property
		self.position,  # initial
		target_position,  # target
		0.155,  # duration (should almost be `action cooldown`)
		Tween.TRANS_LINEAR,  # transition
		Tween.EASE_IN_OUT,  # easing
		0  # delay
	)
	$Tween.start()


func snap_to_grid():
	var level = get_level()
	if not level:
		printerr("No Level found, skipping snap_to_grid()…")
		return
		
	var lattice: HexagonalLattice = level.get_items_lattice()
	if not lattice:
		printerr("No Lattice found, skipping snap_to_grid()…")
		return
	
	var cell = lattice.pixel_to_cell(self.position)
	self.cell_position = cell
	reposition()


func is_looking_left() -> bool:
	# Since We're using pointy-topped hexagons,
	# an item is either looking left or right.
	return not is_looking_right()


func is_looking_right() -> bool:
	return (
		self.direction == Directions.RIGHT
		or
		self.direction == Directions.TOP_RIGHT
		or
		self.direction == Directions.BOTTOM_RIGHT
	)


func reverse_direction():
	self.direction = Directions.inverse(self.direction)
#	if self.direction == Directions.RIGHT:
#		self.direction = Directions.LEFT
#	elif self.direction == Directions.UP_RIGHT:
#		self.direction = Directions.DOWN_LEFT
#	elif self.direction == Directions.UP_LEFT:
#		self.direction = Directions.DOWN_RIGHT
#	elif self.direction == Directions.LEFT:
#		self.direction = Directions.RIGHT
#	elif self.direction == Directions.DOWN_LEFT:
#		self.direction = Directions.UP_RIGHT
#	elif self.direction == Directions.DOWN_RIGHT:
#		self.direction = Directions.UP_LEFT


const SALIENCE_NONE := 0.0
const SALIENCE_SOME := 0.1
const SALIENCE_LOTS := 1.0
const SALIENCE_HUGE := 10.0


var saliences_of_qualities := {
	Words.QUALITY_YOU: SALIENCE_HUGE,
}

func get_z_salience() -> float:
	var z_salience := 0.0
	
	for quality in Words.QUALITIES:
		if get("is_%s" % quality):  # noooo
			z_salience += saliences_of_qualities.get(quality, SALIENCE_SOME)
	return z_salience


func is_on_screen() -> bool:
	return $VisibilityNotifier2D.is_on_screen()

