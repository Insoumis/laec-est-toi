tool
extends Node

#                       _____      _   _   _
#     /\               / ____|    | | | | (_)
#    /  \   _ __  _ __| (___   ___| |_| |_ _ _ __   __ _ ___
#   / /\ \ | '_ \| '_ \\___ \ / _ \ __| __| | '_ \ / _` / __|
#  / ____ \| |_) | |_) |___) |  __/ |_| |_| | | | | (_| \__ \
# /_/    \_\ .__/| .__/_____/ \___|\__|\__|_|_| |_|\__, |___/
#          | |   | |                                __/ |
#          |_|   |_|                               |___/
# 
# I. Register your settings metadata
# I.a Register common settings metadata
# I.b Register custom settings metadata
# II. Enjoy
# II.a Access settings values
#      `AppSettings.get_setting(…)`
# II.b Generate settings menu UI
#      `AppSettings.pack_scene(…)`
# II.c Override logic by putting a GdScript in some location
# 
# This needs more love:
# - A way to set and translate sections' titles
# - settings_metadata.json ?


# Using preload() instead of class_name shenanigans,
# because of cyclic deps resolution.
const AppSettingsTypeFactory = preload( \
	"res://addons/open-hexes.appsettings/types/type_factory.gd" \
)


# See the demo for an example for now (copy example here once appropriate)
# <section>: <category>: <setting>: {}
var metadata := Dictionary()


# Values of the settings, stored in the file described below.
# Prefer using accessors over this property directly.
# It's multidimensional: <section>: <category>: <setting>: {}
var __settings := Dictionary()


# Actual settings' values for each setting defined in metadata.
# This HAS TO be somewhere in the `user://` space.
var settings_path := "user://settings.json"
# Registered metadata is stored in there.
var metadata_path := "res://settings_metadata.json"
# This value ought to be set in project's settings at:
# application/config/project_settings_override
# Perhaps the EditorPlugin will handle that ?
var project_settings_path := "user://settings.godot"
var project_settings_path_temp := "user://settingstmp.godot"
# Project's directory where to look for override scripts.
var settings_dir := "res://appsettings/settings"

var last_saved_migration_resource : MigrationData
var current_migration_resource : MigrationData




# Not sure we should do this here, at least not without a way to disable it
#func _init():
#	apply()

#func _init():
func _ready():
	print("AppSettings: Readying…")
	load_and_apply_migrations()


func boot(with_metadata:Dictionary) -> void:
	register_metadata(with_metadata)
	load_from_file()
	apply()


func register_metadata(additional_metadata:Dictionary) -> void:
	if not is_metadata_valid(additional_metadata):
		printerr("Metadata is invalid:")
		print(additional_metadata)
		printerr("The keys MUST NOT include the `/` character.")
	merge_dicts(self.metadata, additional_metadata)


# class_name cyclic shenanigans
#func pack_scene(config:AppSettingsPackerOptions) -> PackedScene:
func pack_scene(config) -> PackedScene:
	var scene := PackedScene.new()
	
	var container = HBoxContainer.new()
	container.set_name("AppSettingsContainer")
	container.anchor_left = 0.0
	container.anchor_top = 0.0
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	container.margin_left = 0.0
	container.margin_top = 0.0
	container.margin_right = 0.0
	container.margin_bottom = 0.0
	
	var columns := Array()
	for column_id in range(config.columns):
#		var column = GridContainer.new()
		var column = VBoxContainer.new()
		column.set_name("AppSettingsColumn%d" % column_id)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.size_flags_vertical = Control.SIZE_EXPAND
		columns.append(column)
	
	var column_id := 0
	var current_column = columns[column_id]
	var current_column_height := 0.0  # in pixels
	var maximum_column_height := 0.0  # in pixels
	var amount_of_settings := 0
	var sl = get_settings_list()
	for setting in get_settings_list():
		assert(setting.has('type'), "Property 'type' is required in setting metadata.  Use 'boolean', 'range', or 'select'.")
		if not setting.has('type'):
			continue
		var type = setting['type']
		var setting_factory = get_setting_factory(setting)
		if not setting_factory:
			continue
		
		amount_of_settings += 1
		
		var setting_hbox = HBoxContainer.new()
		setting_hbox.set_name(setting_to_name(setting))
		
		var left_gap = Control.new()
		left_gap.set_name("LeftGap")
		left_gap.size_flags_horizontal = Control.SIZE_FILL
		
		var label_field = setting_factory.create_label_field(setting)
		label_field.set_name('LabelField')
		var input_field = setting_factory.create_input_field(setting)
		input_field.set_name('InputField')
		
		var inner_gap = Control.new()
		inner_gap.set_name("InnerGap")
		inner_gap.rect_min_size.x = config.inner_gap_width
		
		if not config.flex:
			label_field.rect_min_size.x = config.label_width
			input_field.rect_min_size.x = config.input_width
		setting_hbox.rect_min_size.y = config.row_height
