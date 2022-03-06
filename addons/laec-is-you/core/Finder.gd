# Either as singleton
extends Node # singleton Finder for example
# or as simple class
class_name FinderClass # class
# … your pick!  (remember to .free() it if using the class)


#  ______ _           _
# |  ____(_)         | |
# | |__   _ _ __   __| | ___ _ __
# |  __| | | '_ \ / _` |/ _ \ '__|
# | |    | | | | | (_| |  __/ |
# |_|    |_|_| |_|\__,_|\___|_|
#
# version 0.1.1-20220222
#
#
# ## Pitfall
#
# Make sure you include `*.cfg` or `finder.cfg` in your export configuration !
#
#
# ## Rationale
#
# Directory() does not work in standalone (exported builds).
# This is not a bug, just the way the filesystem works.
# This class aims to help hack around this limitation.
# It's very convenient to be able to list files in a directory.
# Makes me write less code.
# 
# 
# ## How it works
#
# It will create a cache file that should be added to exports.
# When it detects it is in standalone and not looking through `user://`,
# it uses the cached file instead that you produced doing the same thing
# during development.
# 
# That means that everytime you add a file in a directory you're listing
# with Finder, you have to run a script that uses Finder on that directory
# BEFORE you export the game, so that Finder can update `finder.cfg`.
# 
# We could also add a routine that scans the whole project, to mitigate that.
# Never needed it myself.  (for now)
# 

# Just use Logger trait later on
var is_logging := false

# File will be created if missing, but not intermediary directories.
var cache_path := "res://finder.cfg"

# A handle to the cache file, to write and read from.
# Using a ConfigFile because it Just Works®, we could also make our own.
var __cache := ConfigFile.new()


func _init():
	init()


func __print(thing) -> void:
	if is_logging:
		print("[%s] %s" % [self.name, str(thing)])


func init():
	var cache_path = get_cache_path()
	var err = __cache.load(cache_path)

	if err != OK:
		__print("No cache found at `%s'." % [cache_path])
		save_cache()


func get_cache_path():
	return self.cache_path


func get_cache():
	return __cache


func save_cache():
	var used_cache_path = get_cache_path()
	var err = __cache.save(used_cache_path)
	if err != OK:
		printerr("[%s] ERROR! Cannot save cache at `%s'." % [
			self.name, used_cache_path,
		])


func list_directory(directory_path: String) -> Dictionary:
	"""
	Main API.  Paths are full, so they all start by something like `xxxx://`.
	Structure of output:
		{
			'files': <array of paths as strings>,
			'directories': <array of paths as strings>,
		}
	"""
	var is_userland = directory_path.begins_with("user://")
	if is_in_tool_mode() or is_userland:
		var directories_paths = Array()
		var files_paths = Array()
		
		var directory = Directory.new()
		if OK == directory.open(directory_path):
			directory.list_dir_begin(true)
			var file_name = directory.get_next()
			while file_name != "":
				var path = "%s/%s" % [directory_path, file_name]
				if directory.current_is_dir():
					__print("Found directory: `%s'." % path)
					directories_paths.append(path)
				else:
					__print("Found file: `%s'." % path)
					files_paths.append(path)
				
				file_name = directory.get_next()
			directory.list_dir_end()
		else:
			printerr("[%s] Failed to open `%s'." % [self.name, directory_path])
		
		files_paths.sort()
		directories_paths.sort()
		
		if not is_userland:
			__cache.set_value(directory_path, "directories_all", directories_paths)
			__cache.set_value(directory_path, "files_all", files_paths)
			save_cache()
		else:
			return {
				'files': files_paths,
				'directories': directories_paths,
			}
	
	return {
		'files': __cache.get_value(directory_path, "files_all", Array()),
		'directories': __cache.get_value(directory_path, "directories_all", Array()),
	}


func list_files_with_extensions(directory_path:String, extensions:Array) -> Array:
	"""
	Sugar
	"""
	var directory_lists = list_directory(directory_path)
	var all_files = directory_lists['files']
	var found_files = Array()
	for file in all_files:
		for extension in extensions:
			if file.ends_with(extension):
				found_files.append(file)
	
	return found_files


func list_directories_of(directory_path: String) -> Array:
	var directory_lists = list_directory(directory_path)
	return directory_lists['directories']


func is_in_tool_mode() -> bool:
	return not OS.has_feature("standalone")
