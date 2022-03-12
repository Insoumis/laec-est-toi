tool
extends Control

const SIZE_ICON_BASE := 64.0

var items_position_by_name := Dictionary()
onready var _item_container : ItemList = get_node("ItemListContainer/ItemContainer")
onready var _direction_container : ItemList = get_node("ItemListContainer/DirectionContainer")
onready var _item_sizer : HSlider = get_node("ItemSizer")
onready var _item_search : LineEdit = get_node("SearchBox")
onready var _repaint_button : Button = get_node("Repaint")
onready var _rescan_button : Button = get_node("Rescan")


var level_editor : EditorPlugin setget set_level_editor

func set_level_editor(p_level_editor: EditorPlugin):
	level_editor = p_level_editor
	
func reset_bg_colors():
	for i in range(_item_container.get_item_count()):
		_item_container.set_item_custom_bg_color(i, Color(0, 0, 0, 0))

func get_selection():
	return level_editor.get_editor_interface().get_selection()

func refresh_item_selector_from_selected_nodes(nodes : Array):
	if nodes.size() == 1:
		if nodes[0] is YSort and nodes[0].name == "Items":
			reset_bg_colors()
			_item_container.update()
			return
	for node in nodes:
		if node.name == "Items" and node is YSort:
			continue
		var concept
		if node.is_text:
			concept = "text_" + node.concept_name
		else:
			concept = node.concept_name
		var item_id = items_position_by_name[concept]
		
		
		_item_container.set_item_custom_bg_color(item_id, Color(0.3, 0.7, 0.4, 0.7))
		_item_container.update()


#  _____           _        _
# |  __ \         | |      | |
# | |__) |__  _ __| |_ __ _| |___
# |  ___/ _ \| '__| __/ _` | / __|
# | |  | (_) | |  | || (_| | \__ \
# |_|   \___/|_|   \__\__,_|_|___/
#
#

const PortalButton = preload("res://addons/laec-is-you/ide/PortalButton.tscn")
var __portal_guis := Array()


func clean_portal_guis():
	for gui in __portal_guis:
		gui.queue_free()
	__portal_guis.clear()
#	var nodes = 
	#is_inside_tree())
	var scene_root = level_editor.get_tree().get_edited_scene_root()
	if not is_instance_valid(scene_root):
		return
	var items_node = scene_root.find_node("Items")
	if not is_instance_valid(items_node):
		return
	var nodes = items_node.get_children()
	for node in nodes:
		var gui = node.find_node('*PortalGuiHint*', true, false)
		if not is_instance_valid(gui):
			continue
		gui.queue_free()


func clean_portal_button():
	if is_instance_valid(level_editor.__portal_button):
		level_editor.__portal_button.queue_free()
	level_editor.__portal_button = null

var CopyLabelSizeToParent = load("res://lib/CopyLabelSizeToParentBehaviour.gd")

func refresh_portals_from_selected_nodes(nodes: Array):
	for node in nodes:
		if level_editor.is_item_layer(node):
			continue
		var portal_gui = Node2D.new()
		portal_gui.z_index = 30
		var portal_panel_gui = Panel.new()
		portal_panel_gui.size_flags_horizontal = Control.SIZE_EXPAND
		var portal_vbox_gui = VBoxContainer.new()
		portal_vbox_gui.size_flags_horizontal = Control.SIZE_EXPAND
		portal_vbox_gui.margin_top = 10
		portal_vbox_gui.margin_left = 10
		portal_vbox_gui.margin_right = 10
		portal_vbox_gui.margin_bottom = 15
		var portal_title_label = Label.new()
		var portal_label = Label.new()
		var portal_dependencies_label = Label.new()
		portal_gui.set_name("PortalGuiHint")
		var title = ""
		if node.title_override != "":
			title = node.title_override
		elif node.title != "":
			title = node.title
		portal_title_label.set_text("Title: " + title)
		portal_label.set_text("Scene path: " + node.level_path)
		
		node.add_child(portal_gui)
		portal_gui.add_child(portal_panel_gui)
		if (
			node.dependency_a != "" and
			node.dependency_a and 
			is_instance_valid(node.get_node(node.dependency_a))
		):
			var line = Line2D.new()
			line.z_index = -1
			portal_gui.add_child(line)
			line.add_point(Vector2(0.0, 0.0))
			portal_dependencies_label.set_text("Dependency: " + node.get_node(node.dependency_a).name)
			line.add_point(node.get_node(node.dependency_a).get_global_position() - node.get_global_position())
		portal_panel_gui.add_child(portal_vbox_gui)
		portal_vbox_gui.add_child(portal_title_label)
		portal_vbox_gui.add_child(portal_label)
		portal_vbox_gui.add_child(portal_dependencies_label)
		var size_copier = CopyLabelSizeToParent.new()
		size_copier.target_node = portal_panel_gui
		size_copier.parent_node = portal_vbox_gui
		portal_gui.add_child(size_copier)
		__portal_guis.push_back(portal_gui)
	if 1 == nodes.size():
		var node = nodes[0]
		level_editor.__portal_button = PortalButton.instance()
		node.add_child(level_editor.__portal_button)
		level_editor.last_portal_selected_ticks = OS.get_ticks_msec()
		level_editor.__portal_button.level_editor = level_editor
		level_editor.__portal_button.last_click_ticks = OS.get_ticks_msec()
		level_editor.has_been_released = false


