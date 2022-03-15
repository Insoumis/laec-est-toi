tool
extends "res://addons/laec-is-you/entity/Item.gd"

const Spirograph = preload("res://spiros/Spirograph.gd")



# 
# Portals help navigate between levels.
# They are, in essence, Items with some special behavior.
# 
# Since at runtime we do not want to instantiate the whole target level
# just to get its title and other custom info,
# we duplicate some of that information in the portals. in editor mode.
# It's not the best design, and we welcome tips
# on how to handle a decentralized database of levels and items like we have.
# Hopefully, we'll probably be able to automate that duplication.
# 


# Emitted when the portal completes
signal portal_completed()


#   _____             __ _                       _   _
#  / ____|           / _(_)                     | | (_)
# | |     ___  _ __ | |_ _  __ _ _   _ _ __ __ _| |_ _  ___  _ __
# | |    / _ \| '_ \|  _| |/ _` | | | | '__/ _` | __| |/ _ \| '_ \
# | |___| (_) | | | | | | | (_| | |_| | | | (_| | |_| | (_) | | | |
#  \_____\___/|_| |_|_| |_|\__, |\__,_|_|  \__,_|\__|_|\___/|_| |_|
#                           __/ |
#                          |___/
# 

# Secret portals do not show up, but can be activated
export var secret := false

# Warps don't have a completion status ; they show an animated epicycloïd
export var warp := false

# Target level this portal leads to
export(String, FILE, "*.tscn") var level_path : String

# Set to true to constrain availability to after a datetime found in the target level path
# Eg with the level `Lotd20220321.tscn`.
# The date is inclusive, that is the portal will be shown on the day it specifies, and afterwards.
export var daily := false

# Another portal that must have been completed fo this portal to appear
# There are no safeguards if you put odd things in here, like warps or items.
# Expect things to blow if not handled with care.
export(NodePath) var dependency_a : NodePath


# Perhaps restore this later,
# at least provide _some_ way of customizing the portals,
# so that we can hide invisible portals in the levels.
#export(Texture) var texture
#export(Texture) var texture_when_completed


# __          ___                  _
# \ \        / (_)                | |
#  \ \  /\  / / _ ______ _ _ __ __| |
#   \ \/  \/ / | |_  / _` | '__/ _` |
#    \  /\  /  | |/ / (_| | | | (_| |
#     \/  \/   |_/___\__,_|_|  \__,_|
#
#
# These properties are exported for the Item Wizard,
# to let the Engine set the value for us in the level editor.

# We can dynamically fetch this data from the level's title.
# We also store this data here to avoid instantiating each level
# when on the map in order to get their title and other data.
# These properties are not meant to be written by the level maker.
export(String) var title := ''
export(String) var title_override := ''

# ざわ…  (not a good way to handle I18N)
var title_displayed : String setget ,get_title_displayed

func get_title_displayed() -> String:
	if self.title_override != '':
		return self.title_override
	if self.title != '':
		return tr(self.title)  # we tr() it but do not need to
	return ''
# …ざわ


#  _____      _            _
# |  __ \    (_)          | |
# | |__) | __ ___   ____ _| |_ ___
# |  ___/ '__| \ \ / / _` | __/ _ \
# | |   | |  | |\ V / (_| | ||  __/
# |_|   |_|  |_| \_/ \__,_|\__\___|
#
#

var __was_initialized := false
var __was_completed_last_i_checked : bool
var __was_available_last_i_checked : bool


#  _      _  __                     _
# | |    (_)/ _|                   | |
# | |     _| |_ ___  ___ _   _  ___| | ___
# | |    | |  _/ _ \/ __| | | |/ __| |/ _ \
# | |____| | ||  __/ (__| |_| | (__| |  __/
# |______|_|_| \___|\___|\__, |\___|_|\___|
#                         __/ |
#                        |___/

