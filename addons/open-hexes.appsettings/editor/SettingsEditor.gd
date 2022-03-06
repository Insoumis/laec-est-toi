tool
extends Control

var BooleanTexture = preload("res://addons/open-hexes.appsettings/editor/icon_check_box.svg")
var DirectoryTexture = preload("res://addons/open-hexes.appsettings/editor/Folder.svg")
var SaveTexture = preload("res://addons/open-hexes.appsettings/editor/icon_save_button.svg")
var SelectTexture = preload("res://addons/open-hexes.appsettings/editor/icon_option_button.svg")
var RangeTexture = preload("res://addons/open-hexes.appsettings/editor/icon_h_slider.svg")
var AddTexture = preload("res://addons/open-hexes.appsettings/editor/Add.svg")
var AddScriptTexture = preload("res://addons/open-hexes.appsettings/editor/ScriptCreate.svg")
var RemoveScriptTexture = preload("res://addons/open-hexes.appsettings/editor/ScriptRemove.svg")

var parent_plugin : Node
var fileDialog := FileDialog.new()

var container
var scrollContainer
var metadataContainer


var dictMerger

var DictMerger = preload("res://addons/open-hexes.appsettings/editor/DictMerger.gd")

var waiting_metadata = Dictionary()

func on_presets_file_opened(filePath : String):
	var file = File.new()
	if file.file_exists(AppSettings.metadata_path):
		var result = Dictionary()
		var error = AppSettings.load_json(filePath, result)
		if OK == error:
			var dict_similar = AppSettings.are_dicts_having_common_values(AppSettings.metadata, result)
			if dict_similar:
				waiting_metadata = result.duplicate()
				dictMerger = DictMerger.new()
				add_child(dictMerger)
				dictMerger.connect("replace_pressed", self, "on_merge_replace_pressed")
				dictMerger.connect("cancel_pressed", self, "on_merge_cancel_pressed")
				dictMerger.generate_merge_popup(
					AppSettings.get_dicts_common_values(AppSettings.metadata, result),
					AppSettings.metadata, result
				)
			else:
				AppSettings.merge_dicts(AppSettings.metadata, result)
				generate_main_screen_from_metadata()
	else:
		var dir = Directory.new()
		var copyErr = dir.copy(filePath, AppSettings.metadata_path)
		if OK != copyErr:
			printerr("""Could not load default metadata, check if 
			res://addons/open-hexes.appsetting/presets/default.json exists and if
			res:// settings_metadata.json is writable
			""")
		else:
			AppSettings.load_metadata_from_file()
			generate_main_screen_from_metadata()

func _enter_tree():
	self.anchor_right = 1.0
	self.anchor_bottom = 1.0
	self.margin_right = 0.0
	self.margin_bottom = 0.0
	self.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	self.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fileDialog = FileDialog.new()
	fileDialog.mode = FileDialog.MODE_OPEN_FILE
	fileDialog.access = FileDialog.ACCESS_RESOURCES
	fileDialog.current_path = "res://addons/open-hexes.appsettings/presets/"
	fileDialog.set_filters(PoolStringArray(["*.json ; JSON Files"]))
	add_child(fileDialog)
	fileDialog.connect("file_selected", self, "on_presets_file_opened")
	fileDialog.popup_exclusive = true
	var error = AppSettings.load_metadata_from_file()
#	if OK != error:
#		var dir = Directory.new()
#		var copyErr = dir.copy("res://addons/open-hexes.appsettings/presets/default.json", "res://settings_metadata.json")
#		if OK != copyErr:
#			printerr("""Could not load default metadata, check if 
#			res://addons/open-hexes.appsetting/presets/default.json exists and if
#			res:// settings_metadata.json is writable
#			""")
#	AppSettings.save_metadata_to_file()
	container = $VBoxContainer
	scrollContainer = ScrollContainer.new()
	metadataContainer = VBoxContainer.new()

	scrollContainer.add_child(metadataContainer)

	var header := HBoxContainer.new()
	var addPresetsButton = Button.new()
	var saveMetadataButton = Button.new()
	addPresetsButton.text = "Add settings from presets"
	saveMetadataButton.text = "Save Metadata"
	addPresetsButton.icon = DirectoryTexture
	saveMetadataButton.icon = SaveTexture
	header.add_child(addPresetsButton)
	header.add_child(saveMetadataButton)
	
	container.add_child(header)
	container.add_child(scrollContainer)
	
	addPresetsButton.connect("pressed", self, "on_add_presets_pressed")
	saveMetadataButton.connect("pressed", self, "on_save_metadata_pressed")
	generate_main_screen_from_metadata()

