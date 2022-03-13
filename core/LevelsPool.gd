tool
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
# Naming woes ; refactor at will (into LevelResource, probably)
const PoolLevel = preload("res://core/LevelReference.gd")  # is a Resource


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



# We could also use a `res`, for performance.
# This file should be safe to delete, but the directory must exist.
export var cache_file_path := "res://cache/levels.tres"

# We save this to a file (defined above), and skip the expensive indexation.
var cache: LevelsPoolCache


func _init():
	set_name("LevelsPool")
	# It's expensive.  Call it yourselves when relevant.
	#init()


func _exit_tree():
	clear()


func init_full():  # expensive
	return init(true)


func init(invalidate_cache := false):
	rebuild_regexes()
	var loaded = load_cache_from_file()
	if loaded != OK or invalidate_cache or should_rebuild_cache():
		print("Re-indexing the levels.  This is going to take a few seconds.")
		reindex_levels()
		var saved := save_cache_to_file()
		if saved != OK:
			printerr("Cannot write the levels' cache to file.")
			breakpoint


func should_rebuild_cache():
	return (
		(not self.cache)
	)


func save_cache_to_file() -> int:
	if not self.cache:
		return ERR_CANT_ACQUIRE_RESOURCE
	self.cache.take_over_path(self.cache_file_path)
	var saved = ResourceSaver.save(
		self.cache_file_path,
		self.cache,
		0
#		||
#		ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS
#		||
#		ResourceSaver.FLAG_CHANGE_PATH
	)
	if saved != OK:
		return saved
	return OK


func load_cache_from_file() -> int:
	var file := File.new()
	if not file.file_exists(self.cache_file_path):
		return ERR_FILE_CANT_OPEN
	self.cache = ResourceLoader.load(
		self.cache_file_path,
		"", # "LevelsPoolCache"
		false # read file, not cache
	)
	if not self.cache:
		breakpoint  # corruption?
		return ERR_CANT_ACQUIRE_RESOURCE
	return OK


func clear():
	self.cache.clear()


func reindex_levels(refresh_existing := true):
	"""
	If refresh_existing is false, only newfound levels will be opened, analyzed and indexed.
	This parameter is basically equivalent to `invalidate_cache`, I believe.
	"""
	if refresh_existing:
		self.cache = LevelsPoolCache.new()
	
	for source_directory in self.source_directories:
		add_levels_in_directory(
			source_directory,
			self.directory_max_depth,
			self.excluded_directories,
			refresh_existing
		)
	
	reindex_levels_from_user(refresh_existing)
	reindex_orphanness()


func reindex_levels_from_user(refresh_existing := true):
	var dir_tool = Directory.new()
	for user_directory in self.user_directories:
		assert(user_directory.begins_with("user://"))  # just to be sure
		var _touched = dir_tool.make_dir_recursive(user_directory)
		add_levels_in_directory(
			user_directory,
			self.directory_max_depth,
			self.excluded_directories,
			refresh_existing
		)


func add_level(filepath: String, refresh_existing := true):
	var found := __level_path_regex.search(filepath)
	if not found and self.should_use_match:
		return
	
	var excluded := __excluded_level_path_regex.search(filepath)
	if excluded and self.should_use_exclusion:
		return
	
	assert(self.cache is LevelsPoolCache)
	if not refresh_existing and self.cache.levels.has(filepath):
		return  # Skip
	# Replace an existing level with new contents
	var _erased = self.cache.levels.erase(filepath)
	
	
	# TODO: maps?  we're going to need those at some point, right?
	
	var is_level_file_valid := false
	var level := PoolLevel.new()
	level.level_filepath = filepath
	
	if filepath.ends_with(".phiu"):
		var file := File.new()
		var opened := file.open(filepath, File.READ)
		if opened != OK:
			printerr("Failed to open .phiu file `%s`." % filepath)
			return
		
		var phiu: String = file.get_as_text()
		file.close()
		var parsed := level.parse_phiu(phiu)
		if OK != parsed:
			printerr("Failed to parse .phiu file `%s`." % filepath)
			breakpoint
			return
		is_level_file_valid = true

	if filepath.ends_with(".png"):
		var image := Image.new()
		var load_err := image.load(filepath)

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
			packed_level = null  # hungry GC
			is_level_file_valid = true
		else:
			printerr("Skipping scene `%s`: cannot load() it." % filepath)
	
	if not is_level_file_valid:
		return
	
	var level_instance = level.instantiate_scene()
	if not level_instance:
		print("%s: Skipping wannabe level `%s'." % [self.name, filepath])
		return
	# This is already checked/validated by level.instantiate_scene()
