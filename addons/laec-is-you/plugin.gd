tool
extends EditorPlugin


const PATH_CELL_CURSOR := "res://guis/HexagonGui.tscn"
const PATH_LAEC_ADDON := "res://addons/laec-is-you/"
const PATH_ITEM_SELECTOR := PATH_LAEC_ADDON + "ide/ItemSelector.tscn"
const PATH_ITEM_WIZARD := PATH_LAEC_ADDON + 'ide/ItemWizard.tscn'
const PATH_MAIN_SCREEN_PANEL := PATH_LAEC_ADDON + 'ide/TutorialPanel.tscn'
const PATH_LEVEL_BOILERPLATE := PATH_LAEC_ADDON + 'core/BoilerplateLevel.tscn'
const PATH_LEVEL_OUTPUT := 'res://levels'
const PATH_EDITOR_GRID_TEXTURE := "res://addons/laec-is-you/ide/editor_grid.png"
const PATH_ITEM_SCENE := "res://core/Item.tscn"
const PATH_ITEM_SCRIPT := "res://addons/laec-is-you/entity/Item.gd"
const PATH_PORTAL_SCRIPT := "res://addons/laec-is-you/entity/Portal.gd"
const PATH_LEVEL_SCRIPT := "res://addons/laec-is-you/entity/Level.gd"
const PATH_TILE_MAP_SCRIPT := PATH_LAEC_ADDON + 'node/HexagonalTileMap.gd'
const PATH_HEX_TEXTURE := PATH_LAEC_ADDON + 'icon/hexagon.svg'
const PATH_ITEM_DIRECTORY := "res://sprites/items"

# That container is in the top menu of the 2D Editor
var container = CONTAINER_CANVAS_EDITOR_MENU
var items : Array
var items_by_name : Dictionary
var item_wizard_control
var refresh_button
var new_level_button : Button
var import_button : Button
var add_button : MenuButton
var more_button : MenuButton
var text_menu := PopupMenu.new()
var add_preset_menu := PopupMenu.new()
var editor_grid = recreate_editor_grid()
var item_selector : Node = null

var presets := [  # Sentences, be careful with spacing
	'laec is you',
	'france is win',
	'monarc is defeat',
	'wall is stop',
	'media is push',
	'tree has tree',
	'people make people',
]

var cell_cursor #= preload(PATH_CELL_CURSOR).instance()
#var ItemSelector = preload(PATH_ITEM_SELECTOR).instance()
var was_handling : bool = false
var __portal_button


#  _____ _                  __          ___                  _
# |_   _| |                 \ \        / (_)                | |
#   | | | |_ ___ _ __ ___    \ \  /\  / / _ ______ _ _ __ __| |
#   | | | __/ _ \ '_ ` _ \    \ \/  \/ / | |_  / _` | '__/ _` |
#  _| |_| ||  __/ | | | | |    \  /\  /  | |/ / (_| | | | (_| |
# |_____|\__\___|_| |_| |_|     \/  \/   |_/___\__,_|_|  \__,_|
#

# We load() it to avoid dependency cycles
#const LevelScript = preload('entity/Level.gd')


func add_items_to_tree(p_items: Array):
	add_button.get_popup().clear()
	text_menu.name = "text"
	if not text_menu.get_parent() == add_button.get_popup():
		add_button.get_popup().add_child(text_menu)
	add_button.get_popup().add_submenu_item(
		"text", "text"
	)
	
	add_preset_menu.name = "preset"
	if not add_preset_menu.get_parent() == add_button.get_popup():
		add_button.get_popup().add_child(add_preset_menu)
	add_button.get_popup().add_submenu_item("preset", "preset")
	for preset in presets:
		add_preset_menu.add_item(preset)
	
	for item in p_items:
		if item.is_text:
			text_menu.add_item(item.concept)
		else:
			add_button.get_popup().add_item(item.concept)


func get_selection():
	return get_editor_interface().get_selection()


func is_item_layer(node : Node):
	if node.name == "Items" and node is YSort:
		return true
	return false


