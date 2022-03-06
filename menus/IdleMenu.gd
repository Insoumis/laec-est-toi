extends Control

#  _____    _ _        __  __
# |_   _|  | | |      |  \/  |
#   | |  __| | | ___  | \  / | ___ _ __  _   _
#   | | / _` | |/ _ \ | |\/| |/ _ \ '_ \| | | |
#  _| || (_| | |  __/ | |  | |  __/ | | | |_| |
# |_____\__,_|_|\___| |_|  |_|\___|_| |_|\__,_|
#
#
# - [x] Run
# - [x] Be fun
# - [x] Disappear on interaction
# - [?] Unload without errors nor memory leaks
#
# Depends on Finder to find the levels to run, in the release filesystem.
# 
# Run the scene to see which features pass and which don't.
# This helps offloading mental workload into files,
# when writing new rules and qualities and mechanics.
# 
# This will also help with bug reporting.
# …
# And with tool-assisted speedruns, of course :3


const Level = preload("res://addons/laec-is-you/entity/Level.gd")


const MAX_DIRECTORY_DEPTH := 8  # for auto-discovery of level files


# Subclasses work better than class_name in static analysis in Godot for now.
# If you move this to its own file, weird things'll happen.
class LevelRun:
	extends Reference
	var filepath : String   # to a Level scene
	var packed_scene : PackedScene  # of a Level, result of load()
	var instance  # of the Level scene, freed on unload
	var has_finished := false
	var has_passed := false  # victory was achieved before the end of the inputs


signal level_started(level_run)
signal level_passed(level_run)
signal level_failed(level_run)
#signal suite_passed()
#signal suite_failed()
signal suite_finished()


# We'll play in sequence all the lavels in this directory========
export var levels_source_directory := "res://levels/idle"

# Delay the run of the feature suite by that many seconds.
# Used when recording with OBS for example.
export var startup_delay := 0.0



# Double underscore for private vars ; don't blame me, blame it on the boogie
var __levels_ran := Array()
var __levels_left_to_run := Array()
var __running_level : LevelRun
var __running_level_instance
var __is_currently_running_a_level := false
var __done_running := false
var __running_time_elapsed := 0.0  # seconds spent running levels
var __startup_time_elapsed := 0.0  # seconds spent in startup delay


func _ready():
	setup()


func _process(delta):
	if __startup_time_elapsed < self.startup_delay:
		__startup_time_elapsed += delta
		return
	if __is_currently_running_a_level:
		__running_time_elapsed += delta
		return
	if __done_running:
		set_process(false)
		return
	if __levels_left_to_run.empty():
		__done_running = true
		emit_signal("suite_finished")
		return
	
	var level = __levels_left_to_run.pop_front()
	assert(level)
	run_level(level)


func _input(event):
	if event is InputEventMouseMotion:
		return
	if event is InputEventJoypadMotion:
		return
	exit()


func setup():
	add_idle_levels()
	var _c = connect("suite_finished", self, "__on_suite_finished")


func add_idle_levels():
	add_levels_in_directory(self.levels_source_directory)
#	shuffle_levels() ?


func __on_suite_finished():
	add_idle_levels()
	__done_running = false


func add_levels_in_directory(directory_path: String, depth := 0):
	if depth > MAX_DIRECTORY_DEPTH:
		printerr(
			"Maximum depth reached when adding levels.  Skipping `%s'…"
			%
			[directory_path]
		)
		return
	var finder = FinderClass.new()
	var contents = finder.list_files_with_extensions(
		directory_path, ['tscn']
	)
	for filepath in contents:
		if should_skip_file(filepath):
			continue
		var level_run = LevelRun.new()
		level_run.filepath = filepath
		level_run.packed_scene = load(filepath)
		assert(level_run)
		assert(level_run.filepath)
		assert(level_run.packed_scene)
		
		# At this point we did not check yet if the scene file is a Level.
		# We'll check that later, upon instantiation.
		__levels_left_to_run.append(level_run)
	
#	var directories = finder.list_directories_of(directory_path)
#	for directory in directories:
#		if directory == "tutorial":
#			continue
#		add_levels_in_directory(directory, depth+1)
	
#	prints("Idle menu levels left to run", __levels_left_to_run)


func should_skip_file(filepath: String) -> bool:
#	return not filepath.ends_with('Level.tscn')  # bit rough ; we use "is Level"
	return is_file_of_map(filepath)


func is_file_of_map(filepath: String) -> bool:
	return filepath.ends_with('Map.tscn')


func should_skip_instance(level_instance) -> bool:
	return not (level_instance is Level)


func run_level(level: LevelRun) -> void:
	assert(not self.__is_currently_running_a_level)
	assert(not self.__running_level_instance)
	
	var level_running = level.packed_scene.instance()
	
	if should_skip_instance(level_running):
		level_running.queue_free()
		return  # skip!
	
	level.instance = level_running
	level_running.is_test_run = true
	level_running.no_interaction = true
#	level_running.hide_gui_buttons()
	
	var has_no_solution_to_play := true
	
	if '' != level_running.solution_a:
		level_running.autoplay_a = true
		has_no_solution_to_play = false
	
	if has_no_solution_to_play:
		printerr("Level `%s' has no solution A to play!" % [
			level_running.filename,
		])
	
	self.__is_currently_running_a_level = true
	self.__running_level = level
	self.__running_level_instance = level_running
	var _cx
	_cx = level_running.connect("test_passed", self, 'on_level_passed', [level])
	_cx = level_running.connect("test_failed", self, 'on_level_failed', [level])
	add_child(level_running)
	emit_signal("level_started", level)
	# Shaking the camera, besides being rad, also solves a camera glitch
	level_running.shake_camera()
	
	if has_no_solution_to_play:
		__handle_level_failure(level, "No solution defined !")


func unload_level():
	if not __is_currently_running_a_level:
		return
	assert(__is_currently_running_a_level)
	assert(__running_level_instance)
	
	__levels_ran.append(__running_level)
	__running_level.instance = null
	__running_level_instance.queue_free()
	
	__is_currently_running_a_level = false
	__running_level_instance = null
	__running_level = null


var __is_exiting := false

func exit():
	if __is_exiting:
		return  # prevent fast double clicks and other shenanigans
	__is_exiting = Game.go_back()
	#unload_level()
	


func on_level_passed(level: LevelRun):
	__handle_level_success(level)


func on_level_failed(level: LevelRun):
	__handle_level_failure(level)


func __handle_level_success(level: LevelRun, _msg := ""):
	level.has_finished = true
	level.has_passed = true
	emit_signal("level_passed", level)
	unload_level()


func __handle_level_failure(level: LevelRun, _msg := ""):
	level.has_finished = true
	level.has_passed = false
	emit_signal("level_failed", level)
	unload_level()