func clear_main_screen_metadata():
	for child in metadataContainer.get_children():
		child.queue_free()

func on_section_rename(text : String, lineEdit : LineEdit):
	
	var metadataDuplicate := Dictionary()
	var key = lineEdit.get_meta("section_key")
	var sectionContent = AppSettings.metadata[key].duplicate(true)
	for section in AppSettings.metadata.keys():
		if section == key:
			metadataDuplicate[text] = sectionContent.duplicate(true)
		else:
			metadataDuplicate[section] = AppSettings.metadata[section].duplicate(true)
	lineEdit.set_meta("section_key", text)
	AppSettings.metadata = Dictionary()
	AppSettings.metadata = metadataDuplicate.duplicate(true)
	
	#print(AppSettings.metadata)


func on_category_rename(text : String, lineEdit : LineEdit):
	#print(text)
	var metadataDuplicate : Dictionary
	#print(AppSettings.metadata)
	
	var section = lineEdit.get_meta("section_key")
	var editedCategory = lineEdit.get_meta("category_key")
	var categoryContent = AppSettings.metadata[section][editedCategory].duplicate(true)
	metadataDuplicate = Dictionary()
	for category in AppSettings.metadata[section].keys():
		if category == editedCategory:
			metadataDuplicate[text] = categoryContent.duplicate(true)
		else:
			metadataDuplicate[category] = AppSettings.metadata[section][category].duplicate(true)
	lineEdit.set_meta("category_key", text)
	AppSettings.metadata[section] = Dictionary()
	AppSettings.metadata[section] = metadataDuplicate.duplicate(true)
	

func on_setting_rename(text : String, lineEdit : LineEdit):
	#print(text)
	var metadataDuplicate : Dictionary
	#print(AppSettings.metadata)
	
	var section = lineEdit.get_meta("section_key")
	var category = lineEdit.get_meta("category_key")
	var editedSetting = lineEdit.get_meta("setting_key")
	var settingContent = AppSettings.metadata[section][category][editedSetting].duplicate(true)
	metadataDuplicate = Dictionary()
	for setting in AppSettings.metadata[section][category].keys():
		
		if setting == editedSetting:
			
			metadataDuplicate[text] = settingContent.duplicate(true)
		else:
			#print(setting)
			metadataDuplicate[setting] = AppSettings.metadata[section][category][setting].duplicate(true)
	lineEdit.set_meta("setting_key", text)
	AppSettings.metadata[section][category] = Dictionary()
	AppSettings.metadata[section][category] = metadataDuplicate.duplicate(true)
	#print(AppSettings.metadata[section][category])

func on_default_boolean_pressed(pressed : bool, checkBox : CheckBox):
	#print(pressed)
	var section = checkBox.get_meta("section_key")
	var category = checkBox.get_meta("category_key")
	var setting = checkBox.get_meta("setting_key")
	AppSettings.metadata[section][category][setting]["default"] = pressed

func on_default_range_changed(value : float, slider : Range):
	var section = slider.get_meta("section_key")
	var category = slider.get_meta("category_key")
	var setting = slider.get_meta("setting_key")
	AppSettings.metadata[section][category][setting]["default"] = value

func on_default_select_changed(index : int, optionButton : OptionButton):
	var section = optionButton.get_meta("section_key")
	var category = optionButton.get_meta("category_key")
	var setting = optionButton.get_meta("setting_key")
	var value = AppSettings.metadata[section][category][setting]['options'][index]['value']
	AppSettings.metadata[section][category][setting]["default"] = value

func on_setting_title_changed(text : String, lineEdit : LineEdit):
	var section = lineEdit.get_meta("section_key")
	var category = lineEdit.get_meta("category_key")
	var setting = lineEdit.get_meta("setting_key")
	AppSettings.metadata[section][category][setting]["title"] = text

func on_range_setting_changed(text : String, lineEdit : LineEdit, key : String):
	var section = lineEdit.get_meta("section_key")
	var category = lineEdit.get_meta("category_key")
	var setting = lineEdit.get_meta("setting_key")
	AppSettings.metadata[section][category][setting][key] = str2var(text)
	#todo: reload Hslider