func on_selection_changed():
	clean_portal_button()
	clean_portal_guis()
	if not level_editor.are_all_selected_nodes_items():
		if not level_editor.are_all_selected_nodes_portals():
			if not level_editor.is_selected_node_items_layer():
				return
	reset_bg_colors()
	#print("reseted background")
	var selection = get_selection()
	if level_editor.are_all_selected_nodes_portals(false):
		refresh_portals_from_selected_nodes(
			selection.get_selected_nodes()
		)
	else:
		refresh_item_selector_from_selected_nodes(
			selection.get_selected_nodes()
		)


func get_item_brush_selected():
	var selected_brushes = _item_container.get_selected_items()
	if not selected_brushes:
		printerr("No brushes in the brushes container.")
		return null
	if selected_brushes.empty():
		return -1
	return selected_brushes[0]


func on_repaint_pressed():
	repaint_selected_items()


func repaint_selected_items():
	if not level_editor.are_all_selected_nodes_items(false):
		printerr("You must only select Items from the Scene editor before pressing repaint")
		return
	var selected_item_brush = get_item_brush_selected()
	if selected_item_brush < 0:
		printerr("Select an item brush in the dock on the right.")
		return
	
	#print("start repainting")
	var selected_nodes := Array()
	var selection : EditorSelection = get_selection()
	for node in selection.get_selected_nodes():
		selected_nodes.push_back(node)
		var game_item = _item_container.get_item_metadata(selected_item_brush)
		#print(game_item)
		node.concept_name = game_item["concept"]
		node.is_text = game_item["is_text"]
		#print(node.concept_name)
	
	level_editor.refresh_pressed()
	call_deferred("reselect_nodes", selected_nodes)


func on_rescan_pressed():
	#print("Indexing all items…")
	ItemsPool.recollect_items()
	level_editor.index_items()
	#print("Filling item container…")
	fill_item_container()
	print("Generating spriteframes…")
	AtlasSpriteFramesFactory.generate_spriteframes(ItemsPool.list_items_sorted())
	AtlasSpriteFramesFactory.load_from_files()
	level_editor.get_editor_interface().inspect_object(AtlasSpriteFramesFactory.data_cache)
	print("Done scanning item sprites.")


func on_brush_activated(brush_item):
	repaint_selected_items()


func reselect_nodes(nodes : Array):
	var selection : EditorSelection = get_selection()
	selection.clear()
	for node in nodes:
		selection.add_node(node)

	
func fill_item_container():
	_item_container.clear()
	items_position_by_name.clear()
	var i := 0
	for item in level_editor.items:
		items_position_by_name[item.concept_full] = i
		_item_container.add_item(item.concept)
		_item_container.set_item_metadata(
			i,
			item
		)
		_item_container.set_item_icon(
			i, 
			load(
				level_editor.PATH_ITEM_DIRECTORY +
				"/" +
				item.filepaths_relative[0]
			)
		)
		i += 1


func item_sizer_changed(value: float):
	var icon_size = SIZE_ICON_BASE * value
	_item_container.fixed_column_width = icon_size
	_item_container.fixed_icon_size = Vector2(icon_size, icon_size)

func _exit_tree():
	clean_portal_button()
	clean_portal_guis()

func _enter_tree():
	_item_container = get_node("ItemListContainer/ItemContainer")
	_direction_container = get_node("ItemListContainer/DirectionContainer")
	_item_sizer = get_node("ItemSizer")
	_item_search = get_node("SearchBox")
	_repaint_button = get_node("Repaint")
	_rescan_button = get_node("Rescan")
	_item_sizer.connect("value_changed", self, "item_sizer_changed")
	
	_repaint_button.connect("pressed", self, "on_repaint_pressed")
	_rescan_button.connect("pressed", self, "on_rescan_pressed")
	
	var selection = level_editor.get_editor_interface().get_selection()
	selection.connect("selection_changed", self, "on_selection_changed")
#	fill_item_container()

	_item_container.connect("item_activated", self, 'on_brush_activated')
