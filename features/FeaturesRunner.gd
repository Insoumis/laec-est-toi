extends Control

#  ______         _                         _____
# |  ____|       | |                       |  __ \
# | |__ ___  __ _| |_ _   _ _ __ ___  ___  | |__) |   _ _ __  _ __   ___ _ __
# |  __/ _ \/ _` | __| | | | '__/ _ \/ __| |  _  / | | | '_ \| '_ \ / _ \ '__|
# | | |  __/ (_| | |_| |_| | | |  __/\__ \ | | \ \ |_| | | | | | | |  __/ |
# |_|  \___|\__,_|\__|\__,_|_|  \___||___/ |_|  \_\__,_|_| |_|_| |_|\___|_|
#
#
# - [x] Run
# - [x] Display list of ran features
# - [ ] Unload without errors nor memory leaks
# - [ ] Display metrics (time elapsed, amount of features, failures ratio)
# - [ ] Allow rerun of failures
#
# Homebrewed feature suite runner.
# Pretty basic, but it's doing its best to help.  And it does!  Help, that is.
# Depends on Finder to find the scenes even when in prod.
# 
# Run the scene to see which features pass and which don't.
# This helps offloading mental workload into files,
# when writing new rules and qualities and mechanics.
# 
# This will also help with bug reporting.
# …
# And with tool-assisted speedruns, of course :3


const Level = preload("res://addons/laec-is-you/entity/Level.gd")


const MAX_DIRECTORY_DEPTH := 8  # for auto-discovering of "feature" files


# In our case, instances of Levels are our features
# Subclasses work better than class_name in static analysis in Godot for now.
# If you move this to its own file, weird things'll happen.
class Feature:
	extends Reference
	var filepath : String
	var packed_scene : PackedScene
	var instance  # of the Level scene, freed on unload
	var has_finished := false
	var has_passed := false


signal feature_started(feature)
signal feature_passed(feature)
signal feature_failed(feature)
signal suite_passed()
signal suite_failed()
signal suite_finished()


# Delay the run of the feature suite by that many seconds.
# Used when recording with OBS for example.
export var startup_delay := 0.0


var __features_ran := Array()
var __features_left_to_run := Array()
var __running_feature : Feature
var __running_feature_instance
var __is_currently_running_a_feature := false


onready var reports_list = find_node('ReportsList', true)


var __done_running := false
var __running_time_elapsed := 0.0  # seconds spent running features
var __startup_time_elapsed := 0.0  # seconds spent in startup delay


func _ready():
	var finder := FinderClass.new()
	var directory = finder.list_directory("res://levels")
	
	self.reports_list.visible = false
	add_levels_in_directory_as_features("res://features/autoplays")
	for directory_path in directory['directories']:
		if "res://levels/tutorial" == directory_path:
			continue
		add_levels_in_directory_as_features(directory_path)
	var _c = connect("suite_finished", self, "__on_suite_finished")


func __on_suite_finished():
	self.reports_list.visible = true


func add_levels_in_directory_as_features(directory_path: String, depth := 0):
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
		var feature = Feature.new()
		feature.filepath = filepath
		feature.packed_scene = load(filepath)
		assert(feature)
		assert(feature.filepath)
		assert(feature.packed_scene)
		
		# At this point we did not check yet if the scene file is a Level.
		# We'll check that later, upon instantiation.
		__features_left_to_run.append(feature)
	
	var directories = finder.list_directories_of(directory_path)
	for directory in directories:
		if directory == "tutorial":
			continue
		add_levels_in_directory_as_features(directory, depth+1)
	#prints("Features left to run", __features_left_to_run)


func should_skip_file(filepath: String) -> bool:
#	return not filepath.ends_with('Level.tscn')  # bit rough ; we use "is Level"
	return is_file_of_map(filepath)


func is_file_of_map(filepath: String) -> bool:
	return filepath.ends_with('Map.tscn')


func _process(delta):
	if self.__is_currently_running_a_feature:
		self.__running_time_elapsed += delta
		return
	if self.__done_running:
		set_process(false)
		return
	if self.__features_left_to_run.empty():
		self.__done_running = true
		emit_signal("suite_finished")
		return
	if self.__startup_time_elapsed < self.startup_delay:
		self.__startup_time_elapsed += delta
		return
	
	var feature = self.__features_left_to_run.pop_front()
	assert(feature)
	run_feature(feature)


func run_feature(feature: Feature):
	assert(not self.__is_currently_running_a_feature)
	assert(not self.__running_feature_instance)
	
	var feature_running = feature.packed_scene.instance()
	
	assert(feature_running is Level)
	if not (feature_running is Level):
		feature_running.queue_free()
		return  # skip!
	
	feature.instance = feature_running
	feature_running.is_test_run = true
	
	var has_no_solution_to_play := true
	
	if '' != feature_running.solution_a:
		feature_running.autoplay_a = true
		has_no_solution_to_play = false
	
	if has_no_solution_to_play:
		printerr("Level `%s' has no solution to play!" % [
			feature_running.filename,
		])
	
	self.__is_currently_running_a_feature = true
	self.__running_feature = feature
	self.__running_feature_instance = feature_running
	var _cx
	_cx = feature_running.connect("test_passed", self, 'on_feature_passed', [
		feature,
	])
	_cx = feature_running.connect("test_failed", self, 'on_feature_failed', [
		feature,
	])
	add_child(feature_running)
	emit_signal("feature_started", feature)
	# Shaking the camera, besides being rad, also solves a camera glitch
	feature_running.shake_camera()
	
	if has_no_solution_to_play:
		__handle_feature_failure(feature, "No solution defined !")


func unload_feature():
	assert(self.__is_currently_running_a_feature)
	assert(self.__running_feature_instance)
	
	self.__features_ran.append(self.__running_feature)
	self.__running_feature.instance = null
	self.__running_feature_instance.queue_free()
	
	self.__is_currently_running_a_feature = false
	self.__running_feature_instance = null
	self.__running_feature = null


func add_report(feature: Feature, ok: bool, msg := ""):
	var level = feature.instance
	var message = "0K : %s (%s) at %s" % [
		level.title_displayed,
		level.name,
		feature.filepath,
	]
	if not ok:
		message = "/!.  FAILURE : %s (%s) at %s" % [
			level.title_displayed,
			level.name,
			feature.filepath,
		]
	if msg != "":
		message = "%s\n  %s" % [message, msg]
	var report = Label.new()
	report.text = message
	reports_list.add_child(report)
	print(message)


func on_feature_passed(feature: Feature):
	__handle_feature_success(feature)


func on_feature_failed(feature: Feature):
	__handle_feature_failure(feature)


func __handle_feature_success(feature: Feature, msg := ""):
	feature.has_finished = true
	feature.has_passed = true
	add_report(feature, true, msg)
	emit_signal("feature_passed", feature)
	unload_feature()


func __handle_feature_failure(feature: Feature, msg := ""):
	feature.has_finished = true
	feature.has_passed = false
	add_report(feature, false, msg)
	emit_signal("feature_failed", feature)
	unload_feature()