#	if not (level_instance is LevelScript):
#		print("%s: Skipping would-be level `%s'." % [self.name, filepath])
#		return
	
	#level_instance.register_all_items()
	level_instance.reindex_lattice()

	level.is_in_score = level_instance.contribute_to_completion_score
	level.title = level_instance.get_title_displayed()
	
	for portal_scene in level_instance.get_portals():
		var portal = PortalResource.new()
		portal.target_level_path = portal_scene.level_path
		level.portals.append(portal)
	
	# … grab more data from the level here, such as available concepts, their tallies, etc.

	self.cache.levels[filepath] = level
	
	level_instance.free()  # not queue_free() else boum


func add_levels_in_directory(
	target_directory,
	depth := 0,
	skipped_directories := Array(),
	refresh_existing := true
):
	if depth < 0:
		return
	if skipped_directories.has(target_directory):
		return
	
	var finder := FinderClass.new()
	finder.set_name("LevelsPoolFinder")
	var levels_directory = finder.list_directory(target_directory)
	
	for filepath in levels_directory['files']:
		add_level(filepath, refresh_existing)
	for filepath in levels_directory['directories']:
		add_levels_in_directory(filepath, depth - 1, excluded_directories, refresh_existing)
	finder.queue_free()


func get_levels_dict() -> Dictionary:
	assert(self.cache, "Call init() or init_full() first.")
	
	return self.cache.levels


func get_levels() -> Array:
	assert(self.cache, "Call init() or init_full() first.")
	
	return self.cache.levels.values()


func get_user_levels() -> Array:
	assert(self.cache, "Call init() or init_full() first.")
	
	var user_levels := Array()
	for level_filepath in self.cache.levels:
		var level = self.cache.levels[level_filepath]
		if level_filepath.begins_with("user://"):
			user_levels.append(level)
	return user_levels


func find_orphans_paths() -> Array:
	assert(self.cache, "Call init() or init_full() first.")
	
	var possible_orphans := self.cache.levels.keys()
	for parent_filepath in self.cache.levels:
		var parent_level = self.cache.levels[parent_filepath]
		for portal in parent_level.portals:
			possible_orphans.erase(portal.target_level_path)
	return possible_orphans


func reindex_orphanness():
	
	for level_filepath in self.cache.levels:
		var level = self.cache.levels[level_filepath]
		level.parents.clear()
	
	for parent_filepath in self.cache.levels:
		var parent_level = self.cache.levels[parent_filepath]
		for portal in parent_level.portals:
			if not portal.has_a_target_defined():
				continue
			assert(self.cache.levels.has(portal.target_level_path))
			if not self.cache.levels.has(portal.target_level_path):
				# Portal target level path is probably messed up.
				printerr("%s: Portal targets a level not in the level pool (%s)" % [
					self.name, portal.target_level_path,
				])
				continue
			self.cache.levels[portal.target_level_path].parents.append(parent_level)


## REGEXES #####################################################################

func __set_level_path_regex(value):
	level_path_regex = value  # not self.… !
	rebuild_regexes()


func __set_excluded_level_path_regex(value):
	excluded_level_path_regex = value  # not self.… !
	rebuild_regexes()


func __set_map_path_regex(value):
	map_path_regex = value  # not self.… !
	rebuild_regexes()


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


func rebuild_regexes() -> void:
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