func are_all_selected_nodes_script(script_path : String, ignore_items_layer := true):
	for selection in get_selection().get_selected_nodes():
		if selection.script:
			if selection.script.resource_path != script_path:
				if not ignore_items_layer:
					return false
				else:
					if not is_item_layer(selection):
						return false
		else:
			if not ignore_items_layer:
				return false
			else:
				if not is_item_layer(selection):
					return false
	if get_selection().get_selected_nodes().size() > 0:
		return true
	else:
		return false


func are_all_selected_nodes_items(ignore_item_layer := true):
	return are_all_selected_nodes_script(PATH_ITEM_SCRIPT, ignore_item_layer)


func are_all_selected_nodes_portals(ignore_item_layer := true):
	return are_all_selected_nodes_script(PATH_PORTAL_SCRIPT, ignore_item_layer)


func is_selected_node_items_layer():
	if get_selection().get_selected_nodes().size() == 1:
		if is_item_layer(get_selection().get_selected_nodes()[0]):
			return true
		return false
	return false
		

func is_editing_a_level():
	var scene_root = get_editor_interface().get_edited_scene_root()
	if scene_root:
		if scene_root.script:
			return scene_root.script.resource_path == "res://addons/laec-is-you/entity/Level.gd"
	else:
		return false

var was_handling_type
const HANDLE_TYPE_PORTAL = 0
const HANDLE_TYPE_ITEM = 1

func has_to_be_handled():
	if (
		is_editing_a_level() and
		(
			are_all_selected_nodes_items() or 
			are_all_selected_nodes_portals() or
			is_selected_node_items_layer()
		)
	):
		return true
	return false

func should_be_refresh():
	if (
		not was_handling 
		or
		(
			(
				are_all_selected_nodes_portals() 
				and 
				not was_handling_type == HANDLE_TYPE_PORTAL
			)
			or
			(
				not are_all_selected_nodes_portals() 
				and 
				was_handling_type == HANDLE_TYPE_PORTAL
			)
			or
			(
				is_selected_node_items_layer()
			)
		)
	):
		return true
	return false

func handles(object: Object):
#	print("was handling:%s" % [was_handling])
	if has_to_be_handled():
		if should_be_refresh():
#			print(get_editor_interface().get_editor_viewport())
			_init_level_editor()
#			print("now handling")
			if are_all_selected_nodes_portals(false):
				was_handling_type = HANDLE_TYPE_PORTAL
				item_selector.visible = false
			else:
				was_handling_type = HANDLE_TYPE_ITEM
				#"item selector now visible")
				item_selector.call_deferred("set_visible", true)
		was_handling = true
#		print("is handling:%s" % [true])
		return true
	if was_handling:
		_clean_level_editor()
#	print("is handling:%s" % [false])
	was_handling = false
	return false

func recreate_cell_cursor():
	cell_cursor = load(PATH_CELL_CURSOR).instance()

func recreate_editor_grid():
	editor_grid = Sprite.new()
	editor_grid.position = Vector2(-6.4, 11.0)
	editor_grid.texture = load(PATH_EDITOR_GRID_TEXTURE)
	editor_grid.scale = Vector2(0.985, 0.928)
	editor_grid.region_enabled = true
	editor_grid.region_rect = Rect2(0.0, 0.0, 2000.0, 2000.0)

func recreate_item_selector():
	item_selector = load(PATH_ITEM_SELECTOR).instance()

func _init_level_editor():
	var scene_root = get_editor_interface().get_edited_scene_root()
	var canvasViewport = get_editor_interface().get_editor_viewport()
	if not is_instance_valid(cell_cursor):
		recreate_cell_cursor()
	if not is_instance_valid(editor_grid):
		recreate_editor_grid()
	if not is_instance_valid(cell_cursor.get_parent()):
		cell_cursor.scale = Vector2(0.827, 0.827)
		scene_root.add_child(cell_cursor)
	if not is_instance_valid(editor_grid.get_parent()):
		cell_cursor.scale = Vector2(0.827, 0.827)
		scene_root.add_child(editor_grid)
	if not is_instance_valid(item_selector):
		recreate_item_selector()
	if not is_instance_valid(item_selector.get_parent()):
		#"adding to viewport the item selector")
		item_selector.set_level_editor(self)
		add_control_to_container(
			EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_RIGHT,
			item_selector
		)
		item_selector.fill_item_container()
	cell_cursor.visible = more_button.get_popup().is_item_checked(MORE_OPTION_DISPLAY_CURSOR)
	editor_grid.visible = more_button.get_popup().is_item_checked(MORE_OPTION_DISPLAY_GRID)