#		label_field.rect_min_size.y = 42  # no, see below
		input_field.rect_min_size.y = config.row_height
		
#		label_field.fit_content_height = true
		label_field.align = Label.ALIGN_RIGHT
		label_field.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		label_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label_field.size_flags_stretch_ratio = config.text_to_button_ratio
		
		current_column_height += config.row_height
#		current_column_height += label_field.rect_size.y  #  == 0

		input_field.script = self.get_input_field_script(setting)
		input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		setting_factory.init_input_field_script(input_field, setting)
		
		setting_hbox.add_child(left_gap)
		setting_hbox.add_child(label_field)
		setting_hbox.add_child(inner_gap)
		setting_hbox.add_child(input_field)
		current_column.add_child(setting_hbox)
		
		column_id = (column_id + 1) % columns.size()
		maximum_column_height = max(maximum_column_height, current_column_height)
		current_column_height = 0.0
		current_column = columns[column_id]
	
	# Since we're packin', the owner must be set.
	for column in columns:
		container.add_child(column)
		set_owner_recursively(column, container)  # property is theft
	
	# Since the rect_size.y is 3251 px and we can't figure out why,
	# let's crutch it and store the expected pixel height in meta.
	# This value becomes wrong if labels effect newline feeds
	# We're not using this metadata anymore anyway.
	container.set_meta(
		"maximum_height",
		config.row_height * (amount_of_settings + 2)  # +2 is padding
		/
		config.columns
	)
	
	scene.pack(container)
	
	return scene


func get_setting_meta(section:String, category:String, setting:String) -> Dictionary:
	if not self.metadata.has(section):
		return {}
	if not self.metadata[section].has(category):
		return {}
	if not self.metadata[section][category].has(setting):
		return {}
	
	return self.metadata[section][category][setting]


#func get_setting_value:
#func get_value:
func get_setting(section:String, category:String, setting:String, default=null):
	if not self.__settings.has(section):
		return get_default_setting(section, category, setting, default)
	if not self.__settings[section].has(category):
		return get_default_setting(section, category, setting, default)
	if not self.__settings[section][category].has(setting):
		return get_default_setting(section, category, setting, default)
	
	return self.__settings[section][category][setting]


func get_default_setting(section:String, category:String, setting:String, default=null):
	if null != default:
		return default
	
	if not self.metadata.has(section):
		return null
	if not self.metadata[section].has(category):
		return null
	if not self.metadata[section][category].has(setting):
		return null
	if self.metadata[section][category][setting].has('default'):
		return self.metadata[section][category][setting]['default']

	if self.metadata[section][category][setting].has('project'):
		var project = self.metadata[section][category][setting]['project']
		assert(typeof(project) == TYPE_STRING)
		# todo @adrenesis handle arrays of strings and arrays of dicts
		return ProjectSettings.get_setting(project)

	return null


func set_setting(section:String, category:String, setting:String, value):
	set_value_in_dict(self.__settings, [section, category, setting], value)
	save_to_file()
	var project = get_value_from_dict(self.metadata, [section, category, setting, 'project'])
	if project:
#		print("project setting set: ", section, " ", category, " ", setting)
		assert(typeof(project) == TYPE_STRING)  # hahaha, so simple
		set_project_setting(project, value)



