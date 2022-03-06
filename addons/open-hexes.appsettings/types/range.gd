extends AppSettingsGenericInput
class_name AppSettingsRangeInput


func on_ready():
	var error = connect("value_changed", self, "on_value_changed", [self.setting])
	var setting_value = AppSettings.get_setting(
		self.setting.section,
		self.setting.category,
		self.setting.setting
	)
	if null != setting_value:
		self.value = setting_value


func on_value_changed(value, setting):
	AppSettings.set_setting(
		setting.section,
		setting.category,
		setting.setting,
		value
	)
	AppSettings.save_to_file()
	apply_value(value)

