extends Control

#  _                    _ ______    _ _ _
# | |                  | |  ____|  | (_) |
# | |     _____   _____| | |__   __| |_| |_ ___  _ __
# | |    / _ \ \ / / _ \ |  __| / _` | | __/ _ \| '__|
# | |___|  __/\ V /  __/ | |___| (_| | | || (_) | |
# |______\___| \_/ \___|_|______\__,_|_|\__\___/|_|
#
# Nitty-gritty is in EditorActivity

const LevelReference = preload("res://core/LevelReference.gd")
const ExportDialog = preload("res://editor/activities/ExportDialog.gd")
const ImportDialog = preload("res://editor/activities/ImportDialog.gd")
const MetadataDialog = preload("res://editor/activities/MetadataDialog.gd")


export var camera_zoom_step := 0.1


onready var activity := $DrawingSection/ActivityContainer
onready var preview := $DrawingSection/ActivityContainer/Preview/PreviewContainer
onready var export_dialog: ExportDialog = $ExportDialog
onready var import_dialog: ImportDialog = $ImportDialog
onready var help_dialog: AcceptDialog = $HelpDialog
onready var metadata_dialog: MetadataDialog = $MetadataDialog
onready var exit_dialog: ConfirmationDialog = $ExitDialog
onready var preview_camera := $DrawingSection/ActivityContainer/Preview/PreviewContainer/Previewport/PreviewCamera
onready var level_camera := $DrawingSection/ActivityContainer/Preview/PreviewContainer/Previewport/Level/Camera2D
onready var menu := $Menu
onready var camera_border := $DrawingSection/ActivityContainer/Preview/PreviewContainer/Previewport/CameraBorder


var has_connected_gui := false  # _ready may be run multiple times


func _ready():
	connect_gui_perhaps()
	if __level_to_open:
		#load_level(__level_to_open)
		if __level_to_open.pickle:
#			load_level_from_pickle(Jsonify.godotify(__level_to_open.pickle))
			load_level_from_pickle(__level_to_open.pickle)
		else:
			breakpoint # todo: load from tscn file


func _input(_event):
	process_tool_inputs()


func _on_Preview_gui_input(_event):
	process_zoom_inputs()


#   _____                           _
#  / ____|                         | |
# | |  __  ___ _ __   ___ _ __ __ _| |
# | | |_ |/ _ \ '_ \ / _ \ '__/ _` | |
# | |__| |  __/ | | |  __/ | | (_| | |
#  \_____|\___|_| |_|\___|_|  \__,_|_|
#
#

var __level_to_open

#func configure_for_level(level: PoolLevel):
func configure_for_level(level):
	__level_to_open = level
	if level.filepath:
		self.save_filepath = level.filepath


func connect_gui_perhaps():
	if self.has_connected_gui:
		return
	
	if OK != self.exit_dialog.connect("confirmed", self, "exit"):
		printerr("Failed to connect exit dialog gui.")
	if OK != self.import_dialog.connect("confirmed", self, "_on_ImportDialog_confirmed"):
		printerr("Failed to connect import dialog gui.")
	if OK != self.preview.connect("gui_input", self, "_on_Preview_gui_input"):
		printerr("Failed to connect preview gui input.")
	
	self.has_connected_gui = true


func zoom_level_camera(forward := true) -> void:
	self.level_camera.zoom += (-1 if forward else 1) * Vector2(
		self.camera_zoom_step * 0.618,
		self.camera_zoom_step * 0.618
	)
	self.camera_border.update()


func zoom_preview_camera(forward := true) -> void:
	self.preview_camera.zoom += (-1 if forward else 1) * Vector2(
		self.camera_zoom_step,
		self.camera_zoom_step
	)


func process_zoom_inputs():
	if Input.is_action_just_pressed("zoom_in"):
		if Input.is_key_pressed(KEY_SHIFT):
			zoom_level_camera()
		else:
			zoom_preview_camera()
	
	if Input.is_action_just_pressed("zoom_out"):
		if Input.is_key_pressed(KEY_SHIFT):
			zoom_level_camera(false)
		else:
			zoom_preview_camera(false)


func process_tool_inputs():
	if Input.is_action_just_pressed("editor_zen"):
		self.menu.visible = not self.menu.visible
		self.camera_border.visible = not self.camera_border.visible


func ask_exit_confirmation():
	self.exit_dialog.popup_centered()


func exit():
	Game.go_back()


#  _______    _     __  __
# |__   __|  | |   |  \/  |
#    | | __ _| |__ | \  / | ___ _ __  _   _
#    | |/ _` | '_ \| |\/| |/ _ \ '_ \| | | |
#    | | (_| | |_) | |  | |  __/ | | | |_| |
#    |_|\__,_|_.__/|_|  |_|\___|_| |_|\__,_|
#
#

func _on_PlayButton_pressed():
	var preview_level_pack = preload("res://core/Level.tscn")
	var preview_level = preview_level_pack.instance()
	
	preview_level.editor_live_preview = true
	# return value is skewed by yield
	var _load_err = preview_level.load_from_string(serialize_level())
#	if load_err:
#		printerr("Failed to load the level! %d" % load_err)
#		preview_level.free()
#		return
	Game.switch_to_scene(preview_level, false, true)


