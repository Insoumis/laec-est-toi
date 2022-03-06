extends AppSettingsRangeInput
class_name AppSettingsVolumeRangeInput


func get_bus_name() -> String:
	return 'Master'


func apply_value(value):
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(get_bus_name()),
		AppSettings.setting_to_db(value)
	)