func ready():
	.ready()
	#print('Portal running ready()')
	if Engine.is_editor_hint():
		copy_properties_from_level()
		return

	var is_completed_now = is_completed()
	var is_available_now = is_available()
	
	if not __was_initialized: 
		__was_initialized = true
		__was_completed_last_i_checked = is_completed_now
		__was_available_last_i_checked = is_available_now
		if __was_available_last_i_checked:
			show_as_available()
		else:
			show_as_unavailable()


# This will be called every time we get back to the map
func enter_tree() -> void:
	.enter_tree()
	#print('Portal running enter_tree()')
	
	if Engine.is_editor_hint():
		return
	
	if not __was_initialized:
		return
	
	var is_completed_now = is_completed()
	var is_available_now = is_available()
	
#	if not __was_initialized: 
#		__was_initialized = true
#		__was_completed_last_i_checked = is_completed_now
#		__was_available_last_i_checked = is_available_now
#		if __was_available_last_i_checked:
#			show_as_available()
#		else:
#			show_as_unavailable()
	
	yield(get_tree().create_timer(
		Game.transitions_duration * 0.9
	), "timeout")
	
	if __was_completed_last_i_checked != is_completed_now:
		__was_completed_last_i_checked = is_completed_now
		emit_signal('portal_completed')
		animate_portal_completion()
	
	if __was_available_last_i_checked != is_available_now:
		__was_available_last_i_checked = is_available_now
		if is_available_now:
			show_as_available()
			#animate_portal_apparition()
		else:
			printerr("Portal `%s' stopped being available.  WTF?" % [self.name])
			breakpoint  # do tell me how you ended up here, please  <-- UNDO!
			show_as_unavailable()


func _input(event) -> void:
	if (
		(event is InputEventKey or event is InputEventJoypadButton)
		and event.pressed
		and (
			Input.is_action_just_pressed("ui_accept")
			or
			Input.is_action_just_pressed("pass")
			or
			Input.is_action_just_pressed("enter")
		)
	):
		perhaps_open()


func _get_configuration_warning() -> String:
	if not self.level_path:
		return tr("You must define a target level for this Portal.")
	if not ResourceLoader.exists(self.level_path):
		return tr("The target level of this Portal does not exist.")
	return ''


func rename() -> void:
	pass  # leave the portals' names alone for now


var warp_rotation_speed := 0.06


func _process(_delta):
	if self.warp:
		$AnimatedSprite.rotate(_delta * TAU * -1 * self.warp_rotation_speed)


#  _                    _
# | |                  | |
# | |     _____   _____| |
# | |    / _ \ \ / / _ \ |
# | |___|  __/\ V /  __/ |
# |______\___| \_/ \___|_|
#
#

func copy_properties_from_level() -> void:
	if not self.level_path:
		return
	
	var level_scene = load(self.level_path)
	if not level_scene:
		return
	
	var level = level_scene.instance()
	if not level:
		return
	
	self.title = level.get_title_displayed()
	
	level.queue_free()


#                    _ _       _     _ _ _ _
#     /\            (_) |     | |   (_) (_) |
#    /  \__   ____ _ _| | __ _| |__  _| |_| |_ _   _
#   / /\ \ \ / / _` | | |/ _` | '_ \| | | | __| | | |
#  / ____ \ V / (_| | | | (_| | |_) | | | | |_| |_| |
# /_/    \_\_/ \__,_|_|_|\__,_|_.__/|_|_|_|\__|\__, |
#                                               __/ |
#                                              |___/
# 

const MAX_RECURSION_DEPTH := 16


func is_available(loop_index := 0) -> bool:
	
	if not self.level_path:
		# Skip portal without target level, useful for LotD
		return false
	
	if MAX_RECURSION_DEPTH < loop_index:
		printerr(
			"Portal.is_available() reached maximum depth. " +
			"You probably have cyclic dependencies set up. " +
			"Thank you for using the level editor; love you !"
		)
		return false
	
	if is_completed():
		return true
	
	var available := true
	
	# fixme: use a for loop and some reflection, we can afford it here
	if self.dependency_a:
		var dep = get_node_or_null(self.dependency_a)
		if not dep:
			printerr(
				(
					"Availability dependency `%s` of portal `%s' was not found.  " +
					"Make sure the Portal nodes in your Level are in the correct order " +
					"(dependencies first/above)."
				) % [ self.dependency_a, name ]
			)
		else:
			if (
#				(not dep.is_available(loop_index + 1))
#				or
				(not dep.is_completed())
			):
				available = false
	
	if self.daily and available:
		var date = DateUtils.extract_date(self.level_path)
		available = DateUtils.date_a_before_b(date, OS.get_date())
	
	return available