func _on_TerrainButton_pressed():
	self.activity.change_activity(self.activity.ACTIVITIES.TERRAIN)


func _on_ConceptsButton_pressed():
	self.activity.change_activity(self.activity.ACTIVITIES.CONCEPTS)


func _on_MetadataButton_pressed():
	self.metadata_dialog.popup_centered_ratio(0.618)


func _on_ExportButton_pressed():
	do_export()
	self.export_dialog.popup_centered_ratio(0.618)
	self.export_dialog.set_base1024_export(self.base1024_export)
	self.export_dialog.set_base256_export(self.base256_export)
	self.export_dialog.set_base64_export(self.base64_export)
	self.export_dialog.set_base16_export(self.base16_export)
	self.export_dialog.set_image_export(self.image_export)


func _on_ImportButton_pressed():
	self.import_dialog.popup_centered_ratio(0.618)


func _on_HelpButton_pressed():
	self.help_dialog.popup_centered_ratio(0.618)


func _on_ExitButton_pressed():
	ask_exit_confirmation()


#  ______                       _
# |  ____|                     | |
# | |__  __  ___ __   ___  _ __| |_
# |  __| \ \/ / '_ \ / _ \| '__| __|
# | |____ >  <| |_) | (_) | |  | |_
# |______/_/\_\ .__/ \___/|_|   \__|
#             | |
#             |_|


const Jsonify = preload("res://lib/jsonify.gd")
const CompressorSerializer = preload("res://lib/CompressorSerializer.gd")


var json_export := ""
var base16_export := ""
var base64_export := ""
var base256_export := ""
var base1024_export := ""
var image_export := Image.new()

var save_filepath := ""


func do_export():
	self.json_export = serialize_level()
	self.base16_export = CompressorSerializer.compress_string(self.json_export)
	self.base64_export = CompressorSerializer.compress_string_64(self.json_export)
	self.base256_export = CompressorSerializer.compress_string_pretty(self.json_export)
	self.base1024_export = CompressorSerializer.compress_string_1024(self.json_export)

	var image = find_node("Previewport").get_texture().get_data()
	image.flip_y()
	image.resize(100, 63)
	self.image_export = CompressorSerializer.compress_string_in_image(self.json_export, image)

	print("Exported the level to shareable strings (here in base 1024):")
	print(self.base1024_export)


func serialize_level() -> String:
	"""
	We prefer JSON to var2str because we want to read it on our server
	and it will be written in Go, most likely.
	"""
	var pickled_level = to_pickle()
	return JSON.print(Jsonify.jsonify(pickled_level))


func to_pickle() -> Dictionary:
	var rick = self.activity.to_pickle()
	rick['meta'] = self.metadata_dialog.pickle()
	rick['editor_version'] = 1
	return rick


func _on_SaveDialog_file_selected(filepath):
	var file = File.new()
	var opened = file.open(filepath, File.WRITE)
	if OK != opened:
		printerr("Could not open file `%s` to save level into it." % filepath)
		breakpoint
		return
	file.store_string(self.json_export)
	file.close()
	prints("Saved level to file:", filepath)


func _on_SaveDialog_image_file_selected(image_file_path):
	print("_on_SaveDialog_image_file_selected")
	var save_error = self.image_export.save_png(image_file_path)

	if OK != save_error:
		printerr("Could not save image level file at `%s`." % image_file_path)
		breakpoint
		return

	prints("Saved level to image file:", image_file_path)


#  _____                            _
# |_   _|                          | |
#   | |  _ __ ___  _ __   ___  _ __| |_
#   | | | '_ ` _ \| '_ \ / _ \| '__| __|
#  _| |_| | | | | | |_) | (_) | |  | |_
# |_____|_| |_| |_| .__/ \___/|_|   \__|
#                 | |
#                 |_|

# I'm really not fond of using Vector2 in keys, here.
# Perhaps we should change this before release.
#{"terrain":{"(-1, -1)":4,"(0, -1)":4,"(-1, 0)":4,"(0, 0)":12,"(1, 0)":4,"(-1, 1)":4,"(0, 1)":4},"concepts":[],"meta":{"title":"","congratulation":"","authors":"","version":"1"},"editor_version":1}

func _on_ImportDialog_confirmed():
	var level_string = self.import_dialog.get_import_string()
	load_level_from_string(level_string)


func load_level_from_string(level_string: String):
	if not level_string:
		return
	
	var level = LevelReference.new()
	var parse_err = level.parse_phiu(level_string)
	if parse_err:
		printerr("Failed to load level string")
		return
	var level_pickle = level.pickle
	if level_pickle:
		load_level_from_pickle(level_pickle)
	else:
		breakpoint  # bad data but no parse error?


func load_level_from_pickle(level_pickle: Dictionary):
	self.activity.load_from_pickle(level_pickle)
	self.metadata_dialog.unpickle(level_pickle['meta'])



func _on_ZoomEditorOutButton_pressed():
	zoom_preview_camera(false)


func _on_ZoomEditorInButton_pressed():
	zoom_preview_camera()


func _on_ZoomLevelOutButton_pressed():
	zoom_level_camera(false)


func _on_ZoomLevelInButton_pressed():
	zoom_level_camera()