func apply_set_migration(key: String, built_config : ConfigFile, loaded_config : ConfigFile) -> int:
	var setting_path_array = key.split("/", false)
	if setting_path_array.size() > 0:
		var slashed_setting_key = key.replace(setting_path_array[0] + "/", "")
		# not useful as set_value create sections
		# if loaded_config.has_section(setting_path_array[0]):
		var value = built_config.get_value(setting_path_array[0], slashed_setting_key, null)
		if value == null:
#			print("Migration reading setting ", setting_path_array[0] + "/" + slashed_setting_key, " from ProjectSettings")
			value = ProjectSettings.get_setting(setting_path_array[0] + "/" + slashed_setting_key)
			if value == null:
				return ERR_DOES_NOT_EXIST
		loaded_config.set_value(setting_path_array[0], slashed_setting_key, value)
		return OK
	else:
		return ERR_FILE_UNRECOGNIZED

func apply_erase_migration(key: String, built_config : ConfigFile, loaded_config : ConfigFile) -> int:
	var setting_path_array = key.split("/", false)
	if setting_path_array.size() > 0:
		var slashed_setting_key = key.replace(setting_path_array[0] + "/", "")
		# not useful as set_value create sections
		# if loaded_config.has_section(setting_path_array[0]):
		if built_config.has_section_key(setting_path_array[0], slashed_setting_key):
			built_config.erase_section_key(setting_path_array[0], slashed_setting_key)
		return OK
	else:
		return ERR_DOES_NOT_EXIST

func apply_migrations(migration_data_array : Array, built_config : ConfigFile, loaded_config : ConfigFile):
	for migration_datum in migration_data_array:
		if migration_datum.purge:
			loaded_config = built_config.duplicate(true)
		else:
			for created_key in migration_datum.created:
				var error = apply_set_migration(created_key, built_config, loaded_config)
				if OK != error:
					printerr("Migration: Couldn't find section name in setting ", created_key, " to create.")
			for updated_key in migration_datum.updated:
				var error = apply_set_migration(updated_key, built_config, loaded_config)
				if OK != error:
					printerr("Migration: Couldn't find section name in setting ", updated_key, " to update.")
			for erased_key in migration_datum.erased:
				var error = apply_erase_migration(erased_key, built_config, loaded_config)
				if OK != error:
					printerr("Migration: Couldn't find section name in setting ", erased_key, " to erase.")
			for renamed_datum in migration_datum.renamed:
				var error = apply_erase_migration(renamed_datum.old_name, built_config, loaded_config)
				if OK != error:
					printerr("Migration: Couldn't find section name in setting ", renamed_datum.old_name, " to rename from.")
				error = apply_set_migration(renamed_datum.new_name, built_config, loaded_config)
				if OK != error:
					printerr("Migration: Couldn't find section name in setting ", renamed_datum.new_name, " to rename to.")
				


const CURRENT_MIGRATION_DATA = preload("res://SettingsMigrationData.tres")
const USER_MIGRATION_DATA_PATH = "user://SettingsMigrationData.json"
# BY PLATFORM:
# On WINDOWS/LINUX?/MAXOS: user:// can be accessed, 
## should act like a traditionnal save with a migration flag
# On HTML5: user:// CANNOT be accessed, 
## should load exported res://project.godot
# On ANDROID: ????????
## should ????????

func load_built_project_settings_with_fallbacks(out_config:ConfigFile):
	var loaded : int
	loaded = out_config.load("res://project.godot")
	var saved
	if OK != loaded:
		# LOADING project.godot FAILED, PROBABLY AN EXPORT ISSUE
		printerr("Can't load project setting from res://project.godot, check exported file on build")
		printerr("Trying a fallback....")
		# SAVING TEMPORARY PROJECTSETTINGS TO RELOAD IT AS CONFIG FILE
		saved = ProjectSettings.save_custom(self.project_settings_path_temp)
		if OK != saved:
			printerr("Failed to save project settings to `%s'." % self.project_settings_path_temp)
		loaded = out_config.load(self.project_settings_path_temp)
		if OK != loaded:
			printerr("Failed to read project settings to `%s'." % self.project_settings_path_temp)
	return loaded