func on_setting_type_changed(id : int, optionButton : OptionButton):
	var section = optionButton.get_meta("section_key")
	var category = optionButton.get_meta("category_key")
	var setting = optionButton.get_meta("setting_key")
	var container = optionButton.get_meta("container")
	var type : String
	var keyToCreate = Array()
	if id == 0:
		type = 'boolean'
		keyToCreate += ['default']
	elif id == 1:
		type = 'select'
		keyToCreate += ['options']
		keyToCreate += ['default']
	elif id == 2:
		type = 'range'
		keyToCreate += ['minimum']
		keyToCreate += ['maximum']
		keyToCreate += ['step']
		keyToCreate += ['default']
	AppSettings.metadata[section][category][setting]['type'] = type
	AppSettings.metadata[section][category][setting].erase('minimum')
	AppSettings.metadata[section][category][setting].erase('maximum')
	AppSettings.metadata[section][category][setting].erase('step')
	AppSettings.metadata[section][category][setting].erase('options')
	AppSettings.metadata[section][category][setting].erase('default')
	for key in keyToCreate:
		if key == 'options':
			AppSettings.metadata[section][category][setting]['options'] = Array()
		elif key == 'minimum' :
			AppSettings.metadata[section][category][setting]['minimum'] = 0
		elif key == 'maximum':
			AppSettings.metadata[section][category][setting]['maximum'] = 100
		elif key == 'step':
			AppSettings.metadata[section][category][setting]['step'] = 1.0
		elif key == 'default':
			if type == 'boolean':
				AppSettings.metadata[section][category][setting]['default'] = false
			elif type == 'select':
				AppSettings.metadata[section][category][setting]['options'] += [{
					"title": "_",
					"value": "_",
				}]
				AppSettings.metadata[section][category][setting]['default'] = '_'
			elif type == 'range':
				AppSettings.metadata[section][category][setting]['default'] = 50
	var parentContainer = container.get_parent()
	for child in parentContainer.get_children():
		parentContainer.remove_child(child)
#	var position = container.get_position_in_parent()
#	var previousNode = parentContainer.get_children()[position -1 ]
#	parentContainer.remove_child(container)
	for key in AppSettings.metadata[section][category][setting]:
		container = generate_setting_editor_from_key(section, category, setting, key)
		parentContainer.add_child(container)

func insert_section_at_position(section, position):
	var metadataDuplicate = Dictionary()
	var sectionName = section
	#print("position" + str(position))
	var i = 0
	while(AppSettings.metadata.has(sectionName)):
		#print("retrying")
		sectionName = section + str(i)
		i += 1
	i = 0
	for key in AppSettings.metadata:
		if i == position:
			metadataDuplicate[sectionName] = Dictionary()
		
		metadataDuplicate[key] = AppSettings.metadata[key].duplicate(true)
		i += 1
	if i == position:
			metadataDuplicate[sectionName] = Dictionary()
	AppSettings.metadata = metadataDuplicate.duplicate(true)

func insert_category_at_position(section, category, position):
	var metadataDuplicate = Dictionary()
	#print("position" + str(position))
	var categoryName = category
	var i = 0
	while(AppSettings.metadata[section].has(categoryName)):
		#print("retrying")
		categoryName = categoryName + str(i)
		i += 1
	i = 0
	for key in AppSettings.metadata[section]:
		#print(i)
		if i == position:
			metadataDuplicate[categoryName] = Dictionary()
			print("created new category")

		metadataDuplicate[key] = AppSettings.metadata[section][key].duplicate(true)
		i += 1
	if i == position:
		metadataDuplicate[categoryName] = Dictionary()
		print("created new category")
	AppSettings.metadata[section] = metadataDuplicate.duplicate(true)
	#print(metadataDuplicate)

func insert_setting_at_position(section, category, setting, position):
	var metadataDuplicate = Dictionary()
	#print("position" + str(position))
	var settingName = setting
	var i = 0
