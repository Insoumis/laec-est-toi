extends Control
signal replace_pressed
signal cancel_pressed

var DiffTexture = preload("res://addons/open-hexes.appsettings/editor/icon_diff_button.svg")
var DiffTextureOff = preload("res://addons/open-hexes.appsettings/editor/icon_diff_off_button.svg")

var parent_plugin : Node
var fileDialog := FileDialog.new()
var popup := Popup.new()
var mergeCheckBoxes := Array()
var mergeKeyLabels := Array()
var mergeOldValueLabels := Array()
var mergeNewValueLabels := Array()
var keySpaceHolder : Control
var oldSpaceHolder : Control
var newSpaceHolder : Control

var container
var metadataContainer
var waiting_dict = Dictionary()

# probable event should be an InputEvent but can be an offset
# used for performance optimisation to avoid iteration when useless
# while keeping colmuns aligned
func on_diff_hsplit_resize(probable_event):
	if not (probable_event is InputEventMouseButton) and not (typeof(probable_event) == TYPE_INT):
		return
	elif not (typeof(probable_event) == TYPE_INT):
		if probable_event.pressed:
			return
	for label in mergeKeyLabels:
		label.rect_size.x = keySpaceHolder.rect_size.x
	for label in mergeOldValueLabels:
#		pass
		label.rect_size.x = oldSpaceHolder.rect_size.x
		label.rect_position.x = keySpaceHolder.rect_size.x  
	for label in mergeNewValueLabels:
		label.rect_size.x = newSpaceHolder.rect_size.x 
		label.rect_position.x = keySpaceHolder.rect_size.x + oldSpaceHolder.rect_size.x  + 62.0
	for checkBox in mergeCheckBoxes:
		checkBox.rect_position.x = keySpaceHolder.rect_size.x + oldSpaceHolder.rect_size.x +12

func on_all_hsplit_resize(probable_event):
	on_diff_hsplit_resize(probable_event)

func generate_merge_popup(keys : Array, destination : Dictionary, source : Dictionary):
	self.result = destination.duplicate()
	self.waiting_dict = source.duplicate()
	# Reset Nodes and Arrays
	
	if popup != null:
		popup.queue_free()
	mergeCheckBoxes = Array()
	mergeKeyLabels = Array()
	mergeOldValueLabels = Array()
	mergeNewValueLabels = Array()
	popup = Popup.new()
	keySpaceHolder = ColorRect.new()
	oldSpaceHolder = ColorRect.new()
	newSpaceHolder = ColorRect.new()
	
	# Inititial popup setup
	
	var popupContentContainer = VBoxContainer.new()
	var popupColorRectBackground = ColorRect.new()
	var popupColorRect = ColorRect.new()
	popupColorRect.color = 0x333a4fff
	popupColorRectBackground.color = 0x00000033
	popup.add_child(popupColorRectBackground)
	popup.add_child(popupColorRect)
	popupColorRect.add_child(popupContentContainer)
	
	get_node("/root").add_child(popup)
	var tableBackgroundContainer = Control.new()
	var tableScrollContainer = ScrollContainer.new()
	var tableContainer = VBoxContainer.new()
	
	var allVSplit := HSplitContainer.new()
	var diffVSplit := HSplitContainer.new()
	allVSplit.add_child(keySpaceHolder)
	allVSplit.add_child(diffVSplit)
	diffVSplit.add_child(oldSpaceHolder)
	diffVSplit.add_child(newSpaceHolder)
	
	# Set Windows Title
	
	var popupTitle = Label.new()
	popupTitle.text = "Metadata Merger"
	popupTitle.align = Label.ALIGN_CENTER
	popupContentContainer.add_child(popupTitle)
	popupContentContainer.add_child(tableBackgroundContainer)
	tableBackgroundContainer.add_child(allVSplit)
	tableBackgroundContainer.add_child(tableScrollContainer)
	tableScrollContainer.add_child(tableContainer)
	
	# Column Title Line
	
	var titleSplit = HSeparator.new()

	tableBackgroundContainer.add_child(titleSplit)

	var keyColumnTitle = Label.new()
	keyColumnTitle.clip_text = true
	keyColumnTitle.text = "Metadata keys:"
	keyColumnTitle.align = Label.ALIGN_CENTER
	keyColumnTitle.anchor_right = 1.0
	keyColumnTitle.margin_top = 15
	keySpaceHolder.add_child(keyColumnTitle)
	
	var oldColumnTitle = Label.new()
	oldColumnTitle.clip_text = true
	oldColumnTitle.text = "Values before merge:"
	oldColumnTitle.align = Label.ALIGN_CENTER
	oldColumnTitle.anchor_right = 1.0
	oldColumnTitle.margin_top = 15
	oldSpaceHolder.add_child(oldColumnTitle)
	
	var newColumnTitle = Label.new()
	newColumnTitle.clip_text = true
	newColumnTitle.text = "Values to merge:"
	newColumnTitle.align = Label.ALIGN_CENTER
	newColumnTitle.anchor_right = 1.0
	newColumnTitle.margin_top = 15
	newSpaceHolder.add_child(newColumnTitle)
	
	# Setup splits for column tricks and size flags
	
	diffVSplit.add_constant_override("separation", 40)
	
	popupContentContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	tableBackgroundContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tableBackgroundContainer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	titleSplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titleSplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tableScrollContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tableScrollContainer.size_flags_vertical = Control.SIZE_EXPAND_FILL
