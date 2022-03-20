extends Node

# A Global Singleton for Game Logic.
# 
# Handles
# -------
# - Orchestration of top-level scenes (mostly levels)
# - Transitions between scenes
# - Save file
# - Achievements
# - …
# 
# When relevant, try to shift those responsibilities
# to other singletons, or plain objects if you can.
# This is why not all the properties of Game
# are at the top of this file, but along with the code.
# 
# This is a useful place to blackboard.
# 


# Adding new effects can be done in `effects/transitions.shader`.
# Add a new bool uniform named `is_<something>` like `is_snake` for example,
# add the GLSL shader code that handles it, add it here and enjoy!
var available_transition_effects := [
	'fade',
	'checkerboard',
	'vertical_stripes',
	'horizontal_stripes',
	'dots',
	'clock',
	'wavy',
	'diamond',
	'clock_grid',
	'circly',
	# Ideas
	#'diagonal_stripes',
	#'hive',
	#'sprite_zoom',
]

var transitions_duration := 0.42
var transitions_pause_duration := 0.70

################################################################################

var input_mapper_config := [
	{
		'action': 'move_up',
		'title': tr('Up'),
	},
	{
		'action': 'move_down',
		'title': tr('Down'),
	},
	{
		'action': 'move_left',
		'title': tr('Left'),
	},
	{
		'action': 'move_right',
		'title': tr('Right'),
	},
	{
		'action': 'move_up_left',
		'title': tr('Up Left'),
	},
	{
		'action': 'move_down_left',
		'title': tr('Down Left'),
	},
	{
		'action': 'move_up_right',
		'title': tr('Up Right'),
	},
	{
		'action': 'move_down_right',
		'title': tr('Down Right'),
	},
	{
		'action': 'pass',
		'title': tr('Pass'),
	},
	{
		'action': 'undo',
		'title': tr('Undo'),
	},
	{
		'action': 'restart',
		'title': tr('Restart'),
	},
	{
		'action': 'escape',
		'title': tr('Escape'),
	},
	{
		'action': 'pause',
		'title': tr('Pause'),
	},
	{
		'action': 'move_gauge_up',
		'title': tr('Arrow Up'),
	},
	{
		'action': 'move_gauge_down',
		'title': tr('Arrow Down'),
	},
	{
		'action': 'move_gauge_left',
		'title': tr('Arrow Left'),
	},
	{
		'action': 'move_gauge_right',
		'title': tr('Arrow Right'),
	},
]

################################################################################

var html5_disclaimer_scene_path := "res://guis/HTML5Disclaimer.tscn"

#var entrypoint_story_level_scene_path := "res://levels/laec/Chapter1Map.tscn"
var entrypoint_story_level_scene_path := "res://levels/story/Partie1Map.tscn"
# Don't use a map for tutos, use the first level (we rely on its completion)
var entrypoint_tutos_level_scene_path := "res://levels/tutorial/Tutorial01Level.tscn"
#var entrypoint_tutos_level_scene_path := "res://levels/tutorial/ButtonCheckLeft.tscn"
var entrypoint_extra_level_scene_path := "res://levels/PhiMap.tscn"
var entrypoint_tutorial_menu := "res://menus/TutorialMenu.tscn"
var entrypoint_button_check_level_scene_path := "res://levels/tutorial/ButtonCheckDownLeft.tscn"

const ItemScene = preload("res://core/Item.tscn")
#const LevelScene = preload("res://core/Level.tscn")
const LevelScript = preload("res://addons/laec-is-you/entity/Level.gd")
const LevelVictoryScreen = preload("res://menus/LevelVictoryScreen.tscn")
#const StartMenuScript = preload("res://menus/StartMenu.gd")
const StartMenuScene = preload("res://menus/StartMenu.tscn")


signal level_entered(level_name)
signal game_paused
signal game_resumed
signal level_completed
signal main_menu_entered