#	metadataDuplicate[section] = Dictionary()
#	metadataDuplicate[section][category] = Dictionary()
	while(AppSettings.metadata[section][category].has(settingName)):
		#print("retrying")
		settingName = settingName + str(i)
		i += 1
	i = 0
	#print(metadataDuplicate)
	for key in AppSettings.metadata[section][category]:
		
		if i == position:
			metadataDuplicate[settingName] = {
				"title": "new_setting",
				"type": 'boolean',
				"default": false,
			}
			
		metadataDuplicate[key] = 'a'
		metadataDuplicate[key] = AppSettings.metadata[section][category][key].duplicate(true)
		i += 1
	if i == position:
		metadataDuplicate[settingName] = {
			"title": "new_setting",
			"type": 'boolean',
			"default": false,
		}
	AppSettings.metadata[section][category] = metadataDuplicate.duplicate(true)

func on_add_section_pressed(button : Button):
	var position = button.get_meta("position")
	insert_section_at_position("new_section", position)
	generate_main_screen_from_metadata()

func on_add_category_pressed(button : Button):
	var section = button.get_meta("section_key")
	var position = button.get_meta("position")
	insert_category_at_position(section, "new_category", position)
	generate_main_screen_from_metadata()

func on_add_setting_pressed(button : Button):
	var section = button.get_meta("section_key")
	var category = button.get_meta("category_key")
	var position = button.get_meta("position")
	insert_setting_at_position(section, category, "new_setting", position)
	generate_main_screen_from_metadata()

func generate_main_screen_from_metadata():
	clear_main_screen_metadata()
	var sectionPosition = 0
	generate_new_add_section_button(sectionPosition, metadataContainer)
	for section in AppSettings.metadata.keys():
		var sectionContainer := VBoxContainer.new()
		var sectionEditContainer := HBoxContainer.new()
		var sectionLineEdit = LineEdit.new()
		sectionLineEdit.text = section
		sectionLineEdit.connect("text_entered", self, "on_section_rename", [sectionLineEdit])
		sectionLineEdit.set_meta("section_key", section)
#		sectionLineEdit.set_meta("dict_position", sectionPosition)
		sectionEditContainer.add_child(sectionLineEdit)
		sectionContainer.add_child(sectionEditContainer)

		metadataContainer.add_child(sectionContainer)
		var categoryPosition = 0
		generate_new_add_category_button(categoryPosition, sectionContainer, section)
		for category in AppSettings.metadata[section].keys():
			var categoryContainer := VBoxContainer.new()
			var categoryEditContainer := HBoxContainer.new()
			
			var categoryLineEdit = LineEdit.new()
			var categoryLabel := Label.new()
			categoryLineEdit.connect("text_entered", self, "on_category_rename", [categoryLineEdit])
			categoryLineEdit.set_meta("section_key", section)
			categoryLineEdit.set_meta("category_key", category)
			categoryLineEdit.text = category
	#		sectionLineEdit.set_meta("dict_position", sectionPosition)
			sectionContainer.add_child(categoryContainer)
			categoryContainer.add_child(categoryEditContainer)
			categoryEditContainer.add_child(categoryLabel)
			categoryEditContainer.add_child(categoryLineEdit)
			
			categoryLabel.text = " |─"
