extends Node
 
#
#     /\
#    /  \   _ __  _ __
#   / /\ \ | '_ \| '_ \
#  / ____ \| |_) | |_) |
# /_/    \_\ .__/| .__/
#          | |   | |
#          |_|   |_|
# 
# 
# Handles Application logic.
# 
# - Window
#   - Closing
#   - Fullscreen Toggle
# - Settings
# - …
# 
# Meant to be used as a Godot Singleton.
# 


# Properties in project settings we're not letting users customize
# When we merge source and user configs, we always prefer the source, for these.
# Am I documenting this right, @Adrenesis?
var exclude_list = [
	"",
	"autoload",
	"editor_plugins",
	"WAT",
	"application"
]



func _ready():
	boot()


func boot():
	var loaded := verify_autoloads()
	if OK != loaded:
		rewrite_user_project_settings()
	init_settings()



#                _        _                 _
#     /\        | |      | |               | |
#    /  \  _   _| |_ ___ | | ___   __ _  __| |___
#   / /\ \| | | | __/ _ \| |/ _ \ / _` |/ _` / __|
#  / ____ \ |_| | || (_) | | (_) | (_| | (_| \__ \
# /_/    \_\__,_|\__\___/|_|\___/ \__,_|\__,_|___/
#
#


func is_autoload_loadable(autoload_name, autoload_script_path) -> bool:
	autoload_script_path = autoload_script_path.split("*", false)[0]
	#print(autoload_script_path)
	var autoloaded = load(autoload_script_path)
	if autoloaded:
		#print("App: autoload ", autoload_name, " loaded succesfully.")
		return true
	else:
		printerr("App: autoload ", autoload_name, " failed to load.")
		OS.set_window_fullscreen(false)
		OS.alert(
			"Autoload `%s' couldn't be loaded at `%s'" % [autoload_name, autoload_script_path],
			"Failed to load `%s'" % autoload_name
		)
		quit()
		return false


func verify_autoloads() -> int:
	var loaded := OK
	for setting in ProjectSettings.get_property_list():
		if setting.name.begins_with("autoload"):
			var setting_name = setting.name.replace("autoload/", "")
			var autoload_script_path : String = ProjectSettings.get_setting(setting.name)

			if autoload_script_path:
				if not is_autoload_loadable(setting_name, autoload_script_path):
					loaded = ERR_PARSE_ERROR
	return loaded



#  _____           _           _      _____      _   _   _
# |  __ \         (_)         | |    / ____|    | | | | (_)
# | |__) | __ ___  _  ___  ___| |_  | (___   ___| |_| |_ _ _ __   __ _ ___
# |  ___/ '__/ _ \| |/ _ \/ __| __|  \___ \ / _ \ __| __| | '_ \ / _` / __|
# | |   | | | (_) | |  __/ (__| |_   ____) |  __/ |_| |_| | | | | (_| \__ \
# |_|   |_|  \___/| |\___|\___|\__| |_____/ \___|\__|\__|_|_| |_|\__, |___/
#                _/ |                                             __/ |
#               |__/                                             |___/


func clean_and_save_project_settings(config, file_path):
	# CLEANING AND SAVING PROJECTSETTINGS TO USER FOLDER
	for section_to_be_removed in exclude_list:
		if config.has_section(section_to_be_removed):
			config.erase_section(section_to_be_removed)

	for section in config.get_sections():
#		print("setting section written: \"", section, "\"")
		pass
	var saved = config.save(file_path)
	if OK != saved:
		printerr("Failed to save project settings to `%s'." % file_path)
	return saved


func rewrite_user_project_settings():
	var config := ConfigFile.new()
	var saved : int
	var _loaded = config.load("res://project.godot")
	saved = clean_and_save_project_settings(config, "user://settings.godot")
	if OK != saved:
		if not OS.has_feature("HTML5"):
			printerr("Couldn't rewrite ", ProjectSettings.globalize_path("user://settings.godot"))
	else:
		OS.set_window_fullscreen(false)
		OS.alert("LAEC IS YOU couldn't load, but tried to apply a fix.\n" +
				"LAEC IS YOU now needs to be restarted",
				"Please restart the game")


# __          ___           _
# \ \        / (_)         | |
#  \ \  /\  / / _ _ __   __| | _____      __
#   \ \/  \/ / | | '_ \ / _` |/ _ \ \ /\ / /
#    \  /\  /  | | | | | (_| | (_) \ V  V /
#     \/  \/   |_|_| |_|\__,_|\___/ \_/\_/
#


func quit() -> void:
	get_tree().quit()


func exit() -> void:
	quit()


func is_fullscreen() -> bool:
	return OS.window_fullscreen


func toggle_fullscreen() -> void:
	OS.window_fullscreen = not OS.window_fullscreen


#   _____      _   _   _
#  / ____|    | | | | (_)
# | (___   ___| |_| |_ _ _ __   __ _ ___
#  \___ \ / _ \ __| __| | '_ \ / _` / __|
#  ____) |  __/ |_| |_| | | | | (_| \__ \
# |_____/ \___|\__|\__|_|_| |_|\__, |___/
#                               __/ |
#                              |___/


func init_settings():
	var AppSettingsLauncher = load("res://singletons/AppSettingsLauncher.gd")
	if not AppSettingsLauncher:
		printerr("Couldn't load AppSettingsLauncher")
	else:
		var appsl = AppSettingsLauncher.new()
		appsl.launch()
	
	


#   _____           _
#  / ____|         | |
# | (___  _   _ ___| |_ ___ _ __ ___
#  \___ \| | | / __| __/ _ \ '_ ` _ \
#  ____) | |_| \__ \ ||  __/ | | | | |
# |_____/ \__, |___/\__\___|_| |_| |_|
#          __/ |
#         |___/


func get_unique_device_id():
	return OS.get_unique_id()


#  _    _ _   _ _
# | |  | | | (_) |
# | |  | | |_ _| |___
# | |  | | __| | / __|
# | |__| | |_| | \__ \
#  \____/ \__|_|_|___/
#


# https://godotengine.org/qa/8024/update-dictionary-method
static func merge_dict(dest, source):
	for key in source:
		if dest.has(key):
			var dest_value = dest[key]
			var source_value = source[key]
			if typeof(dest_value) == TYPE_DICTIONARY:
				if typeof(source_value) == TYPE_DICTIONARY:
					merge_dict(dest_value, source_value)
				else:
					dest[key] = source_value
			else:
				dest[key] = source_value
		else:
			dest[key] = source[key]