var root : Viewport  # sugar ← diabetes
var transition_timer : Timer

# Ever-increasing counter of frames since the beginning,
# /!.   SUBJECT TO BUFFER OVERFLOWS
var frames_processed := 0

# The game should be deterministic (unless we start doing crazy things),
# but transitions are randomized.
var rng := RandomNumberGenerator.new()


func i_am_never_called_because_i_am_a_hack():
	# Trick Godot's static analyser into thinking we emit the signal.
	# It thinks we don't, but we do, in the PauseMenu.
	emit_signal('game_resumed')


func _ready():
	transition_timer = Timer.new()
	var _sigh = transition_timer.connect("timeout", self, "transition_ended")
	add_child(transition_timer)
	self.root = get_tree().get_root()
	load_game()
	setup_transition_effect_layer()
	setup_achievements_layer()
	# Grab startup scene, defined in Project settings
	self.current_scene = root.get_child(root.get_child_count() - 1)
	
	# Wait for the next frame before accessing LevelsPool
	# Perhaps prone to race conditions?  Not sure.
#	call_deferred("setup_levels_pool")
	# Since this is autoloaded BEFORE other things that use it, it's OK
	# … perhaps.   Race conditions may still happen, not sure.
	setup_levels_pool()


func _process(_delta):
	update_transitions_shader_time()
	self.frames_processed += 1


func _input(_event):
	if Input.is_action_just_pressed("toggle_fullscreen"):
		App.toggle_fullscreen()



#   ____           _               _
#  / __ \         | |             | |
# | |  | |_ __ ___| |__   ___  ___| |_ _ __ __ _
# | |  | | '__/ __| '_ \ / _ \/ __| __| '__/ _` |
# | |__| | | | (__| | | |  __/\__ \ |_| | | (_| |
#  \____/|_|  \___|_| |_|\___||___/\__|_|  \__,_|
#
#

var current_scene = null
var scenes_ancestry := Array()  # of Node (scenes)
var __is_currently_switching := false


func switch_to_story_mode(free_current_scene := false):
	if is_level_complete(entrypoint_tutos_level_scene_path):
		enter_level(entrypoint_story_level_scene_path, free_current_scene)
	enter_level(entrypoint_tutos_level_scene_path, free_current_scene)


# Somewhat deprecated
func switch_to_level(
		level_path: String,
		free_current := false,
		append_ancestry := true
	):
	switch_to_scene_path(level_path, free_current, append_ancestry)


func switch_to_scene_path(
		scene_path: String,
		free_current := false,
		append_ancestry := true,
		animate_transition := true
	):
	var scene_pack = ResourceLoader.load(scene_path)
	assert(scene_pack, "Failed to load scene at `%s'." % [scene_path])
	if not scene_pack:
		# todo: Would love a glitched level here
		scene_pack = preload("res://levels/PhiMap.tscn")
	var scene_instance = scene_pack.instance()
	assert(scene_instance, "Failed to instantiate scene at `%s'." % [scene_path])
	print("%s switching to scene %s" % [self.name, scene_path])
	switch_to_scene(scene_instance, free_current, append_ancestry, animate_transition)


func switch_to_scene(
		scene_instance,
		free_current := false,
		append_ancestry := true,
		animate_transition := true
	) -> bool:
	
	assert(
		not (free_current and append_ancestry),
		"Best not append to ancestry a scene that you also free."
	)
	
	if self.__is_currently_switching:
		print("%s cancelled switch because it is already switching.")
		return false
	self.__is_currently_switching = true

	if self.current_scene and append_ancestry:
		#prints("Appending to ancestry", self.current_scene)
		self.scenes_ancestry.append(self.current_scene)

	if animate_transition:
		start_transition_effect(self.transitions_duration)
		yield(get_tree().create_timer(
			self.transitions_duration
			+
			self.transitions_pause_duration
		), "timeout")
	
	# Deleting the current scene at this point is
	# a bad idea, because it may still be executing code.
	# This will result in a crash or unexpected behavior.
	# The solution is to defer the load to a later time, when
	# we can be sure that no code from the current scene is running.
	call_deferred("__deferred_switch_to_scene", scene_instance, free_current)

	if animate_transition:
		start_transition_effect(self.transitions_duration, true)
		transition_timer.start(	
			self.transitions_duration)
	else:
		self.__is_currently_switching = false
	emit_scene_signals(current_scene, scene_instance)
	return true