#			categoryEditContainer.add_child(categoryLineEdit)
			categoryEditContainer.anchor_right = 1.0
			var settingPosition = 0
			generate_new_add_setting_button(settingPosition, categoryContainer, section, category)
			for setting in AppSettings.metadata[section][category].keys():
				var settingContainer := VBoxContainer.new()
				var settingTitleContainer := HBoxContainer.new()
				var settingLabel := Label.new()
				var settingLineEdit := LineEdit.new()
				settingLabel.text = " |     |─"
				settingLineEdit.text = setting
				settingLineEdit.expand_to_text_length = true
				settingLineEdit.connect("text_entered", self, "on_setting_rename", [settingLineEdit])
				settingLineEdit.set_meta("section_key", section)
				settingLineEdit.set_meta("category_key", category)
				settingLineEdit.set_meta("setting_key", setting)
				settingTitleContainer.add_child(settingLabel)
				settingTitleContainer.add_child(settingLineEdit)
				categoryContainer.add_child(settingTitleContainer)
				categoryContainer.add_child(settingContainer)
				var foundScript = false
				for key in AppSettings.metadata[section][category][setting]:
					if key == 'script':
						foundScript = true
					var subMetadataContainer = generate_setting_editor_from_key(section, category, setting, key)
					settingContainer.add_child(subMetadataContainer)
				if not foundScript:
					var scriptContainer = HBoxContainer.new()
					var subKeySpacer := Label.new()
					subKeySpacer.text = " |     |     |─"
					var subKeyLineEdit := Label.new()
					subKeyLineEdit.text = 'script'
					subKeyLineEdit.rect_min_size.x = 90 
					scriptContainer.add_child(subKeySpacer)
					scriptContainer.add_child(subKeyLineEdit)
					
					var addScriptButton = generate_add_script_button(section, category, setting, scriptContainer)
					scriptContainer.add_child(addScriptButton)
					settingContainer.add_child(scriptContainer)
				settingPosition += 1
				generate_new_add_setting_button(settingPosition, categoryContainer, section, category)
			
			categoryPosition += 1
			generate_new_add_category_button(categoryPosition, sectionContainer, section)
		
		sectionPosition += 1
		generate_new_add_section_button(sectionPosition, metadataContainer)
	scrollContainer.scroll_horizontal_enabled = false
	scrollContainer.anchor_right = 1.0
	scrollContainer.anchor_bottom = 1.0
	scrollContainer.margin_right = 0.0
	scrollContainer.margin_bottom = 0.0
	scrollContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scrollContainer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	metadataContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metadataContainer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	metadataContainer.anchor_right = 1.0
	metadataContainer.anchor_bottom = 1.0

func on_add_script_pressed(button: Button):
	var section = button.get_meta("section_key")
	var category = button.get_meta("category_key")
	var setting = button.get_meta("setting_key")
	var scriptField = generate_script_field(section, category, setting)
	var container = button.get_meta("container")
	container.add_child(scriptField)
	container.remove_child(button.get_parent())
	pass

func on_remove_script_pressed(button: Button):
	var section = button.get_meta("section_key")
	var category = button.get_meta("category_key")
	var setting = button.get_meta("setting_key")
	var container = button.get_meta("container")
	var parentContainer = container.get_parent()
	var addScriptButton = generate_add_script_button(section, category, setting, parentContainer)
	AppSettings.metadata[section][category][setting].erase('script')
	parentContainer.add_child(addScriptButton)
	parentContainer.remove_child(container)
	pass

func on_setting_script_changed(text : String, lineEdit : LineEdit):
	var section = lineEdit.get_meta("section_key")
	var category = lineEdit.get_meta("category_key")
	var setting = lineEdit.get_meta("setting_key")
	var file = File.new()
	if not file.file_exists(text):
		var created = file.open(text, File.WRITE)
		if OK != created:
			printerr("The script metadata is set for %s/%s/%s, but the file doesn't exist and can't be written")
	AppSettings.metadata[section][category][setting]['script'] = text

func generate_add_script_button(section, category, setting, container):
	var subMetadataContainer = HBoxContainer.new()
#	var subKeySpacer := Label.new()
#	subKeySpacer.text = " |     |     |─"
	var addScriptButton := Button.new()
	addScriptButton.text = "Add a script to this setting"
	addScriptButton.icon = AddScriptTexture
	addScriptButton.set_meta("section_key", section)
	addScriptButton.set_meta("category_key", category)
	addScriptButton.set_meta("setting_key", setting)
	addScriptButton.set_meta("container", container)
	var settingDict = {
		'section': section,
		'category': category,
		'setting': setting
	}
	addScriptButton.hint_tooltip = """Optional, override field behaviour and actions\nLoaded scripts by default: \n"""
	addScriptButton.connect("pressed", self, "on_add_script_pressed", [addScriptButton])
	for path in AppSettings.get_input_field_script_lookup_paths(settingDict):
		addScriptButton.hint_tooltip += path + "\n"
#	subMetadataContainer.add_child(subKeySpacer)
	subMetadataContainer.add_child(addScriptButton)
	return subMetadataContainer

func generate_script_field(section : String, category : String, setting : String):
	var subMetadataContainer = HBoxContainer.new()