func set_project_setting(setting_path:String, value):
	print("AppSettings: Setting `%s' to `%s'." % [setting_path, str(value)])
	if not ProjectSettings.has_setting(setting_path):
		printerr("Unknown project setting `%s'." % setting_path)
		return
	ProjectSettings.set_setting(setting_path, value)
	
	var loaded_config = load_and_apply_migrations()
	var setting_path_array = setting_path.split("/", false)
	var slashed_setting_key = setting_path.replace(setting_path_array[0] + "/", "")
	loaded_config.set_value(setting_path_array[0], slashed_setting_key, value)
	App.clean_and_save_project_settings(loaded_config, self.project_settings_path)

func load_and_apply_migrations() -> ConfigFile:
	var loaded : int
	var saved : int
	var built_project_settings_config = ConfigFile.new()
	var loaded_config := ConfigFile.new()
	var saved_migration := MigrationData.new()
	if OS.has_feature("standalone") and (not Engine.is_editor_hint()):
		print("AppSettings: Loading ProjectSettings from user://")
		# NORMAL LOADING FORM USER FOLDERS
		loaded = loaded_config.load(self.project_settings_path)
	if (OK != loaded) or (not OS.has_feature("standalone")) or Engine.is_editor_hint():
		print("AppSettings: Saving all user ProjectSettings")
		# NORMAL LOADING CRASHED, REWRITING SETTINGS FROM BUILD PROJECTSETTINGS...
		loaded = load_built_project_settings_with_fallbacks(loaded_config)
		clean_and_save_project_settings(loaded_config, self.project_settings_path)
		loaded = load_migration_from_file(saved_migration)
		if OK != loaded:
			# Migrate everything?
			print("Migration data not found, rewriting...")
			saved = save_migration_data_to_file(CURRENT_MIGRATION_DATA)
	else:
		loaded = load_built_project_settings_with_fallbacks(built_project_settings_config)
		if OK != loaded:
			# error already should have been printed, pragma to acknowledge
			pass
		var current_migration = CURRENT_MIGRATION_DATA
		loaded = load_migration_from_file(saved_migration)
		if OK != loaded:
			# Migrate everything?
			print("Migration data not found, rewriting...")
			saved = save_migration_data_to_file(CURRENT_MIGRATION_DATA)
			print("Migration: Applying all migrations")
			apply_migrations(CURRENT_MIGRATION_DATA.migration_version_array, built_project_settings_config, loaded_config)
			if OK != saved:
				if not OS.has_feature("HTML5"):
					printerr("Can't write migration data file at ", USER_MIGRATION_DATA_PATH)
			else:
				print("Migration: Migration applied")
		else:
			if (
				saved_migration.current_version_string == ""
			) or (
				saved_migration.current_version_string < current_migration.current_version_string
			):
				if saved_migration.current_version_string == "":
					apply_migrations(current_migration.migration_version_array, built_project_settings_config, loaded_config)
				else:
					if saved_migration.migration_version_array.size() < 1:
						apply_migrations(current_migration.migration_version_array, built_project_settings_config, loaded_config)
					else:
						var last_migrated_version = saved_migration.migration_version_array[(
							saved_migration.migration_version_array.size() - 1
							)].current_version_string
						var migration_data_to_apply = Array()
						for migration_datum in current_migration.migration_version_array:
							if migration_datum.current_version_string > last_migrated_version:
								migration_data_to_apply.append(migration_datum)
						apply_migrations(migration_data_to_apply, built_project_settings_config, loaded_config)
	return loaded_config



# Carbon Copy of the one in App  (trying to hunt a bug)
func clean_and_save_project_settings(config, file_path):
	# CLEANING AND SAVING PROJECTSETTINGS TO USER FOLDER
	for section_to_be_removed in App.EXCLUDE_LIST:
		if config.has_section(section_to_be_removed):
			config.erase_section(section_to_be_removed)

	for section in config.get_sections():
#		print("setting section written: \"", section, "\"")
		pass
	var saved = config.save(file_path)
	if OK != saved:
		printerr("Failed to save project settings to `%s'." % file_path)
	return saved



