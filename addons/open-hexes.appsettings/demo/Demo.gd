extends Control

func _ready():
#	print(OS.get_executable_path())
#	print(ProjectSettings.get_setting("application/config/project_settings_override"))
#	print(ProjectSettings.get_setting("display/window/size/fullscreen"))
#	print(ProjectSettings.globalize_path(ProjectSettings.get_setting("application/config/project_settings_override")))
#	print(File.new().file_exists(ProjectSettings.globalize_path(ProjectSettings.get_setting("application/config/project_settings_override"))))
	AppSettings.register_metadata({
		'video': {
			'screen': {
				'fullscreen': {
					'title': "Fullscreen",
					'type': 'boolean',
					'default': false,
#					'script': 'res://mything.gd'
					# Both are checked
					# 'res://appsettings/settings/video/screen/fullscreen.gd'
					# 'res://addons/open-hexes.appsettings/presets/default/video/screen/fullscreen.gd'
				},
				'resolution': {
					'title': "Resolution",
					'type': "select",
					'options': [
						{
							'title': '800x600',
							'value': Vector2(800, 600),
						},
						{
							'title': '1024x768',
							'value': Vector2(1024, 768),
						},
						{
							'title': '1280x1024',
							'value': Vector2(1280, 1024),
						},
					],
					'default': Vector2(1024, 768),
				},
				'vsync': {
					'title': "Vertical Sync",
					'hint': "Requires reboot of The Internet Box©",
					'type': 'boolean',
					# Synchronize this app setting with the project setting
					'project': 'display/window/vsync/use_vsync',
				},
			},
			
		},
		"audio":{
			"volume":{
				"master": {
					"title": "Master\nVolume",
					"type": "range",
					"minimum": 0,
					"maximum": 100,
					"step": 1,
					"default": 40,
				},
				"music": {
					"title": "Music\nVolume",
					"type": "range",
					"minimum": 0,
					"maximum": 100,
					"step": 1,
					"default": 40,
				},
				"interface": {
					"title": "Interface\nVolume",
					"type": "range",
					"minimum": 0,
					"maximum": 100,
					"step": 1,
					"default": 40,
				},
				"effects": {
					"title": "Effects\nVolume",
					"type": "range",
					"minimum": 0,
					"maximum": 100,
					"step": 1,
					"default": 40,
				},
			},
		},
		"audio3":{
			"volume":{
				"master": {
					"title": "Master\nVolume",
					"type": "range",
					"minimum": 0,
					"maximum": 100,
					"step": 1,
					"default": 40,
				},
				"music": {
					"title": "Music\nVolume",
					"type": "range",
					"minimum": 0,
					"maximum": 100,
					"step": 1,
					"default": 40,
				},
				"interface": {
					"title": "Interface\nVolume",
					"type": "range",
					"minimum": 0,
					"maximum": 100,
					"step": 1,
					"default": 40,
				},
				"effects": {
					"title": "Effects\nVolume",
					"type": "range",
					"minimum": 0,
					"maximum": 100,
					"step": 1,
					"default": 40,
				},
			},
		},
	})
	AppSettings.load_from_file()
	AppSettings.apply()
	
	$Panel/SettingsButton.grab_focus()


# AppSettingsPackerOptions is sometimes not available
# Weird class_name shenanigans...  Let's preload,  it works.
const PackerOptions = preload("res://addons/open-hexes.appsettings/presets/PackerOptions.gd")


func _on_Button_pressed():
	var button = $Panel/SettingsButton
	var container = $Panel/SettingsContainer/SettingsWrapper
	if 0 == container.get_child_count():
#		var settings_config = AppSettingsPackerOptions.new()
		var settings_config = PackerOptions.new()
#		settings_config.columns = 2
		var settings_scene = AppSettings.pack_scene(settings_config)
		
		
		# II.a We could do that, but the settings scene is raw on purpose
		# (no "back" button, no panel → perhaps a panel may optionally appear)
		#get_tree().change_scene_to(settings_scene)
		# II.b Let's swap instead
		var settings_scene_instance = settings_scene.instance()
		# we tried to get a sane rect_size.y, to no avail
#		settings_scene_instance.rect_size = Vector2.ZERO
		container.add_child(settings_scene_instance)
#		settings_scene_instance.rect_size = Vector2.ZERO
#		settings_scene_instance.minimum_size_changed()
#		settings_scene_instance.margin_left = 0.0
#		settings_scene_instance.margin_top = 0.0
#		settings_scene_instance.margin_right = 0.0
#		settings_scene_instance.margin_bottom = 0.0
#		settings_scene_instance.minimum_size_changed()
#		settings_scene_instance.rect_size = Vector2.ZERO
		
#		container.rect_min_size.y = 700
#		var ssis = settings_scene_instance.rect_size
#		print("ssis", ssis)
#		container.rect_min_size.y = ssis.y
		container.rect_min_size.y = settings_scene_instance.get_meta("maximum_height")
		
		# III. Save the scene and open it in the editor for some post-process, perhaps
#		ResourceSaver.save("res://addons/open-hexes.appsettings/demo/settings.tscn", settings_scene)
		
		button.text = tr("BACK")
	else:
		for child in container.get_children():
			child.queue_free()
		button.text = tr("Settings")
	