#	more_button.visible = true
#	add_button.visible = true
#	refresh_button.visible = true
	var color_rect = ColorRect.new()
	var center_container = CenterContainer.new()
	
	center_container.add_child(color_rect)
	scene_root.get_parent().get_parent().add_child(center_container)
	color_rect.margin_bottom = 0
	color_rect.margin_top = 0
	color_rect.margin_left = 0
	color_rect.margin_right = 0


func _clean_level_editor():
	remove_control_from_container(
		EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_RIGHT,
		item_selector
	)
	item_selector.queue_free()
#	more_button.visible = false
#	add_button.visible = false
#	refresh_button.visible = false


func index_items():
	self.items = ItemsPool.get_items_sorted_for_editor()
	add_items_to_tree(self.items)


func setup_item_wizard():
	item_wizard_control = load(PATH_ITEM_WIZARD).instance()
	refresh_button = item_wizard_control.find_node("Refresh")
	add_button = item_wizard_control.find_node("Add")
	more_button = item_wizard_control.find_node("More")
	new_level_button = item_wizard_control.find_node("NewLevel")
	import_button = item_wizard_control.find_node("ImportPhiu")
	
	more_button.get_popup().add_check_item("display_grid")
	more_button.get_popup().add_check_item("display_cursor")
	
	add_button.get_popup().connect('index_pressed', self, 'add_item_pressed')
	text_menu.connect('index_pressed', self, 'add_text_pressed')
	add_preset_menu.connect('index_pressed', self, 'add_preset_pressed')
	refresh_button.connect('pressed', self, 'refresh_pressed')
	new_level_button.connect('pressed', self, 'new_level_pressed')
	import_button.connect('pressed', self, 'import_pressed')
	more_button.get_popup().connect('index_pressed', self, 'more_option_pressed')
	
	add_control_to_container(container, item_wizard_control)
	index_items()


func _enter_tree():
	add_custom_type(
		"HexagonalTileMap", "TileMap",
		load(PATH_TILE_MAP_SCRIPT),
		load(PATH_HEX_TEXTURE)
	)
	setup_item_wizard()
	connect("main_screen_changed", self, "on_main_scene_changed")


func _exit_tree():
	if item_selector:
		item_selector.queue_free()
	if cell_cursor:
		cell_cursor.queue_free()
	if add_button:
		add_button.queue_free()
	if import_button:
		import_button.queue_free()
	if refresh_button:
		refresh_button.queue_free()
	remove_custom_type("HexagonalTileMap")
	remove_control_from_container(container, item_wizard_control)


var has_shown_tutorial = false

func on_main_scene_changed(scene_name):
	var main_screen_editor = get_editor_interface().get_editor_viewport().get_node("YouMakeLaec")
	if not has_shown_tutorial:
		if main_screen_editor:
			main_screen_editor.you_make_laec.set_level_editor(self)
			get_editor_interface().set_main_screen_editor("YOU MAKE LAEC")
			has_shown_tutorial = true


var last_portal_selected_ticks = 0
var has_been_released = true

func forward_canvas_gui_input(event):
	var consumed = false
	if event is InputEventMouseButton and event.pressed == false:
		has_been_released = true
	if is_instance_valid(__portal_button):
		if (OS.get_ticks_msec() - last_portal_selected_ticks < 450
			or
			OS.get_ticks_msec() - __portal_button.last_click_ticks < 450):
			if not (event is InputEventMouseButton and event.pressed == false):
				has_been_released
				consumed = has_been_released
		__portal_button._gui_input(event)

	on_canvas_editor_input(event)
	return consumed


func on_canvas_editor_input(event):
	var scene_root = get_tree().get_edited_scene_root()
	var mouse_coords = scene_root.get_global_mouse_position()
	var tilemap : TileMap = get_editor_interface().get_edited_scene_root().find_node("HexagonalTileMap")
	var cell = tilemap.world_to_map(mouse_coords)
	if not is_instance_valid(cell_cursor):
		recreate_cell_cursor()
	if not is_instance_valid(editor_grid):
		recreate_editor_grid()
	cell_cursor.position = tilemap.map_to_world(cell)