#	tableScrollContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tableContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tableContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tableContainer.add_constant_override("separation", 0)

	allVSplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	allVSplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	diffVSplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diffVSplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diffVSplit.size_flags_stretch_ratio = 2.0
	
	# Set column colors and size flags
	
	keySpaceHolder.color = Color(1.0, 1.0, 1.0, 0.05)
	oldSpaceHolder.color = Color(1.0, 1.0, 1.0, 0.05)
	newSpaceHolder.color = Color(1.0, 1.0, 1.0, 0.05)
	keySpaceHolder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keySpaceHolder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	oldSpaceHolder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	oldSpaceHolder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	newSpaceHolder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	newSpaceHolder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Build each Line
	
	for key in keys:
		var keySplitted = key.split("/", false)
		var oldValue = destination.duplicate()
		var newValue = source.duplicate()
		for keyString in keySplitted:
			oldValue = oldValue[keyString]
			newValue = newValue[keyString]
		
		var keyContainer = HBoxContainer.new()
		tableContainer.add_child(keyContainer)
		var label = Label.new()
		label.text = key
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.clip_text = true
		keyContainer.add_child(label)
		mergeKeyLabels += [label]
		var oldValueLabel = Label.new()
		oldValueLabel.clip_text = true
		if typeof(oldValue) == TYPE_ARRAY:
			oldValueLabel.text = str(oldValue).replace("}, ", "\n")
		else:
			oldValueLabel.text = str(oldValue)
#		oldValueLabel.rect_min_size.x = 300
		oldValueLabel.align = oldValueLabel.ALIGN_RIGHT
		keyContainer.add_child(oldValueLabel)
		mergeOldValueLabels += [oldValueLabel]
		oldValueLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
		var diffSeparator = CheckButton.new()
		var diffStyle = StyleBoxFlat.new()
		diffStyle.bg_color = Color(0.2, 0.6, 1.0, 1.0)
#		textureStyleBox.modulate_color = Color(0.0, 1.0, 1.0)
		diffSeparator.add_icon_override("on",DiffTexture)
		diffSeparator.add_icon_override("off",DiffTextureOff)
		diffSeparator.add_stylebox_override("hover", diffStyle)
		diffSeparator.add_stylebox_override("hover_pressed", diffStyle)
		diffSeparator.rect_min_size.y = 30
		keyContainer.add_child(diffSeparator)
		diffSeparator.set_meta("setting_key", key)
		mergeCheckBoxes += [diffSeparator]

		var newValueLabel = Label.new()
		newValueLabel.clip_text = true
		if typeof(newValue) == TYPE_ARRAY:
			newValueLabel.text = str(oldValue).replace("}, ", "\n")
		else:
			newValueLabel.text = str(newValue)
		newValueLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mergeNewValueLabels += [newValueLabel]
		keyContainer.add_child(newValueLabel)
	
	popup.popup()
	
	# Set anchor and margins
	
	popupColorRectBackground.anchor_right = 1.0
	popupColorRectBackground.anchor_bottom = 1.0
	popupColorRectBackground.margin_right = 0
	popupColorRectBackground.margin_bottom = 0 	

	popupContentContainer.anchor_left = 0
	popupContentContainer.anchor_top = 0
	popupContentContainer.anchor_right = 1.0
	popupContentContainer.anchor_bottom = 1.0

	titleSplit.anchor_right = 1.0
	titleSplit.margin_top = 33
#	titleSplit.anchor_bottom = 1.0

	tableScrollContainer.anchor_right = 1.0
	tableScrollContainer.anchor_bottom = 1.0
	tableScrollContainer.margin_top = 35
	
	allVSplit.anchor_right = 1.0
	allVSplit.anchor_bottom = 1.0
	
	keySpaceHolder.anchor_right = 1.0
	keySpaceHolder.anchor_bottom = 1.0
	
	tableContainer.anchor_left = 0
	tableContainer.anchor_top = 0
	tableContainer.anchor_right = 1.0
	tableContainer.anchor_bottom = 1.0

	popup.anchor_left = 0
	popup.anchor_top = 0
	popup.anchor_right = 1.0
	popup.anchor_bottom = 1.0
	
	popup.margin_left = 0
	popup.margin_top = 0 
	popup.margin_right = 0
	popup.margin_bottom = 0 
	popupColorRect.anchor_left = 0.2
	popupColorRect.anchor_top = 0.2
	popupColorRect.anchor_right = 0.8
	popupColorRect.anchor_bottom = 0.8
	popupColorRect.margin_left = 0
	popupColorRect.margin_top = 0 
	popupColorRect.margin_right = 0
	popupColorRect.margin_bottom = 0

	var answerContainer = HBoxContainer.new()
	answerContainer.alignment = BoxContainer.ALIGN_CENTER
	popupContentContainer.add_child(answerContainer)
	var replaceButton = Button.new()
	replaceButton.text = 'Replace'
	answerContainer.add_child(replaceButton)
	var cancelButton = Button.new()
	cancelButton.text = 'Cancel'
	answerContainer.add_child(cancelButton)

	allVSplit.connect("dragged", self, "on_all_hsplit_resize")
	diffVSplit.connect("dragged", self, "on_diff_hsplit_resize")
	allVSplit.connect("gui_input", self, "on_all_hsplit_resize")
	diffVSplit.connect("gui_input", self, "on_diff_hsplit_resize")
	replaceButton.connect("pressed", self, "on_merge_replace_pressed")
	cancelButton.connect("pressed", self, "on_merge_cancel_pressed")

var result

func on_merge_replace_pressed():
	var keys := Array()
	for checkbox in self.mergeCheckBoxes:
		if checkbox.pressed == true:
			keys += [checkbox.get_meta("setting_key")]
	AppSettings.merge_dicts(result, waiting_dict, true, "", keys)

	print("replaced from metadata:")
	print(keys)

	emit_signal("replace_pressed")

func on_merge_cancel_pressed():
	emit_signal("cancel_pressed")