func is_switching_scenes():
	return self.__is_currently_switching


func transition_ended():
#	print("timer ended")
	transition_timer.stop()
#	print(self.__is_currently_switching)
	self.__is_currently_switching = false

func __deferred_switch_to_scene(scene_instance, free_current):
	if not scene_instance:
		printerr("There is no scene to switch to.")
		return
	
	# It is now safe to remove the current scene
	if free_current:
		#prints("Freeing current scene", self.current_scene)
		self.current_scene.free()
	else:
		self.current_scene.get_parent().remove_child(current_scene)
		# Will be garbage-collected anyway, unless added to ancestry

	# Register the new current scene
	self.current_scene = scene_instance

	# Add it to the active scene, as child of root.
	get_tree().get_root().add_child(self.current_scene)

	# Make it compatible with the SceneTree.change_scene() API.
	get_tree().set_current_scene(self.current_scene)

	


func delete_scene(scene_instance) -> void:
	call_deferred("__deferred_delete_scene", scene_instance)


func __deferred_delete_scene(scene_instance) -> void:
	if scene_instance and is_instance_valid(scene_instance):
		scene_instance.queue_free()  # .free() should be ok too


# Not printed.
#func free():
#	print("FREEING GAME")
#	.free()


func _exit_tree():
	print("Game is closing…")
	if self.current_scene:
		print("→ Deleting current scene `%s'." % [self.current_scene.name])
		self.current_scene.queue_free()
#		self.current_scene.free()
		self.current_scene = null
	
	for scene in self.scenes_ancestry:
		print("→ Deleting ancestor scene `%s'." % [scene.name])
		scene.free()
#		scene.queue_free()
	
	print("Game has closed.  Goodbye!")


#   _____ _                   _
#  / ____(_)                 | |
# | (___  _  __ _ _ __   __ _| |___
#  \___ \| |/ _` | '_ \ / _` | / __|
#  ____) | | (_| | | | | (_| | \__ \
# |_____/|_|\__, |_| |_|\__,_|_|___/
#            __/ |
#           |___/


func emit_scene_signals(current, target):
#	print(current.name, " ", target.name)
	if target.name == "PauseMenu":
		if not current.name == "SettingsMenu":
			emit_signal("game_paused")
	elif target.name == "StartMenu":
		if not current.name == "SettingsMenu":
			emit_signal("main_menu_entered")
	elif target.name == "VictoryCard":
		emit_signal("level_completed")
	else:
		if (target is LevelScript):
#		if (not current.name == "PauseMenu" and 
#			not target.name == "SettingsMenu"):
			emit_signal("level_entered", target.name)


#  _                    _
# | |                  | |
# | |     _____   _____| |___
# | |    / _ \ \ / / _ \ / __|
# | |___|  __/\ V /  __/ \__ \
# |______\___| \_/ \___|_|___/
#
#

func setup_levels_pool():
	assert(LevelsPool)
	# This takes a looong time (0.3s) and it will grow with levels
	LevelsPool.init()


func reset_level():
	var current_scene_path = self.current_scene.filename
	if not current_scene_path:
		printerr(
			"Cannot reset current level because " +
			"`switch_to_level(…)' was never called."
		)
		return
	self.switch_to_level(current_scene_path, true, false)


func enter_level(level_path, free_current_scene := false):
	switch_to_level(level_path, free_current_scene, not free_current_scene)