var file_dialog : FileDialog

func new_level_pressed():
	file_dialog = FileDialog.new()
	file_dialog.set_access(FileDialog.ACCESS_RESOURCES)
	file_dialog.set_mode(FileDialog.MODE_SAVE_FILE)
	file_dialog.set_current_dir(PATH_LEVEL_OUTPUT)
	file_dialog.add_filter("*.tscn ; Scene File")
	file_dialog.connect("file_selected", self, "create_new_level")
	
	file_dialog.anchor_bottom = 1.0
	file_dialog.anchor_right = 1.0
	file_dialog.call_deferred("set_visible", true)
	file_dialog.call_deferred("update")
	file_dialog.call_deferred("set_current_dir", PATH_LEVEL_OUTPUT)

	get_editor_interface().get_editor_viewport().add_child(file_dialog)


func create_new_level(file_path : String):
	var dir = Directory.new()
	dir.copy(PATH_LEVEL_BOILERPLATE, file_path)
	get_editor_interface().open_scene_from_path(file_path)
	if is_instance_valid(file_dialog):
		file_dialog.queue_free()
	yield(get_tree(), "idle_frame")
	get_editor_interface().set_main_screen_editor("2D")


var import_dialog: ConfirmationDialog

func import_pressed():
	# Since we can't figure out how to 100% unload this node once we've used it,
	# and we don't want to cumulate multiple orphan nodes, but one is OK.
	# We also clean this up when exiting the tree, for good measure
	if is_instance_valid(self.import_dialog) and self.import_dialog:
		self.import_dialog.queue_free()
	
	self.import_dialog = ConfirmationDialog.new()
	self.import_dialog.anchor_bottom = 1.0
	self.import_dialog.anchor_right = 1.0
	# Disabled bc/ of positioning "bug" below
#	self.import_dialog.dialog_text = tr("Paste a PHIU export string in here to load the current level with its data.  This will REPLACE the current level data.")
	
	var field = TextEdit.new()
	field.set_name("PhiuField")
	
	# Bug: none of these have any effect ; prolly container shenanigans
	field.anchor_top = 0.1
	field.margin_top = 200

	self.import_dialog.add_child(field)
	self.import_dialog.set_title("Paste a PHIU to REPLACE level contents")
	self.import_dialog.connect("confirmed", self, "import_confirmed")
	# None of these are triggered on my machine (!?)
#	self.import_dialog.connect("modal_closed", self, "import_canceled")
#	self.import_dialog.connect("popup_hide", self, "import_hide")
#	self.import_dialog.connect("custom_action", self, "import_custom")
	
	get_editor_interface().get_editor_viewport().add_child(self.import_dialog)
	
	self.import_dialog.popup_centered_ratio(0.618)


#func import_custom():
#	printerr("cust")
#func import_hide():
#	printerr("hid")
#func import_canceled():
#	printerr("canceled")


func import_confirmed():
	if not self.import_dialog:
		printerr("Cannot find the import dialog anymore?")
		
	var phiu_field: TextEdit = self.import_dialog.find_node("PhiuField", true, false)
	if not phiu_field:
		printerr("Cannot find the PHIU field.  This is not normal.")
	else:
		var phiu = phiu_field.text
		if not phiu:
			printerr("No PHIU data found in the input field.  Please paste some data.")
		else:
			import_phiu_into_level(phiu)
	
	self.import_dialog.queue_free()


func import_phiu_into_level(phiu: String):
	var level = get_editor_interface().get_edited_scene_root()
	var LevelType = load(PATH_LEVEL_SCRIPT) 
	if not (level is LevelType):
		printerr("Importing PHIU only works on levels.  Create a new level first, or open an existing one.")
		return
	var load_err = level.load_from_string(phiu)
	if OK != load_err:
		printerr("Failed to load the provided PHIU string.")


func refresh_pressed():
	refresh_items()
	#refresh_items(false)  # careful of Item.ready() and snap_to_grid