#	var subKeySpacer := Label.new()
#	subKeySpacer.text = " |     |     |─"
#	var subKeyLineEdit := Label.new()
#	subKeyLineEdit.text = 'script'
#	subKeyLineEdit.rect_min_size.x = 90 
#	subMetadataContainer.add_child(subKeySpacer)
#	subMetadataContainer.add_child(subKeyLineEdit)

	var scriptLineEdit := LineEdit.new()
	if not AppSettings.metadata[section][category][setting].has('script'):
		AppSettings.metadata[section][category][setting]['script'] = 'res://'
	scriptLineEdit.text = AppSettings.metadata[section][category][setting]['script']
	scriptLineEdit.set_meta("section_key", section)
	scriptLineEdit.set_meta("category_key", category)
	scriptLineEdit.set_meta("setting_key", setting)
	scriptLineEdit.connect("text_entered", self, "on_setting_script_changed", [scriptLineEdit])
	subMetadataContainer.add_child(scriptLineEdit)
	scriptLineEdit.expand_to_text_length = true
	var removeScriptButton = Button.new()
	removeScriptButton.set_meta("container", subMetadataContainer)
	removeScriptButton.icon = RemoveScriptTexture
	removeScriptButton.set_meta("section_key", section)
	removeScriptButton.set_meta("category_key", category)
	removeScriptButton.set_meta("setting_key", setting)
	subMetadataContainer.add_child(removeScriptButton)
	removeScriptButton.connect("pressed", self, "on_remove_script_pressed", [removeScriptButton])
	return subMetadataContainer

func generate_new_add_category_button(categoryPosition, parent, section):
	var addCategoryContainer = HBoxContainer.new()
	var addCategorySpacer = Label.new()
	var addCategoryButton = Button.new()
#	addCategorySpacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	addCategorySpacer.text = " |─"
#	addCategoryButton.text = "Add New Category Here"
	addCategoryButton.icon = AddTexture

	addCategoryButton.set_meta("section_key", section)
	addCategoryButton.set_meta("position", categoryPosition)
	addCategoryContainer.add_child(addCategorySpacer)
	addCategoryContainer.add_child(addCategoryButton)
	parent.add_child(addCategoryContainer)
	addCategoryButton.connect("pressed", self, "on_add_category_pressed", [addCategoryButton])

func generate_new_add_setting_button(settingPosition, parent, section, category):
	var addSettingContainer = HBoxContainer.new()
	var addSettingSpacer = Label.new()
	var addSettingButton = Button.new()
#	addSettingSpacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	addSettingSpacer.text = " |     |─"
#	addSettingSpacer.text = ""
#	addSettingButton.text = "Add New Setting Here"
	addSettingButton.icon = AddTexture
	addSettingButton.set_meta("section_key", section)
	addSettingButton.set_meta("category_key", category)
	addSettingButton.set_meta("position", settingPosition)
	addSettingContainer.add_child(addSettingSpacer)
	addSettingContainer.add_child(addSettingButton)
	parent.add_child(addSettingContainer)
	addSettingButton.connect("pressed", self, "on_add_setting_pressed", [addSettingButton])

func generate_new_add_section_button(sectionPosition, parent):
	var addSectionContainer = HBoxContainer.new()
#	var addSectionSpacer = Label.new()
	var addSectionButton = Button.new()
#	addSectionButton.text = "Add New Section Here"
	addSectionButton.icon = AddTexture
	addSectionButton.set_meta("position", sectionPosition)
#	addSectionContainer.add_child(addSectionSpacer)
	addSectionContainer.add_child(addSectionButton)
	parent.add_child(addSectionContainer)
	addSectionButton.connect("pressed", self, "on_add_section_pressed", [addSectionButton])
	return addSectionButton