func go_to_level_victory_screen(for_level) -> void:
	var levelVictoryScreen = LevelVictoryScreen.instance()
	levelVictoryScreen.prepare(for_level)
	assert(levelVictoryScreen.level)
	switch_to_scene(levelVictoryScreen, false, false)


#                               _
#     /\                       | |
#    /  \   _ __   ___ ___  ___| |_ _ __ _   _
#   / /\ \ | '_ \ / __/ _ \/ __| __| '__| | | |
#  / ____ \| | | | (_|  __/\__ \ |_| |  | |_| |
# /_/    \_\_| |_|\___\___||___/\__|_|   \__, |
#                                         __/ |
#                                        |___/

func is_path_in_ancestry(scene_path: String):
	var scene_pack = load(scene_path)
	for i in range(self.scenes_ancestry.size() - 1, 0, -1):
		if self.scenes_ancestry[i] is scene_pack:
			return true
	return false


#  _   _             _             _   _
# | \ | |           (_)           | | (_)
# |  \| | __ ___   ___  __ _  __ _| |_ _  ___  _ __
# | . ` |/ _` \ \ / / |/ _` |/ _` | __| |/ _ \| '_ \
# | |\  | (_| |\ V /| | (_| | (_| | |_| | (_) | | | |
# |_| \_|\__,_| \_/ |_|\__, |\__,_|\__|_|\___/|_| |_|
#                       __/ |
#                      |___/


func go_back_to_map() -> void:
	var went_back = go_back()
	if OK != went_back:
		printerr("Failed to go back to the map.")


func go_back(animate_transition := true, cancel_exit := false) -> bool:
#	print(scenes_ancestry)
#	print("Switching: ", __is_currently_switching)
	if self.scenes_ancestry.size() > 1:
#		print(self.scenes_ancestry[self.scenes_ancestry.size() - 1].get_script())
	#	if self.scenes_ancestry.find(current_scene) == -1:
	#		self.scenes_ancestry.append(current_scene)
		if __is_currently_switching and (
			self.scenes_ancestry[self.scenes_ancestry.size() - 1].get_script() == LevelScript
			):
#			print("Switching:", __is_currently_switching)
			return false
	if (not self.scenes_ancestry) and (not cancel_exit):
#		printerr("Nothing to go back to.")
		App.exit()
		return false
	if (not self.scenes_ancestry) and cancel_exit:
		return false
#	print("popping back")
	var previous_scene = self.scenes_ancestry[self.scenes_ancestry.size() - 1]
	
	if switch_to_scene(previous_scene, true, false, animate_transition):
		previous_scene = self.scenes_ancestry.pop_back()
		return true
	return false


func go_back_to_main_menu() -> void:
	"""Iterate over ancestry, try to find the main/start menu, instance it if 404"""
	var found_menu
	for _i in range(self.scenes_ancestry.size() - 1, 0, -1):
		var previous_scene = self.scenes_ancestry.pop_back()
		if previous_scene is StartMenu:
			found_menu = previous_scene
			break
		delete_scene(previous_scene)
	
	if found_menu:
		switch_to_scene(found_menu, true, false)
	else:
		switch_to_scene(StartMenuScene.instance(), true, false)


func go_back_to_first() -> void:
	if not self.scenes_ancestry:
		App.exit()
		return
	var first_scene = self.scenes_ancestry[0]
	for i in range(self.scenes_ancestry.size() - 1, 0, -1):
		delete_scene(self.scenes_ancestry[i])
	self.scenes_ancestry.clear()
	switch_to_scene(first_scene, true, false)


# incorrect logic
#func go_back_to_second() -> void:
#	if not self.scenes_ancestry:
#		App.exit()
#		return
#	var second_scene = self.scenes_ancestry[1]
#	for i in range(self.scenes_ancestry.size() - 1, 1, -1):
#		delete_scene(self.scenes_ancestry[i])
#	self.scenes_ancestry = [ self.scenes_ancestry[0]]
#	switch_to_scene(second_scene, true, false)


