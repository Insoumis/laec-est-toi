extends AppSettingsBooleanInput


func on_ready():
	.on_ready()
#	prints("Fullscreen is", OS.window_fullscreen)


#func on_check_button_toggled(pressed, setting):
#	.on_check_button_toggled(pressed, setting)
#	apply_state(pressed, setting)
#	OS.window_fullscreen = pressed
#	prints("Fullscreen becomes", OS.window_fullscreen)


func apply_value(value):
	OS.window_fullscreen = value
	AppSettings.set_project_setting("display/window/size/fullscreen", value)
#	ProjectSettings.set_setting("display/window/size/fullscreen", value)
#	ProjectSettings.save_custom("user://settings.godot")

