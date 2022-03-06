extends AppSettingsGenericInput
class_name AppSettingsSelectInput


func on_ready():
	var _c = self.connect("item_selected", self, "on_item_selected", [ setting ])
	var settingValue = AppSettings.get_setting(setting.section, setting.category, setting.setting)
	var i := 0
	var meta := AppSettings.get_setting_meta(setting.section, setting.category, setting.setting)
	if meta and meta.has('options'):
		for option in meta["options"]:
			if str(settingValue) == str(option.value):
				break
			i += 1
	self.selected = i


func on_item_selected(id, setting):
	var meta = AppSettings.get_setting_meta(
		setting.section,
		setting.category,
		setting.setting
	)
	if not meta or not meta.has('options'):
		return
	var value = meta["options"][id]["value"]
	AppSettings.set_setting(
		setting.section,
		setting.category, 
		setting.setting,
		value
	)
	AppSettings.save_to_file()
	apply_value(value)


