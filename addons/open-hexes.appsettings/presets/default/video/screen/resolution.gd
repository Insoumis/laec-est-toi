extends AppSettingsSelectInput


func apply_value(value):
	OS.window_size = value
	AppSettings.set_project_setting("display/window/size/width", value.x)
	AppSettings.set_project_setting("display/window/size/height", value.y)