func apply():
	"""
	Trigger the apply_value() method on each setting with `initialize` set to true.
	Useful on app startup to set main sound volume for example.
	"""
	for setting in get_settings_list():
		assert(setting.has('type'), "Property 'type' is required in setting metadata.  Use 'boolean', 'range', or 'select'.")
		if not setting.has('type'):
			continue
		var type = setting['type']
		if not setting.has('initialize'):
			continue
		elif not setting['initialize']:
			continue
		var setting_script = get_input_field_script(setting)
		var setting_script_instance = setting_script.new()
		setting_script_instance.setting = setting
		setting_script_instance.apply_value(
			get_setting(
				setting.section,
				setting.category,
				setting.setting
			)
		)


#  _____       _                        _
# |_   _|     | |                      | |
#   | |  _ __ | |_ ___ _ __ _ __   __ _| |___
#   | | | '_ \| __/ _ \ '__| '_ \ / _` | / __|
#  _| |_| | | | ||  __/ |  | | | | (_| | \__ \
# |_____|_| |_|\__\___|_|  |_| |_|\__,_|_|___/
#
# Protected or private stuff, mostly.


func is_metadata_valid(data:Dictionary) -> bool:
	for key in data:
		if not is_setting_key_valid(key):
			return false
		if typeof(data[key]) == TYPE_DICTIONARY:
			if not is_metadata_valid(data[key]):
				return false
	return true


func is_setting_key_valid(key:String) -> bool:
	var valid := true
	if key.count('/'):
		return false
	return valid


func load_from_file() -> int:
	var file := File.new()
	var opened := file.open(self.settings_path, File.READ)
	if OK != opened:
		printerr("Cannot open settings file at `%s`." % [self.settings_path])
		printerr("This is expected if this is the first run and settings have not been tweaked yet.")
		return opened
	
	var json_text := file.get_as_text()
	file.close()
	var json := JSON.parse(json_text)

	if OK == json.error:
		self.__settings = build_settings_from_metadata()
		merge_dicts(self.__settings, json.result)
	else:
		printerr("Error loading JSON settings: %s at line %d." % [
			json.error_string,
			json.error_line
		])
	return json.error


func save_to_file() -> int:
	var file := File.new()
	var opened := file.open(self.settings_path, File.WRITE)
	if OK != opened:
		printerr("Cannot open settings file at `%s`." % [self.settings_path])
		return opened
	var json_text := JSON.print(self.__settings, "\t")
	file.store_string(json_text)
	file.close()
	return OK


func load_metadata_from_file() -> int:
	var result := Dictionary()
	var error = load_json(self.metadata_path, result)

	if OK == error:
		merge_dicts(self.metadata, result)

	return error

func load_migration_from_file(migration_data : MigrationData) -> int:
	var result := Dictionary()
	var error = load_json(USER_MIGRATION_DATA_PATH, result)
	if error == OK:
		migration_data.migration_version_array = Array()
		migration_data.current_version_string = result["current_version_string"]
		for datum_dict in result["migration_version_array"]:
			var datum = MigrationDatum.new()
			datum.version_string = datum_dict["version_string"]
			datum.created = datum_dict["created"] 
			datum.updated = datum_dict["updated"]
			datum.erased = datum_dict["erased"]
			datum.renamed = Array()
			for rename_datum_dict in datum_dict["renamed"]:
				var rename_datum := RenameDatum.new()
				rename_datum.old_name = rename_datum_dict["old_name"]
				rename_datum.new_name = rename_datum_dict["new_name"]
				datum.renamed.append(rename_datum.duplicate(true))
			datum.purge = datum_dict["purge"]
			migration_data.migration_version_array.append(datum)
	return error


static func load_json(path : String, to_dict : Dictionary):
	var file := File.new()
	var opened := file.open(path, File.READ)
	
	if OK != opened:
		print("Cannot open json file at `%s`." % [path])
		return opened

	var json_text := file.get_as_text()
	file.close()
	var json := JSON.parse(json_text)
	if OK == json.error:
#		self.__settings = build_settings_from_metadata()
#		to_dict = json.result
		for key in json.result.keys():
		# Sketchy
			if not (json.result[key] is String):
				to_dict[key] = json.result[key].duplicate(true)
			else:
				to_dict[key] = json.result[key]
	else:
		print("Can't load JSON : %s at line %d." % [
			json.error_string,
			json.error_line
		])
	return json.error