func go_back_twice() -> void:
	if not self.scenes_ancestry:
		App.exit()
		return
	
	var previous_scene = self.scenes_ancestry.pop_back()
	
	if not self.scenes_ancestry:
		App.exit()
		return
	
	var penultimate_scene = self.scenes_ancestry.pop_back()
	
	delete_scene(previous_scene)
	switch_to_scene(penultimate_scene, true, false)


func go_back_and_reset() -> void:
	
	if not self.scenes_ancestry:
		App.exit()
		return
	
	var previous_scene = self.scenes_ancestry.pop_back()
	
	var previous_scene_filepath = previous_scene.filename
	
	delete_scene(previous_scene)
	
	switch_to_scene_path(previous_scene_filepath, true, false)



const PauseMenuScene = preload("res://menus/PauseMenu.tscn")


func go_to_pause_menu(from_level) -> void:
	var pause_menu = PauseMenuScene.instance()
#	var tex = take_screenshot()
	pause_menu.initialize(from_level)
	var old_clear_mode = get_viewport().get_clear_mode()
	get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	# Let two frames pass to make sure the screen was captured.
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	pause_menu.update_background(get_viewport())
	get_viewport().set_clear_mode(old_clear_mode)
	switch_to_scene(pause_menu, false, true, false)


#  _______                  _ _   _
# |__   __|                (_) | (_)
#    | |_ __ __ _ _ __  ___ _| |_ _  ___  _ __  ___
#    | | '__/ _` | '_ \/ __| | __| |/ _ \| '_ \/ __|
#    | | | | (_| | | | \__ \ | |_| | (_) | | | \__ \
#    |_|_|  \__,_|_| |_|___/_|\__|_|\___/|_| |_|___/
#
#

var transition_effects : ColorRect
var transition_effects_layer : CanvasLayer


func setup_transition_effect_layer():
	var layer := CanvasLayer.new()
	layer.layer = 10
	var fx_rect := ColorRect.new()
	fx_rect.anchor_left = 0.0
	fx_rect.anchor_top = 0.0
	fx_rect.anchor_right = 1.0
	fx_rect.anchor_bottom = 1.0
	fx_rect.mouse_filter = fx_rect.MOUSE_FILTER_IGNORE
	
	var layer_material := ShaderMaterial.new()
	var layer_shader = preload("res://effects/transition.shader")
	layer_material.set_shader(layer_shader)
	fx_rect.set_material(layer_material)
	
	layer.add_child(fx_rect)
	self.add_child(layer)
	
	self.transition_effects = fx_rect
	self.transition_effects_layer = layer
	
	rng.randomize()


func start_transition_effect(duration:float, fade_out:=false, effect:='random', options:={}):
	if 'random' == effect:
		effect = available_transition_effects[(
			rng.randi() % available_transition_effects.size()
		)]
	
	var material = self.transition_effects.get_material()
	material.set_shader_param('duration_ms', duration * 1000.0)
	material.set_shader_param('is_fade_out', fade_out)
	material.set_shader_param('fade_color', options.get('fade_color', Color.black))
	
	for any_effect in available_transition_effects:
		material.set_shader_param("is_%s" % any_effect, false)
	material.set_shader_param("is_%s" % effect, true)
	
	material.set_shader_param('is_reversed', options.get('is_reversed', get_random_bool()))
	material.set_shader_param('is_centered', options.get('is_centered', get_random_bool()))
	material.set_shader_param('is_flip_h', options.get('is_flip_h', get_random_bool()))
	material.set_shader_param('is_flip_v', options.get('is_flip_v', get_random_bool()))
	
	material.set_shader_param('cell_size', options.get('cell_size', rng.randi_range(7,111)))
	material.set_shader_param('random_ratio', options.get('random_ratio', rng.randf()))
	
	# Lastly, …
	update_transitions_shader_time(true)
	material.set_shader_param('is_playing', true)


