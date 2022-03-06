extends Control

var input := Array()
var keys := Array()
var keyNames := Array()

var cxLineEdits := Array()
var cxSpaceHolder := Array()
var splits := Array()


func _enter_tree():
	self.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	self.rect_min_size.y = 110
	for i in range(0, keys.size() -1):
		splits += [HSplitContainer.new()]
		if i == 0:
			splits[i].anchor_right = 1.0
			splits[i].anchor_bottom = 1.0
		else:
			splits[i].size_flags_horizontal = Control.SIZE_EXPAND_FILL
			splits[i].size_flags_vertical = Control.SIZE_EXPAND_FILL
#	var allHSplit = HSplitContainer.new()
##						allHSplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
##						allHSplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
#	allHSplit.anchor_right = 1.0
#	allHSplit.anchor_bottom = 1.0
#	var n2n3HSplit = HSplitContainer.new()
#	n2n3HSplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
#	n2n3HSplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var i = 0
	for split in splits:
		split.connect("dragged", self, "on_column_dragged")
		if i != 0:
			split.size_flags_stretch_ratio = (keys.size() - i) * 1.0
			#print(split.size_flags_stretch_ratio)
		i += 1
#	allHSplit.connect("dragged", self, "on_column_dragged")
#	n2n3HSplit.connect("dragged", self, "on_column_dragged")
	
	var optionScrollContainer = ScrollContainer.new()
#						optionScrollContainer.rect_min_size = Vector2(300,150)
#						optionScrollContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#print('a')
	optionScrollContainer.margin_top = 25
	optionScrollContainer.anchor_right = 1.0
	optionScrollContainer.anchor_bottom = 1.0
	optionScrollContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var optionTableContainer = VBoxContainer.new()
	optionTableContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	i = 0
#	var cxSpaceHolder[0] = ColorRect.new()
#	c0SpaceHolder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
#	c0SpaceHolder.size_flags_vertical = Control.SIZE_EXPAND_FILL
#	var c1SpaceHolder = ColorRect.new()
#	c1SpaceHolder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
#	c1SpaceHolder.size_flags_vertical = Control.SIZE_EXPAND_FILL
#	var c2SpaceHolder = ColorRect.new()
#	c2SpaceHolder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
#	c2SpaceHolder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	self.add_child(splits[0])
	self.add_child(optionScrollContainer)
#	allHSplit.add_child(c0SpaceHolder)
	
#	n2n3HSplit.add_child(c1SpaceHolder)
#	n2n3HSplit.add_child(c2SpaceHolder)
	optionScrollContainer.add_child(optionTableContainer)
	
	var names : Array
	if keyNames.size() == 0: 
		names = keys.duplicate()
	else:
		names = keyNames.duplicate()
	i = 0
	for key in keys:
		cxSpaceHolder += [ColorRect.new()]
		var cTitle = Label.new()
		cTitle.text = names[i].capitalize()
		cxSpaceHolder[i].add_child(cTitle)
		cxSpaceHolder[i].color = Color(1.0, 1.0, 1.0, 0.05)
		cxSpaceHolder[i].size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cxSpaceHolder[i].size_flags_vertical = Control.SIZE_EXPAND_FILL
		if i == 0:
			splits[i].add_child(cxSpaceHolder[i])
			splits[i].add_child(splits[i+1])
		else:
#			print(i+1)
#			print((i + 1) < (keys.size()  - 1))
			if i < keys.size()  - 1:
				splits[i].add_child(cxSpaceHolder[i])
			
			if i + 1 < keys.size()  - 1:
				splits[i].add_child(splits[i+1])
			
			if i == keys.size()  - 1:
				splits[i-1].add_child(cxSpaceHolder[i])

		cxLineEdits += [Array()]
		i += 1
	for row in input:
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title = LineEdit.new()
		cxLineEdits[0] += [title]
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.text = row[keys[0]]
		var value = LineEdit.new()
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.text = row[keys[1]]
		cxLineEdits[1] += [value]
		hbox.add_child(title)
		hbox.add_child(value)
		for j in range(2, keys.size()):
			var pset = LineEdit.new()
			pset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pset.text = ''
			cxLineEdits[j] += [pset]
			hbox.add_child(pset)

		
		optionTableContainer.add_child(hbox)
		hbox.anchor_right = 1.0

func on_column_dragged(v):
	var i = 0
	var parent_offset = 0
	for lineEdits in cxLineEdits:
		if i != 0 and i < keys.size() -1 :
			parent_offset += cxSpaceHolder[i].get_parent().rect_position.x
		for lineEdit in lineEdits:
			lineEdit.rect_size.x =  cxSpaceHolder[i].rect_size.x
			if i != 0 and i < keys.size() -1 :
#				lineEdit.rect_position.x =  cxSpaceHolder[i].get_parent().rect_position.x
#				parent_offset += cxSpaceHolder[i].get_parent().rect_position.x
				lineEdit.rect_position.x = parent_offset
			elif i == keys.size() -1 :
				lineEdit.rect_position.x =  parent_offset +  cxSpaceHolder[i-1].rect_size.x
				lineEdit.rect_size.x =  cxSpaceHolder[i].rect_size.x
				#print(parent_offset)
		i += 1
	pass 