func save_metadata_to_file() -> int:
	var file := File.new()
	var opened := file.open(self.metadata_path, File.WRITE)
	if OK != opened:
		printerr("Cannot write settings file in `%s`." % [self.metadata_path])
		return opened
	var json_text := JSON.print(self.metadata, "\t")
	file.store_string(json_text)
	file.close()
	return OK

func save_migration_data_to_file(migration_data : MigrationData) -> int:
	var file := File.new()
	var opened := file.open(USER_MIGRATION_DATA_PATH, File.WRITE)
	var migration_data_dict := Dictionary()
	migration_data_dict["migration_version_array"] = Array()
	migration_data_dict["current_version_string"] = migration_data.current_version_string
	for datum in migration_data.migration_version_array:
		var datum_dict = Dictionary()
		datum_dict["version_string"] = datum.version_string
		datum_dict["created"] = datum.created
		datum_dict["updated"] = datum.updated
		datum_dict["erased"] = datum.erased
		datum_dict["renamed"] = Array()
		for rename_datum in datum.renamed:
			var rename_datum_dict = Dictionary()
			rename_datum_dict["old_name"] = rename_datum.old_name
			rename_datum_dict["new_name"] = rename_datum.new_name
			datum_dict["renamed"].append(rename_datum_dict.duplicate(true))
		datum_dict["purge"] = datum.purge
		migration_data_dict["migration_version_array"].append(datum_dict)
	if OK != opened:
		printerr("Cannot write settings file in `%s`." % [USER_MIGRATION_DATA_PATH])
		return opened
	var json_text := JSON.print(migration_data_dict, "\t")
	file.store_string(json_text)
	file.close()
	return OK

func build_settings_from_metadata():
	var settings := Dictionary()
	
	for section in get_sections():
		for category in get_categories(section):
			for setting in get_settings(section, category):
				var meta = self.metadata[section][category][setting]
				if not meta.has('default'):
					continue
				set_value_in_dict(settings, [section, category, setting], meta['default'])
	
	return settings


func set_owner_recursively(node:Node, new_owner:Node) -> void:
	node.set_owner(new_owner)
	for child in node.get_children():
		set_owner_recursively(child, new_owner)


func get_sections() -> Array: # of String
	var sections := Array()
	for section in self.metadata:
		if section.begins_with('_'):
			continue
		sections.append(section )
	return sections


func get_categories(section:String) -> Array: # of String
	assert(self.metadata.has(section))
	assert(typeof(self.metadata[section]) == TYPE_DICTIONARY)
	var categories := Array()
	for category in self.metadata[section]:
		if category.begins_with('_'):
			continue
		categories.append(category)
	return categories


func get_settings(section:String, category:String) -> Array: # of String
	var settings := Array()
	for setting in self.metadata[section][category]:
		if setting.begins_with('_'):
			continue
		settings.append(setting)
	return settings


func get_settings_list() -> Array: # of Dictionary
	var settings_list := Array()
	for section in get_sections():
		for category in get_categories(section):
			assert(typeof(self.metadata[section][category]) == TYPE_DICTIONARY)
			for setting in get_settings(section, category):
				var settingDictionary = self.metadata[section][category][setting].duplicate()
				settingDictionary.section = section
				settingDictionary.category = category
				settingDictionary.setting = setting
				settings_list.append(settingDictionary)
	return settings_list


func get_setting_factory(setting:Dictionary) -> AppSettingsTypeFactory:
	var type : String = 'boolean'
	if setting.has('type'):
		type = setting['type']

	var script_path := "res://addons/open-hexes.appsettings/types/%s_factory.gd" % type
	var script : GDScript
	
	if ResourceLoader.exists(script_path):
		script = load(script_path)
	
#	if 'boolean' == type:
#		script = preload("res://addons/open-hexes.appsettings/types/BooleanFactory.gd")
#	elif 'select' == type:
#		script = preload("res://addons/open-hexes.appsettings/types/SelectFactory.gd")
#	elif 'range' == type:
#		script = preload("res://addons/open-hexes.appsettings/types/RangeFactory.gd")
#	else:
#		printerr("Unknown type `%s'." % type)
#		breakpoint  # add the new type here
	
	if not script:
		printerr("Cannot load setting factory for %s" % str(setting))
		return null
	
	return script.new()


