extends Node
class_name LevelsPoolClass  # singleton could be LevelsPool

#  _                    _     _____            _
# | |                  | |   |  __ \          | |
# | |     _____   _____| |___| |__) |__   ___ | |
# | |    / _ \ \ / / _ \ / __|  ___/ _ \ / _ \| |
# | |___|  __/\ V /  __/ \__ \ |  | (_) | (_) | |
# |______\___| \_/ \___|_|___/_|   \___/ \___/|_|
#
# Looks through directories at scene files, to build a pool of Levels.
# Since we do not have a centralized database of levels,
# we use this at runtime to build a pool of "available" Levels,
# by reading the files in the res://levels/ directory (configurable).
# 
# We could perhaps also use it to build Chapter level pools or some such.
# 

const Level = preload("res://addons/laec-is-you/entity/Level.gd")
const Jsonify = preload("res://lib/jsonify.gd")
const CompressorSerializer = preload("res://lib/CompressorSerializer.gd")
const PoolLevel = preload("res://core/LevelReference.gd")


class LevelLink:
	extends Reference
	var from : String  # filepath
	var to : String  # filepath


export var source_directories := [
	"res://levels",
]
export var user_directories := [
	"user://levels",
]
export var directory_max_depth := 8  # for recursion through subdirs
export var excluded_directories := Array()  # of full paths

# Only files whose path matches this regex will be indexed.
export var should_use_match := true
export var level_path_regex := \
	"/?([^/]+/|)*[^/]+[.](tscn|phiu|png)" \
	setget __set_level_path_regex

var __level_path_regex : RegEx

# All files whose path matches this regex will be excluded.
export var should_use_exclusion := true
export var excluded_level_path_regex := \
	"/([^/]+/|)*[^/]+Map[.](tscn|phiu|png)" \
	setget __set_excluded_level_path_regex

var __excluded_level_path_regex : RegEx

# All files whose path matches this regex will be considered maps.
export var should_match_maps := true
export var map_path_regex := \
	"/([^/]+/|)*[^/]+Map[.](tscn|phiu|png)" \
	setget __set_map_path_regex

var __map_path_regex : RegEx


# Main index of levels.  Not sure how big this can get?
var levels := Dictionary()  # filepath => PoolLevel

# TODO: Replace this by an accessor, and use self.levels internally !
var packed_levels := Dictionary()  # filepath => PackedScene

# Index of instanced levels.
# WiP: probably too expensive and troublesome to keep
var instanced_levels := Dictionary()  # filepath => Level

# Links between levels, collected from found portals
var levels_links := Array()  # of LevelLink


# It's expensive.  Call it yourselves when relevant.
#func _init():
#	init()


func _exit_tree():
	clear()


func __set_level_path_regex(value):
	level_path_regex = value  # not self.… !
	rebuild_regexes()


func __set_excluded_level_path_regex(value):
	excluded_level_path_regex = value  # not self.… !
	rebuild_regexes()


func __set_map_path_regex(value):
	map_path_regex = value  # not self.… !
	rebuild_regexes()


func init():
	rebuild_regexes()
	reindex_levels()


func init_full():  # expensive
	init()
	instance_levels()
	reindex_portals()


func clear():
	for filepath in self.instanced_levels:
		self.instanced_levels[filepath].queue_free()
	self.instanced_levels.clear()
	self.levels_links.clear()  # LevelLink is Reference
	self.packed_levels.clear()  # PackedScene is Reference


func build_regex_path_prefix() -> String:
	var r := "("
	var first_prefix := true
	for source_directory in self.source_directories:
		r += source_directory  # how to escape for regex?  FIXME
		if not first_prefix:
			r += "|"
		else:
			first_prefix = false
	for user_directory in self.user_directories:
		r += user_directory  # how to escape for regex?  FIXME
		if not first_prefix:
			r += "|"
		else:
			first_prefix = false
	r += ")"
	
	return r


func rebuild_regexes():
	var path_prefix := build_regex_path_prefix()
	var err: int # : Error
	__level_path_regex = RegEx.new()
	err = __level_path_regex.compile(path_prefix + self.level_path_regex)
	if err != OK:
		printerr("Failed to compile regex `%s`." % path_prefix + self.level_path_regex)
	
	__excluded_level_path_regex = RegEx.new()
	err = __excluded_level_path_regex.compile(
		path_prefix 
		+
		self.excluded_level_path_regex
	)
	if err != OK:
		printerr("Failed to compile regex `%s`." % path_prefix + self.excluded_level_path_regex)
	
	__map_path_regex = RegEx.new()
	err = __map_path_regex.compile(
		path_prefix
		+
		self.map_path_regex
	)
	if err != OK:
		printerr("Failed to compile regex `%s`." % path_prefix + self.map_path_regex)


