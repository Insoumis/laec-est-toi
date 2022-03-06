extends AppSettingsGenericInput
class_name AppSettingsBooleanInput
#class_name AppSettingsBooleanField
#class_name AppSettingsCheckButton


func on_ready():
	var error = connect("toggled", self, "on_check_button_toggled", [setting])
	var settingValue = AppSettings.get_setting(setting.section, setting.category, setting.setting)
	if null == settingValue:
		breakpoint  # default should prevail
		return
	self.pressed = settingValue


func on_check_button_toggled(pressed, setting):
	AppSettings.set_setting(setting.section, setting.category, setting.setting, pressed)
	AppSettings.save_to_file()
	apply_value(pressed)