func update_transitions_shader_time(start_too:=false) -> void:
	# We can't manage to perfectly sync OS.get_ticks_msec() and TIME,
	# so we also provide the current time on each frame,
	# instead of just providing the start time once.
	# Bit expensive (would prefer a single call), but it works.
	var material = self.transition_effects.get_material()
	var rollover = 3600 * 1000  # mimic TIME's buffer overflow avoidance
	var time_ms = OS.get_ticks_msec() % rollover
	
	if start_too:
		material.set_shader_param('start_time_ms', time_ms)
	material.set_shader_param('current_time_ms', time_ms)


func get_random_bool():
	# RNG is pretty recent in Godot
	# If anyone feels like writing an extension of `RandomNumberGenerator`
	# with the goodies we need, and then perhaps make a plugin out of it, go!
	# rng.randb()
	# I'm not overly fond of the randX API
	return true if rng.randi() % 2 == 0 else false


#   _____
#  / ____|
# | (___   __ ___   _____
#  \___ \ / _` \ \ / / _ \
#  ____) | (_| |\ V /  __/
# |_____/ \__,_| \_/ \___|
#
#
# Current structure of the saved data:
# {
#   'levels': {
#     '<level_filepath>': {
#       'complete': <bool>,
#     },
#   },
# }
# 

var save_path := "user://savegame_01.save"
var save_readme_path := "user://README.md"
#var save_paths := Array()
var current_save_data := Dictionary()


func register_victory(on_level):
	var datum = {
		'complete': true,
	}
	#pragma: the business with recorded solution is specific to laecisyou, to refactor
#	write_to_level_save(on_level, datum)
#func write_to_level_save(level, datum:Dictionary):
	var current_scene_path = on_level.filename
	if not self.current_save_data.has('levels'):
		self.current_save_data['levels'] = Dictionary()
	if not self.current_save_data['levels'].has(current_scene_path):
		self.current_save_data['levels'][current_scene_path] = Dictionary()
	
	if on_level.recorded_solution:
		# Only save the solution if it is shorter than the save's
		if (
			(not self.current_save_data['levels'][current_scene_path].has('recorded_solution'))
			or
			(
				self.current_save_data['levels'][current_scene_path]['recorded_solution'].length()
				>=
				on_level.recorded_solution.length()
			)
		):
			datum['recorded_solution'] = on_level.recorded_solution
	
	for key in datum:
		self.current_save_data['levels'][current_scene_path][key] = datum[key]
	
	save_game()


func save_game():
	var dir = Directory.new()
	
	if not dir.file_exists(self.save_readme_path):
		var save_readme = File.new()
		save_readme.open(self.save_readme_path, File.WRITE)
		save_readme.store_line(SaveReadmeGenerator.get_save_readme())
		save_readme.close()
	var save_data_json = to_json(self.current_save_data)
	var save_game = File.new()
	save_game.open(self.save_path, File.WRITE)
	save_game.store_line(save_data_json)
	save_game.close()


func load_game():
	var save_game = File.new()
	if not save_game.file_exists(self.save_path):
		print("[Game] No save to load at `%s'." % self.save_path)
		return  # We don't have a save to load.

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	save_game.open(self.save_path, File.READ)
	self.current_save_data = parse_json(save_game.get_line())
	save_game.close()


func is_level_complete(level_path):
	return (
		self.current_save_data.has('levels')
		and self.current_save_data['levels'].has(level_path)
		and self.current_save_data['levels'][level_path].has('complete')
		and self.current_save_data['levels'][level_path]['complete']
	)


func get_completion_score() -> float:  # between 0.0 and 1.0
	if not LevelsPool:
		breakpoint
		return 0.0
	
	var amount_of_levels_to_complete := 0.0  # yes, float (division!)
	var amount_of_levels_completed := 0.0
	
	# We don't need to use this cached value anymore
	# (it is not even set anymore, I think)