func reindex_levels():
	self.packed_levels.clear()
	
	for source_directory in self.source_directories:
		add_levels_in_directory(
			source_directory,
			self.directory_max_depth,
			self.excluded_directories
		)
	
	var dir_tool = Directory.new()
	for user_directory in self.user_directories:
		assert(user_directory.begins_with("user://"))  # just to be sure
		var _touched = dir_tool.make_dir_recursive(user_directory)
		add_levels_in_directory(
			user_directory,
			self.directory_max_depth,
			self.excluded_directories
		)


func get_user_levels() -> Array:
	var user_levels := Array()
	for level_filepath in self.levels:
		var level = self.levels[level_filepath]
		if level_filepath.begins_with("user://"):
			user_levels.append(level)
	return user_levels


func add_level(filepath: String):
	var found := __level_path_regex.search(filepath)
	if not found and self.should_use_match:
		return
	
	var excluded := __excluded_level_path_regex.search(filepath)
	if excluded and self.should_use_exclusion:
		return
	
	# TODO: maps?  we're going to need those at some point, right?
	
	var is_level_file_valid := false
	var level := PoolLevel.new()
	level.filepath = filepath
	
	if filepath.ends_with(".phiu"):
		var file = File.new()
		file.open(filepath, File.READ)
		var phiu = file.get_as_text()
		file.close()
		var parsed = level.parse_phiu(phiu)
		if OK != parsed:
			printerr("Failed to parse .phiu file `%s`." % filepath)
			breakpoint
			return
		is_level_file_valid = true

	if filepath.ends_with(".png"):
		var image = Image.new()
		var load_err = image.load(filepath)

		if OK != load_err:
			Logger.warn("Cannot open PNG file `%s'." % filepath, null, load_err)
			breakpoint
			return

		var parse_err = level.parse_image_level(image)

		if OK != parse_err:
			Logger.warn("Cannot parse PNG file `%s'." % filepath, null, parse_err)
			breakpoint
			return

		is_level_file_valid = true
	
	elif filepath.ends_with(".tscn"):
		var packed_level = load(filepath)
		if packed_level:
			level.packed = packed_level
			self.packed_levels[filepath] = packed_level
			is_level_file_valid = true
		else:
			printerr("Skipping scene `%s`: cannot load() it." % filepath)
	
	if is_level_file_valid:
		self.levels[filepath] = level


func add_levels_in_directory(
	target_directory,
	depth := 0,
	skipped_directories := Array()
):
	if depth < 0:
		return
	
	if skipped_directories.has(target_directory):
		return
	
	var finder := FinderClass.new()
	finder.set_name("LevelsPoolFinder")
	var levels_directory = finder.list_directory(target_directory)
	
	for filepath in levels_directory['files']:
		add_level(filepath)
	for filepath in levels_directory['directories']:
		add_levels_in_directory(filepath, depth - 1, excluded_directories)


func instance_levels():
	for filepath in self.instanced_levels:
		self.instanced_levels[filepath].queue_free()
	self.instanced_levels.clear()
	var completion_score_levels := Array()  # of filepaths? of PoolLevel?
	for filepath in self.packed_levels:
		var level = self.packed_levels[filepath].instance()
		self.instanced_levels[filepath] = level
		if level.contribute_to_completion_score:
			completion_score_levels.append(
				filepath
			)
	# Cache the index of the levels useful in completion score calculus 
	FileStorage.set_value(
		"LevelsPool", "completion_score_levels", completion_score_levels
	)


func reindex_portals():
	assert(self.instanced_levels, "Call instance_levels() first.")
	for filepath in self.instanced_levels:
		var level = self.instanced_levels[filepath]
		assert(level is Level)
		var portals : Array = level.get_all_portals()
#		print("Found %d portals for %s" % [portals.size(), filepath])
		for portal in portals:
			var link = LevelLink.new()
			link.from = filepath
			link.to = portal.level_path
			if not link.to:
				printerr("Portal `%s` without target in %s" % [
					portal.name, filepath
				])
				continue
			self.levels_links.append(link)


func find_orphans() -> Array:
	assert(self.levels_links, "Call reindex_portals() first.")
	
	var possible_orphans := self.packed_levels.keys()
	for link in self.levels_links:
		possible_orphans.erase(link.from)  # adopted
		possible_orphans.erase(link.to)    # you too
	
	return possible_orphans

