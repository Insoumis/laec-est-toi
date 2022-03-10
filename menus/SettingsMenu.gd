extends Control


const PackerOptions = preload("res://addons/open-hexes.appsettings/presets/PackerOptions.gd")


onready var back_button = find_node('BackButton')
onready var settings_container = find_node('AppSettingsScroll')


func _ready():
	var settings_config = PackerOptions.new()
#	settings_config.columns = 2
	var settings_scene = AppSettings.pack_scene(settings_config).instance()
	
	settings_container.add_child(settings_scene)
	
	# This layout config should probably go into AppSettings instead
	settings_scene.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Old, dirty undies
#	settings_container.rect_min_size.y = settings_scene.get_meta("maximum_height") + 200


func _input(_event):
	if Input.is_action_just_pressed("undo"):
		var _gone = Game.go_back(true, true)
	if Input.is_action_just_pressed("escape"):
		var _gone = Game.go_back(true, false)


func _on_BackButton_pressed():
	var _gone = Game.go_back()


func _on_ControlsButton_pressed():
	SoundFx.play("gui_select")
	#InputMapper.log_level = InputMapper.LOG_LEVEL_DEBUG
	Game.switch_to_scene_path("res://menus/InputMapperMenu.tscn")


func _on_SettingsMenu_visibility_changed():
	back_button.grab_focus()


func _on_OpenDirButton_pressed():
	var directory := OS.get_user_data_dir()
	var opened := OS.shell_open(directory)
	print("Trying to open the user data directory at `%s'." % directory)
	if OK != opened:
		printerr("Cannot open user data directory.")