#	var completion_score_levels = FileStorage.get_value(
#		"LevelsPool", "completion_score_levels", Array()
#	)
	# Instead, we ask the LevelsPool, which handles its own cache
	var completion_score_levels = LevelsPool.get_levels_contributing_to_score()
	
	for level in completion_score_levels:
		amount_of_levels_to_complete += 1.0
		if is_level_complete(level.level_filepath):
			amount_of_levels_completed += 1.0
	
	if 0.0 == amount_of_levels_to_complete:
		return 0.42
	
	return amount_of_levels_completed / amount_of_levels_to_complete


#   _____
#  / ____|
# | (___  _ __   __ ___      ___ __
#  \___ \| '_ \ / _` \ \ /\ / / '_ \
#  ____) | |_) | (_| |\ V  V /| | | |
# |_____/| .__/ \__,_| \_/\_/ |_| |_|
#        | |
#        |_|

# DEPRECATED — Use method of Level instead
func spawn_item(in_level, item_to_copy=null, extra_properties:Dictionary={}):
	breakpoint
	return in_level.spawn_item(item_to_copy, extra_properties)


#               _     _                                     _
#     /\       | |   (_)                                   | |
#    /  \   ___| |__  _  _____   _____ _ __ ___   ___ _ __ | |_ ___
#   / /\ \ / __| '_ \| |/ _ \ \ / / _ \ '_ ` _ \ / _ \ '_ \| __/ __|
#  / ____ \ (__| | | | |  __/\ V /  __/ | | | | |  __/ | | | |_\__ \
# /_/    \_\___|_| |_|_|\___| \_/ \___|_| |_| |_|\___|_| |_|\__|___/
#
#


const AchievementCard = preload("res://guis/AchievementCard.tscn")
var achievements_layer : CanvasLayer


func setup_achievements_layer():
	var layer := CanvasLayer.new()
	layer.layer = 20
	self.achievements_layer = layer
	add_child(self.achievements_layer)


func is_achievement_unlocked(achievement: Achievement) -> bool:
	var current_scene_path : String = self.current_scene.filename
	if not self.current_save_data or not (self.current_save_data is Dictionary):
		return false
	if not self.current_save_data.has('levels'):
		return false
	if not self.current_save_data['levels'].has(current_scene_path):
		return false
	if not self.current_save_data['levels'][current_scene_path].has('achievements'):
		return false
	
	var achs = self.current_save_data['levels'][current_scene_path]['achievements']
	var ach_id = achievement.snake_identifier
	
	if not (achs is Dictionary):
		return false
	if not achs.has(ach_id):
		return false
	if not achs[ach_id].has('complete'):
		return false
	
	return achs[ach_id]['complete']


func unlock_achievement(achievement: Achievement):
	var current_scene_path = self.current_scene.filename
	if not self.current_save_data.has('levels'):
		self.current_save_data['levels'] = Dictionary()
	if not self.current_save_data['levels'].has(current_scene_path):
		self.current_save_data['levels'][current_scene_path] = Dictionary()
	if not self.current_save_data['levels'][current_scene_path].has('achievements'):
		self.current_save_data['levels'][current_scene_path]['achievements'] = Dictionary()
	
	var achs = self.current_save_data['levels'][current_scene_path]['achievements']
	var ach_id = achievement.snake_identifier
	
	if not achs.has(ach_id):
		achs[ach_id] = {
			'complete': false,  # defaults
		}
	
	if achs[ach_id]['complete']:
		#print("Achievement already completed")
		return  # Achievements may only be triggered once per save file
	
	achs[ach_id]['complete'] = true
	
	prints('Unlocked Achievement!', achievement, achievement.snake_identifier)
	
	var achievement_card = AchievementCard.instance()
	self.achievements_layer.add_child(achievement_card)
	achievement_card.from_achievement(achievement)
	
	save_game()

