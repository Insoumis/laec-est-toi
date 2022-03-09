extends Control

#  _                    _     ______            _
# | |                  | |   |  ____|          | |
# | |     _____   _____| |___| |__  __  ___ __ | | ___  _ __ ___ _ __
# | |    / _ \ \ / / _ \ / __|  __| \ \/ / '_ \| |/ _ \| '__/ _ \ '__|
# | |___|  __/\ V /  __/ \__ \ |____ >  <| |_) | | (_) | | |  __/ |
# |______\___| \_/ \___|_|___/______/_/\_\ .__/|_|\___/|_|  \___|_|
#                                        | |
#                                        |_|
# 
# Shows levels found in the local user directories.
# 

const EditorScene = preload("res://editor/LevelEditor.tscn")
const LevelReference = preload("res://core/LevelReference.gd")


onready var filesystem_help: RichTextLabel = find_node("FilesystemHelp")
onready var levels_list: ItemList = find_node("LevelsList")
onready var import_dock: Container = find_node("ImportDock")
onready var import_field: TextEdit = find_node("ImportField")
onready var import_button: Button = find_node("ImportButton")


var user_levels := Array()  # of PoolLevel, indexed like items in ItemList above


var is_ready := false


func _ready():
	refresh_gui()
	self.is_ready = true
	if OK != get_tree().connect("files_dropped", self, "_on_files_dropped"):
		printerr("Failed to connect to files dropped.")
		breakpoint


func _enter_tree():
	if self.is_ready:
		refresh_gui()


func _on_files_dropped(files, _screen):
	if not files:
		breakpoint
		return
	print("Loading dropped file `%s'." % files[0])
	var level = LevelReference.new()
	var loaded = level.load_from_filepath(files[0])
	if OK != loaded:
		printerr("Failed to load file `%s'." % files[0])
		breakpoint
		return
	open_editor(level)


func refresh_gui():
	rebuild_levels_list()
	connect_levels_list()


func rebuild_levels_list():
	if not self.levels_list:
		return
	self.levels_list.clear()
	LevelsPool.reindex_levels()
	self.user_levels = LevelsPool.get_user_levels()
	var i := 0
	for level in self.user_levels:
		# We could also add an icon here
		self.levels_list.add_item(level.level_filepath)
		self.levels_list.set_item_metadata(i, level)
		i += 1


func connect_levels_list():
	if not self.levels_list.is_connected(
			"item_activated", self, "_on_levels_list_item_activated"
		):
		var connected = self.levels_list.connect(
			"item_activated", self, "_on_levels_list_item_activated"
		)
		if OK != connected:
			printerr("Failed to connect to the levels list")


func open_editor(level=null):
	var editor = EditorScene.instance()
	if level:
		editor.configure_for_level(level)
	Game.switch_to_scene(editor)


func _on_NewButton_pressed():
	open_editor()


var open_file_dialog: FileDialog


func _on_OpenButton_pressed():
	if not open_file_dialog:
		open_file_dialog = FileDialog.new()
		open_file_dialog.set_access(FileDialog.ACCESS_USERDATA)
		open_file_dialog.set_current_dir("user://levels")
		open_file_dialog.set_mode(FileDialog.MODE_OPEN_FILE)
		open_file_dialog.set_filters(['*.phiu', '*.png'])
		var _c = open_file_dialog.connect(
			"file_selected", self, "_on_Open_file_selected"
		)
		add_child(open_file_dialog)
	open_file_dialog.popup_centered_ratio()


func _on_ExitButton_pressed():
	Game.go_back()


func _on_Open_file_selected(filepath):
	var level = LevelReference.new()
	var loaded = level.load_from_filepath(filepath)
	if OK != loaded:
		printerr("Failed to load file `%s'." % filepath)
		breakpoint
		return
	open_editor(level)


func _on_levels_list_item_activated(item_id):
	var level = self.levels_list.get_item_metadata(item_id)
	open_editor(level)


func _on_ImportButton_pressed():
	var level = LevelReference.new()
	var parse_err = level.parse_phiu(self.import_field.text)
	if parse_err:
		printerr("Failed to parse level import string")
		# … do something in the UI
		return
	open_editor(level)
