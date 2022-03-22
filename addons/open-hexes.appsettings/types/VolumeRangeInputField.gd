extends AppSettingsRangeInput
class_name AppSettingsVolumeRangeInput


func get_bus_name() -> String:
	return 'Master'


func apply_value(value):
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(get_bus_name()),
		AppSettings.setting_to_db(value)
	)
	if (OS.has_feature("HTML5")) and (get_bus_name() == "Music"):
		if AudioManager.audios_list_names.has("ogg"):
			var v = (-1.0 + value/100.0)* 34.5
			AudioManager.update_config({'volume': str(v)}, "ogg")