func refresh_items(xy2hex := true):
	print('[ItemWizard] \\ô/`')
	var level = get_editor_interface().get_edited_scene_root()
	var LevelType = load(PATH_LEVEL_SCRIPT)
	if not (level is LevelType):
		printerr(
			"You may only use this button on Level scenes.\n"+
			"We will hide the button contextually, eventually.\n"+
			"It's a good first contribution ;)"
		)
		return
	
	var amount_snapped = 0
	for item in level.get_all_items_and_portals():
		if xy2hex:
			item.infer_position()
		else:
			item.reposition()
		amount_snapped += 1
	if 0 < amount_snapped:
		print("[ItemWizard] Snapped %d Items." % amount_snapped)

	print("[ItemWizard] Passing turn but only with some of the rules.")
	level.spend_turn(true)

	var amout_updated = 0
	for item in level.get_all_items():
		item.update_sprite()
		item.rename()
		amout_updated += 1
	if 0 < amout_updated:
		print("[ItemWizard] Updated %d Item sprites." % amout_updated)


# ADDING ITEMS

func add_sentence_to_edited_scene(sentence: String, is_text:=false):
	if not get_editor_interface().get_edited_scene_root():
		printerr("Please open a Level scene first in res://levels")
		return
	var item_container = get_editor_interface().get_edited_scene_root().find_node("Items")
	if not is_instance_valid(item_container):
		printerr("Please open a Level scene first in res://levels")	
		return
	
	var concepts = sentence.split(' ')
	assert(concepts)
	var target_tile := Vector2.ZERO
	for concept in concepts:
		add_item_to_edited_scene(concept, is_text, target_tile)
		target_tile += Vector2.RIGHT
	
func add_item_to_edited_scene(concept: String, is_text:=false, on_tile:=Vector2.ZERO):
	if not is_instance_valid(get_editor_interface().get_edited_scene_root()):
		printerr("Please open a Level scene first in res://levels")
		return
	var item_container = get_editor_interface().get_edited_scene_root().find_node("Items")
	if not is_instance_valid(item_container):
		printerr("Please open a Level scene first in res://levels")	
		return
	
	var item  # PoolItem not Dictionary
	var item_name : String
	if is_text:
		item_name = "text_" + concept
	else:
		item_name = concept
	
	item = ItemsPool.get_item_by_concept_full(item_name)
#	item = items_by_name[item_name]
	
	var ItemScene = load(PATH_ITEM_SCENE)
	var item_node = ItemScene.instance()
	
#	if item.direction:
#		item_node.direction = item.direction
#	else:
#		item_node.direction = "right"
	item_node.direction = "right"
	item_node.is_text = is_text
	item_node.animation_state = 0
	item_node.concept_name = item["concept"]
	item_container.add_child(item_node)
	item_node.tile_position = on_tile
#	item_node.cell_position = on_tile
	item_node.reposition(true)
	
	item_node.set_owner(get_editor_interface().get_edited_scene_root())
#	get_editor_interface().get_selection().add_node(item_node)
	yield(get_tree(), "idle_frame")
	refresh_pressed()
	print("%s has been added to the scene" % [ item_name ])
	yield(get_tree(), "idle_frame")
	get_editor_interface().get_selection().call_deferred("clear")
#	clear()
	get_editor_interface().get_selection().call_deferred("add_node", item_node)


func add_item_pressed(id: int):
	add_item_to_edited_scene(
		add_button.get_popup().get_item_text(id)
	)

func add_text_pressed(id: int):
	add_item_to_edited_scene(
		text_menu.get_item_text(id),
		true
	)

func add_preset_pressed(id: int):
	add_sentence_to_edited_scene(
		add_preset_menu.get_item_text(id),
		true
	)

const MORE_OPTION_DISPLAY_GRID := 0
const MORE_OPTION_DISPLAY_CURSOR := 1
func more_option_pressed(id : int):
	if id == MORE_OPTION_DISPLAY_GRID:
		more_button.get_popup().set_item_checked(
			id,
			not more_button.get_popup().is_item_checked(id)
		)
		editor_grid.visible =  more_button.get_popup().is_item_checked(id)
	elif id == MORE_OPTION_DISPLAY_CURSOR:
		more_button.get_popup().set_item_checked(
			id,
			not more_button.get_popup().is_item_checked(id)
		)
		cell_cursor.visible =  more_button.get_popup().is_item_checked(id)
		