func get_input_field_script_lookup_paths(setting:Dictionary, template:String='default') -> Array:
	var keys = [
		template,
		setting.section,
		setting.category,
		setting.setting,
	]
	var paths = Array()
	if setting.has('script'):
		if ResourceLoader.exists(setting['script']):
			paths.append(setting['script'])
		else:
			printerr("Could not find script at path `%s' for setting %s." % [
				setting['script'], setting,
			])
	paths.append("%s/%s/%s/%s/%s.gd" % ([self.settings_dir] + keys))
	paths.append("res://addons/open-hexes.appsettings/presets/%s/%s/%s/%s.gd" % keys)
	paths.append("res://addons/open-hexes.appsettings/types/%s.gd" % [setting.type])
	return paths


func get_input_field_script(setting:Dictionary) -> GDScript:
	var loaded = load_with_fallback(get_input_field_script_lookup_paths(setting))
	if not loaded:
		breakpoint
		printerr("No script for input field of setting `%s'." % setting)
		return null  # or instance of type.gd?
	assert(loaded is GDScript)
	return loaded


static func get_dicts_common_values(target:Dictionary, patch:Dictionary, future_return = Array(), prefix = ""):
	for key in patch:
		if target.has(key):
			var tv = target[key]
			if typeof(tv) == TYPE_DICTIONARY:
				future_return = get_dicts_common_values(tv, patch[key], future_return, prefix + "/" + key)
				continue
			else:
				future_return += [ prefix + "/" + key ]
#				print(prefix + "/" + key)
	return future_return


static func are_dicts_having_common_values(target:Dictionary, patch:Dictionary, future_return = false):
	for key in patch:
		if target.has(key):
			var tv = target[key]
			if typeof(tv) == TYPE_DICTIONARY:
				future_return = are_dicts_having_common_values(tv, patch[key], future_return) or future_return
				continue
			else:
				return true
	return future_return
		

static func merge_dicts(target:Dictionary, patch:Dictionary, disable_replace_values := false, prefix := "", exclude_list = Array()) -> void:
	for key in patch:
		if target.has(key):
			var tv = target[key]
			if typeof(tv) == TYPE_DICTIONARY:
				merge_dicts(tv, patch[key], disable_replace_values, prefix + "/" + key, exclude_list)
				continue
			elif disable_replace_values:
				# skip replacing value if not in exclude list
				if exclude_list.find(prefix + "/" + key) == -1:
					continue
		
		target[key] = patch[key]


static func set_value_in_dict(target:Dictionary, keys:Array, value):
	assert(typeof(target) == TYPE_DICTIONARY)
	var key = keys.pop_front()
	if keys.empty():
		target[key] = value
	else:
		if not target.has(key):
			target[key] = Dictionary()
		set_value_in_dict(target[key], keys, value)


static func get_value_from_dict(target:Dictionary, keys:Array):
	assert(typeof(target) == TYPE_DICTIONARY)
	var key = keys.pop_front()
	if not target.has(key):
		return null
	if keys.empty():
		return target[key]
	else:
		return get_value_from_dict(target[key], keys)


static func setting_to_name(setting:Dictionary) -> String:
	return "%s%s%sSetting" % [
		setting['section'].capitalize().replace(' ', ''),
		setting['category'].capitalize().replace(' ', ''),
		setting['setting'].capitalize().replace(' ', ''),
	]


static func setting_to_db(setting_value):
	# We expect setting_value to be in range 0...100
	# Custom range, could perhaps be redone with linear2db()
	return setting_value * 0.6 - 60.0


# @semcom Orphan load_with_fallback
static func load_with_fallback(paths:Array):
	for path in paths:
		var file = File.new()
		if ResourceLoader.exists(path):  # two file reads?
			var loaded = load(path)
			if loaded:
				return loaded
			printerr("load_with_fallback: `%s' exists but failed to load" % path)

	printerr("load_with_fallback: all paths failed")
	prints("Paths", paths)
#	breakpoint
	return null
# ------------------------------------------------------------------------------
