extends AcceptDialog


onready var save_button: Button = find_node("SaveToFileButton", true)
onready var save_as_image_button: Button = find_node("SaveToImageFileButton", true)
onready var base_16_field: TextEdit = find_node("Base 16", true)
onready var base_64_field: TextEdit = find_node("Base 64", true)
onready var base_256_field: TextEdit = find_node("Base 256", true)
onready var base_1024_field: TextEdit = find_node("Base 1024", true)
onready var level_image: TextureRect = find_node("LevelImage", true)

var save_file_dialog: FileDialog
var save_image_file_dialog: FileDialog

# cycles, cycles, faites du vélo !
#const LevelEditor = preload("res://editor/LevelEditor.gd")

func _notification(what):
	if what == NOTIFICATION_POST_POPUP:
#		yield(get_tree(), "idle_frame")
		anchor_top = 0.1
		anchor_left = 0.1
		anchor_right = 0.9
		anchor_bottom = 0.9
		margin_top = 0.0
		margin_left = 0.0
		margin_right = 0.0
		margin_bottom = 0.0


var __level_editor

func get_level_editor() -> Control:
	if __level_editor:
		return __level_editor
	
	# Dynamic loading to avoid cyclic deps, cheap but works
	var LevelEditor = load("res://editor/LevelEditor.gd")
	var le = get_parent()
	while le:
		if le and le is LevelEditor:
			__level_editor = le
			return le
		le = le.get_parent()
	breakpoint  # requires parent LevelEditor
	return null


func set_base16_export(s: String):
	self.base_16_field.text = s


func set_base64_export(s: String):
	self.base_64_field.text = s


func set_base256_export(s: String):
	self.base_256_field.text = s


func set_base1024_export(s: String):
	self.base_1024_field.text = s


func set_image_export(image: Image):
	self.level_image.texture = ImageTexture.new()
	self.level_image.texture.create_from_image(image)


func _on_SaveToFileButton_pressed():
	var level_editor = get_level_editor()

	self.save_file_dialog = FileDialog.new()
	self.save_file_dialog.margin_top = 0.0
	self.save_file_dialog.margin_left = 0.0
	self.save_file_dialog.margin_right = 0.0
	self.save_file_dialog.margin_bottom = 0.0
	self.save_file_dialog.anchor_top = 0.07
	self.save_file_dialog.anchor_left = 0.07
	self.save_file_dialog.anchor_right = 0.93
	self.save_file_dialog.anchor_bottom = 0.93
	
	self.save_file_dialog.access = FileDialog.ACCESS_USERDATA
	self.save_file_dialog.popup_exclusive = true
	self.save_file_dialog.current_dir = "user://levels"
	if level_editor.save_filepath:
		self.save_file_dialog.current_file = level_editor.save_filepath
		self.save_file_dialog.current_path = level_editor.save_filepath
	else:
		self.save_file_dialog.current_file = "MyAmazingLevel.phiu"
		self.save_file_dialog.current_path = "MyAmazingLevel.phiu"
	
	get_parent().add_child_below_node(self, self.save_file_dialog)
	self.save_file_dialog.popup_centered()
	var _c = self.save_file_dialog.connect(
		"popup_hide", self, "_on_FileDialog_popup_hide"
	)
	if level_editor:
		_c = self.save_file_dialog.connect(
			"file_selected", level_editor, "_on_SaveDialog_file_selected"
		)


func _on_FileDialog_popup_hide():
#	print("_on_FileDialog_popup_hide")
	self.save_file_dialog.queue_free()


func _on_SaveToImageFileButton_pressed():
	print("saving to image file...")

	var level_editor = get_level_editor()

	self.save_image_file_dialog = FileDialog.new()
	self.save_image_file_dialog.margin_top = 0.0
	self.save_image_file_dialog.margin_left = 0.0
	self.save_image_file_dialog.margin_right = 0.0
	self.save_image_file_dialog.margin_bottom = 0.0
	self.save_image_file_dialog.anchor_top = 0.07
	self.save_image_file_dialog.anchor_left = 0.07
	self.save_image_file_dialog.anchor_right = 0.93
	self.save_image_file_dialog.anchor_bottom = 0.93

	self.save_image_file_dialog.access = FileDialog.ACCESS_USERDATA
	self.save_image_file_dialog.popup_exclusive = true
	self.save_image_file_dialog.current_dir = "user://levels"

	if level_editor.save_filepath:
		self.save_image_file_dialog.current_file = level_editor.save_filepath
		self.save_image_file_dialog.current_path = level_editor.save_filepath
	else:
		self.save_image_file_dialog.current_file = "MyAmazingLevel.png"
		self.save_image_file_dialog.current_path = "MyAmazingLevel.png"

	get_parent().add_child_below_node(self, self.save_image_file_dialog)
	self.save_image_file_dialog.popup_centered()
	var _c = self.save_image_file_dialog.connect("popup_hide", self, "_on_ImageFileDialog_popup_hide")
	if level_editor:
		_c = self.save_image_file_dialog.connect("file_selected", level_editor,
			"_on_SaveDialog_image_file_selected")


func _on_ImageFileDialog_popup_hide():
	print("_on_ImageFileDialog_popup_hide")
	self.save_image_file_dialog.queue_free()