func show_as_available() -> void:
	self.visible = true


func show_as_unavailable() -> void:
	self.visible = false


func is_secret() -> bool:
	return self.secret


#   _____                      _      _   _
#  / ____|                    | |    | | (_)
# | |     ___  _ __ ___  _ __ | | ___| |_ _  ___  _ __
# | |    / _ \| '_ ` _ \| '_ \| |/ _ \ __| |/ _ \| '_ \
# | |___| (_) | | | | | | |_) | |  __/ |_| | (_) | | | |
#  \_____\___/|_| |_| |_| .__/|_|\___|\__|_|\___/|_| |_|
#                       | |
#                       |_|
#

func animate_portal_completion() -> void:
	$CompletionParticles.restart()
	$CompletionParticles2.restart()
	update_sprite()


func is_completed() -> bool:
	assert(Game)
	return Game and Game.is_level_complete(level_path)


func update_sprite(refresh_frames := true) -> void:
	var concept := 'portal'
	if Engine.is_editor_hint():
		concept = 'portal'
	elif is_completed():
		concept = 'portal_completed'
	var sf: SpriteFrames
	if self.warp:
		concept = 'warp'
		$AnimatedSprite.offset = Vector2.ZERO
		sf = SpriteFramesFactory.get_for_concept(concept, false, 'portals', 5)
	else:
		sf = SpriteFramesFactory.get_for_concept(concept, false, 'portals')
	$AnimatedSprite.frames = sf
	$AnimatedSprite.animation = get_animation_name()
	$AnimatedSprite.visible = (
		not is_secret()
		or
		is_completed()
		or
		Engine.is_editor_hint()
	)
	# Use a pretty but _expensive_ spirograph, only in desktop linux/windows/mac builds
	if (
		false  # dev toggle to disable the spirograph for now
		and
		self.warp
		and
		not Engine.is_editor_hint()
		and
		not OS.has_feature("HTML5")
		and
		not OS.has_feature("Android")
	):
		$AnimatedSprite.visible = false
		$WarpSpiro.visible = true


#                           _
#     /\                   | |
#    /  \   _ __   ___ _ __| |_ _   _ _ __ ___
#   / /\ \ | '_ \ / _ \ '__| __| | | | '__/ _ \
#  / ____ \| |_) |  __/ |  | |_| |_| | | |  __/
# /_/    \_\ .__/ \___|_|   \__|\__,_|_|  \___| (science)
#          | |
#          |_|
# 
# This was a triumph… I"m making a note here : huge success!
# It's hard to overstate my satisfaction!
# 
# We do what we must because we can.
# For the good of all of us, except the ones who are dead.
# 
# But there's no sense crying over every mistake ;
# You just keep on trying 'til you run out of cake.
# And the science gets done, and you make a neat game,
# For the people who are still alive.

func perhaps_open() -> bool:
	if not is_available():
		return false
	if not is_piled_with_you():
		return false
	
	print("Opening Portal `%s'…" % self.name)
	if not Game:
		printerr("Singleton `Game' is not defined.")
		return false
	
	Game.enter_level(self.level_path)
	return true


func is_piled_with_you() -> bool:
	var level = get_level()
	if not level:
		printerr("This Portal has no level.  Skipping is_piled_with_you()…")
		return false
	
	var it_is := false
	for item in level.get_all_items():
		if is_piled_with(item) and item.is_you:
			it_is = true
			break
	
	return it_is


func is_piled_with(other_item) -> bool:
	return self.cell_position == other_item.cell_position
