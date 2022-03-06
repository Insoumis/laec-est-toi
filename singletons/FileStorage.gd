extends Node

#  ______ _ _       _____ _
# |  ____(_) |     / ____| |
# | |__   _| | ___| (___ | |_ ___  _ __ __ _  __ _  ___
# |  __| | | |/ _ \\___ \| __/ _ \| '__/ _` |/ _` |/ _ \
# | |    | | |  __/____) | || (_) | | | (_| | (_| |  __/
# |_|    |_|_|\___|_____/ \__\___/|_|  \__,_|\__, |\___|
#                                             __/ |
#                                            |___/
# v0.0.0
# Singleton.
# Stores primitives, basically a wrapper for ConfigFile.
# Poor man's Redis.
# 


export var filepath := "res://storage.cfg"


var __file := ConfigFile.new()


func _init():
	init()


func init():
	var store_path = get_store_path()
	var loaded = __file.load(store_path)
	if OK != loaded:
		print("No file storage found at `%s'." % [store_path])
		save_store()


func get_path():
	return get_store_path()

func get_store_path():  # allows overriding
	return self.filepath


func get_store():
	return __file


func save():
	save_store()

func save_store():
	if is_in_standalone():
		return
	var used_store_path = get_store_path()
	var saved = __file.save(used_store_path)
	if OK != saved:
		printerr("[%s] Cannot save store at `%s'." % [name, used_store_path])


func set_value(section: String, key: String, value):
	__file.set_value(section, key, value)
	save_store()


func get_value(section: String, key: String, default = null):
	return __file.get_value(section, key, default)


func is_in_standalone() -> bool:
	return OS.has_feature("standalone")