func generate_setting_editor_from_key(section, category, setting, key):
	var subMetadataContainer = HBoxContainer.new()
	var subKeySpacer := Label.new()
	subKeySpacer.text = " |     |     |─"
	var subKeyLineEdit := Label.new()
	subKeyLineEdit.text = key
	subKeyLineEdit.rect_min_size.x = 90 
	subMetadataContainer.add_child(subKeySpacer)
	subMetadataContainer.add_child(subKeyLineEdit)
	if key == 'title':
		var titleLineEdit := LineEdit.new()
		titleLineEdit.text = AppSettings.metadata[section][category][setting][key]
		titleLineEdit.set_meta("section_key", section)
		titleLineEdit.set_meta("category_key", category)
		titleLineEdit.set_meta("setting_key", setting)
		titleLineEdit.connect("text_entered", self, "on_setting_title_changed", [titleLineEdit])
		subMetadataContainer.add_child(titleLineEdit)
		titleLineEdit.expand_to_text_length = true
	elif key == 'default':
		var type = AppSettings.metadata[section][category][setting]['type']
		
		var inputField
		if type == 'boolean':
			inputField = CheckBox.new()
			inputField.pressed = AppSettings.metadata[section][category][setting]['default']
			inputField.set_meta("section_key", section)
			inputField.set_meta("category_key", category)
			inputField.set_meta("setting_key", setting)
			inputField.connect("toggled", self, "on_default_boolean_pressed", [inputField])
			
		elif type == 'select':
			inputField = OptionButton.new()
			var options = AppSettings.metadata[section][category][setting]['options']
			var default = AppSettings.metadata[section][category][setting]['default']
			var i = 0
			var default_id
			for option in options:
				inputField.add_item(option['title'])
				if str(default) == str(option['value']):
					default_id = i
				i += 1
			inputField.set_meta("section_key", section)
			inputField.set_meta("category_key", category)
			inputField.set_meta("setting_key", setting)
			inputField.connect("item_selected", self, "on_default_select_changed", [inputField])
			inputField.selected = default_id
		else:
			inputField = HSlider.new()
			inputField.value = AppSettings.metadata[section][category][setting]['default']
			inputField.rect_min_size.x = 300
			inputField.set_meta("section_key", section)
			inputField.set_meta("category_key", category)
			inputField.set_meta("setting_key", setting)
			inputField.connect("value_changed", self, "on_default_range_changed", [inputField])
			inputField.min_value = AppSettings.metadata[section][category][setting]['minimum']
			inputField.max_value = AppSettings.metadata[section][category][setting]['maximum']
			inputField.step = AppSettings.metadata[section][category][setting]['step']
		subMetadataContainer.add_child(inputField)

	elif key == 'type':
		var selectButton := OptionButton.new()

		selectButton.add_icon_item(BooleanTexture,'Boolean')
		selectButton.add_icon_item(SelectTexture,'Select')
		selectButton.add_icon_item(RangeTexture,'Range')
		var settingType = AppSettings.metadata[section][category][setting]['type']
		#print(settingType)
		if settingType == 'boolean':
			selectButton.selected = 0
		elif settingType == 'select':
			selectButton.selected = 1
		else:
			selectButton.selected = 2
		selectButton.set_meta("section_key", section)
		selectButton.set_meta("category_key", category)
		selectButton.set_meta("setting_key", setting)
		selectButton.set_meta("container", subMetadataContainer)
		selectButton.connect("item_selected", self, "on_setting_type_changed", [selectButton])
		subMetadataContainer.add_child(selectButton)
	elif key == 'minimum' or key == 'maximum' or key == 'step':
		var lineEdit = LineEdit.new()
		lineEdit.set_meta("section_key", section)
		lineEdit.set_meta("category_key", category)
		lineEdit.set_meta("setting_key", setting)
		lineEdit.connect("text_entered", self, "on_range_setting_changed", [lineEdit, key])
		lineEdit.text = var2str(AppSettings.metadata[section][category][setting][key])
		subMetadataContainer.add_child(lineEdit)
	elif key == 'options':
		var options = AppSettings.metadata[section][category][setting]['options']
		var optionsContainer = preload("res://addons/open-hexes.appsettings/editor/ResizableTable.gd").new()
		optionsContainer.input = options
		optionsContainer.keys = ['title', 'value', 'pset']
		optionsContainer.keyNames = ['Option title', 'Value', 'ProjectSettings']
		subMetadataContainer.add_child(optionsContainer)
	elif key =='script':
		var scriptContainer = generate_script_field(section, category, setting)
		subMetadataContainer.add_child(scriptContainer)
	return subMetadataContainer
	

func on_add_presets_pressed():
#	print("pouet")

	fileDialog.popup()
#	fileDialog.visible = true
	fileDialog.anchor_right = 1.0
	fileDialog.anchor_bottom = 1.0
	fileDialog.margin_right = 0
	fileDialog.margin_bottom = 0 

func on_save_metadata_pressed():
#	print("hey")
	AppSettings.save_metadata_to_file()


func on_merge_replace_pressed():
	AppSettings.metadata = dictMerger.result.duplicate()
	generate_main_screen_from_metadata()
	dictMerger.popup.queue_free()

func on_merge_cancel_pressed():
	dictMerger.popup.queue_free()
