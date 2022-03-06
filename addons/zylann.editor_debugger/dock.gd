tool
extends Control

const Util = preload("util.gd")

signal node_selected(node)

onready var _inspection_checkbox = get_node("VBoxContainer/HBoxContainer/ShowInInspectorCheckbox")
onready var _print_attributes_checkbox = get_node("VBoxContainer/HBoxContainer/PrintAttributes")
onready var _label = get_node("VBoxContainer/Label")
onready var _tree_view = get_node("VBoxContainer/Tree")
onready var _search_tree_view = get_node("VBoxContainer/SearchTree")
onready var _search_strict_checkbox = get_node("VBoxContainer/StrictCheckButton")
onready var _search_box = get_node("VBoxContainer/SearchBox")
onready var _pack_button = get_node("VBoxContainer/PackButton")


var _update_interval = 1.0
var _time_before_next_update = 0.0
var _control_highlighter = null
var _selected_node : Node = null


func get_tree_view():
	return _tree_view


func _enter_tree():
	if Util.is_in_edited_scene(self):
		return
	_control_highlighter = ColorRect.new()
	_control_highlighter.color = Color(1, 1, 0, 0.2)
	_control_highlighter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_control_highlighter.hide()
	get_viewport().call_deferred("add_child", _control_highlighter)
	_search_box = get_node("VBoxContainer/SearchBox")
	_search_box.connect("text_entered", self, "search_node")
	_pack_button = get_node("VBoxContainer/PackButton")
	_pack_button.connect("pressed", self, "pack_this_scene")
	

func is_query_matching_node(query: String, node: Node, strict := false):
	if strict:
		return node.to_string() == "[" + query + "]"
	else:
		return node.to_string().find(query) != -1

# Act as a register for the following function
var __sit_found_node : Node # local output variable of _search_in_tree
var __sit_found_nodes : Array # local output variable of _search_in_tree

func _search_in_tree(node, node_name, strict = false):
	if is_query_matching_node(node_name, node, strict):
		if strict:
			__sit_found_node = node
		else:
#			var node_dict = Dictionary()
#			node_dict["node"] = node
#			node_dict[""]
			__sit_found_nodes.push_back(node)
			for child in node.get_children():
				_search_in_tree(child, node_name)
	else:
		for child in node.get_children():
			_search_in_tree(child, node_name)
	

func search_node(text : String):
	__sit_found_node = null
	__sit_found_nodes = []
	var strict = _search_strict_checkbox.pressed
	_search_in_tree(get_tree().get_root(), text, strict)
#	print(__sit_found_node)
	_search_tree_view.clear()
	if strict:
		if __sit_found_node:
			_focus_in_tree(__sit_found_node)
		else:
			print("Node %s not found" % [ text ])
	else:
		if(__sit_found_nodes.size() > 0):
			var result_tree_item = _search_tree_view.create_item()
			result_tree_item.set_text(SEARCH_NODE_NAME_COLUMN, "Results")
			for node in __sit_found_nodes:
				var tree_item :TreeItem = _search_tree_view.create_item(result_tree_item)
				tree_item.set_text(SEARCH_NODE_NAME_COLUMN, node.to_string())
				tree_item.set_metadata(SEARCH_META_NODE_REF_COLUMN, node)

func make_children_owned(node: Node, owner: Node, recursive = true):
	for child in node.get_children():
		child.owner = owner
		if recursive:
			make_children_owned(child, owner, true)

func pack_this_scene():
	print(_selected_node)
	if _selected_node:
		make_children_owned(_selected_node, _selected_node, true)
		var scene = PackedScene.new()
		# Only `node` and `rigid` are now packed.
		var result = scene.pack(_selected_node)
		if result == OK:
			var error = ResourceSaver.save("res://packed_node_from_the_editor.tscn", scene)  # Or "user://..."
			if error != OK:
				push_error("An error occurred while saving the scene to disk.")
		else:
			print("Can't pack this node =(, error code from PackedScene.pack: %s" % [result])
	else:
		print("Please select a node before packing it =)")
	print("Remember, for now saving scene messes with Editor's node ownership, so you may restart your editor")



	pass

func print_attributes(node):
	var property_list = []
	for property in node.get_property_list():
		property_list.push_back(property.name)
	var method_list = []
	for method in node.get_method_list():
		method_list.push_back(method.name)
	print("Properties:")
	print("____________ ___________ ___________ _____ _____ _____ _____   ")
	print("| ___ | ___ |  _  | ___ |  ___| ___ |_   _|_   _|  ___/  ___|  _ ")
	print("| |_/ | |_/ | | | | |_/ | |__ | |_/ / | |   | | | |__ \\ `--.  (_)")
	print("|  __/|    /| | | |  __/|  __||    /  | |   | | |  __| `--. \\    ")
	print("| |   | |\\ \\\\ \\_/ | |   | |___| |\\ \\  | |  _| |_| |___/\\__/ /  _ ")
	print("\\_|   \\_| \\_|\\___/\\_|   \\____/\\_| \\_| \\_/  \\___/\\____/\\____/  (_)")
	print(property_list)
	print("___  ________ _____ _   _ ___________ _____")
	print("|  \\/  |  ___|_   _| | | |  _  |  _  /  ___|  _ ")
	print("| .  . | |__   | | | |_| | | | | | | \\ `--.  (_)")
	print("| |\\/| |  __|  | | |  _  | | | | | | |`--. \\    ")
	print("| |  | | |___  | | | | | \\ \\_/ | |/ //\\__/ /  _ ")
	print("\\_|  |_\\____/  \\_/ \\_| |_/\\___/|___/ \\____/  (_)")                 
	print(method_list)

func _on_search_Tree_nothing_selected():
	_control_highlighter.hide()

const SEARCH_NODE_NAME_COLUMN = 0
const SEARCH_META_NODE_REF_COLUMN = 0

func _on_search_Tree_item_selected():
	var node_view = _search_tree_view.get_selected()
#	print(node_view.get_metadata(SEARCH_META_NODE_REF_COLUMN))
	var node = node_view.get_metadata(SEARCH_META_NODE_REF_COLUMN)
	_focus_in_tree(node)
	if _print_attributes_checkbox.pressed:
		print_attributes(node)
	
#	print("Selected ", node)
#
#	_highlight_node(node)
#
#	emit_signal("node_selected", node)

func _exit_tree():
	if _control_highlighter != null:
		_control_highlighter.queue_free()


func _process(delta):
	if Util.is_in_edited_scene(self):
		set_process(false)
		return
		
	var viewport = get_viewport()
	_label.text = str(viewport.get_mouse_position())
	
	_time_before_next_update -= delta
	if _time_before_next_update <= 0:
		_time_before_next_update = _update_interval
		_update_tree()


func _update_tree():
	var root = get_tree().get_root()
	if root == null:
		_tree_view.clear()
		return

	#print("Updating tree")
	
	var root_view = _tree_view.get_root()
	if root_view == null:
		root_view = _create_node_view(root, null)
	
	_update_branch(root, root_view)


func _update_branch(root, root_view):
	if root_view.collapsed and root_view.get_children() != null:
		# Don't care about collapsed nodes.
		# The editor is a big tree, don't waste cycles on things you can't see
		return
	
	var children_views = _get_tree_item_children(root_view)
	
	for i in root.get_child_count():
		var child = root.get_child(i)
		var child_view
		if i >= len(children_views):
			child_view = _create_node_view(child, root_view)
			children_views.append(child_view)
		else:
			child_view = children_views[i]
			var child_view_name = child_view.get_metadata(0)
			if child.name != child_view_name:
				_update_node_view(child, child_view)
		_update_branch(child, child_view)
	
	if root.get_child_count() < len(children_views):
		for i in range(root.get_child_count(), len(children_views)):
			children_views[i].free()


func _create_node_view(node, parent_view):
	#print("Create view for ", node)
	assert(node is Node)
	assert(parent_view == null or parent_view is TreeItem)
	var view = _tree_view.create_item(parent_view)
	view.collapsed = true
	_update_node_view(node, view)
	return view


func _update_node_view(node, view):
	assert(node is Node)
	assert(view is TreeItem)
	view.set_text(0, str(node.get_class(), ": ", node.name))
	view.set_metadata(0, node.name)

			
static func _get_tree_item_children(item):
	var children = []
	var child = item.get_children()
	if child == null:
		return children
	children.append(child)
	child = child.get_next()
	while child != null:
		children.append(child)
		child = child.get_next()
	return children

func _on_Tree_item_selected():
	var node_view = _tree_view.get_selected()
	var node = _get_node_from_view(node_view)
	self._selected_node = node
	print("Selected ", node)
	
	_highlight_node(node)
	
	emit_signal("node_selected", node)
	if _print_attributes_checkbox.pressed:
		print_attributes(node)


func _highlight_node(node):
	if node == null:
		_control_highlighter.hide()
	elif node is Control:
		var r = node.get_global_rect()
		_control_highlighter.rect_position = r.position
		_control_highlighter.rect_size = r.size
		_control_highlighter.show()
	else:
		_control_highlighter.hide()


func _get_node_from_view(node_view):
	if node_view.get_parent() == null:
		return get_tree().get_root()
	
	# Reconstruct path
	var path = node_view.get_metadata(0)
	var parent_view = node_view
	while parent_view.get_parent() != null:
		parent_view = parent_view.get_parent()
		# Exclude root
		if parent_view.get_parent() == null:
			break
		path = str(parent_view.get_metadata(0), "/", path)
	
	var node = get_tree().get_root().get_node(path)
	return node


func _focus_in_tree(node):
	_update_tree()
	
	var parent = get_tree().get_root()
	var path = node.get_path()
	var parent_view = _tree_view.get_root()
	
	var node_view = null
	
	for i in range(1, path.get_name_count()):
		var part = path.get_name(i)
#		print(part)
		
		var child_view = parent_view.get_children()
		if child_view == null:
			_update_branch(parent, parent_view)
		
		child_view = parent_view.get_children()
		
		while child_view != null and child_view.get_metadata(0) != part:
			child_view = child_view.get_next()
		
		if child_view == null:
			node_view = parent_view
			break
		
		node_view = child_view
		parent = parent.get_node(part)
		parent_view = child_view
	
	if node_view != null:
		_uncollapse_to_root(node_view)
		node_view.select(0)
		_tree_view.ensure_cursor_is_visible()


static func _uncollapse_to_root(node_view):
	var parent_view = node_view.get_parent()
	while parent_view != null:
		parent_view.collapsed = false
		parent_view = parent_view.get_parent()


static func _get_index_path(node):
	var ipath = []
	while node.get_parent() != null:
		ipath.append(node.get_index())
		node = node.get_parent()
	ipath.invert()
	return ipath


func _on_Tree_nothing_selected():
	self._selected_node = null
	_control_highlighter.hide()


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_F12:
				pick(get_viewport().get_mouse_position())


func pick(mpos):
	var root = get_tree().get_root()
	var node = _pick(root, mpos)
	if node != null:
		print("Picked ", node, " at ", node.get_path())
		_focus_in_tree(node)
	else:
		_highlight_node(null)


func is_inspection_enabled():
	return _inspection_checkbox.pressed


func _pick(root, mpos, level = 0):
	
#	var s = ""
#	for i in level:
#		s = str(s, "  ")
#
#	print(s, "Looking at ", root, ": ", root.name)
	
	var node = null
	
	for i in root.get_child_count():
		var child = root.get_child(i)
		
		if (child is CanvasItem and not child.visible):
			#print(s, child, " is invisible or viewport")
			continue
		if child is Viewport:
			continue
		if child == _control_highlighter:
			continue
		
		if child is Control and child.get_global_rect().has_point(mpos):
			var c = _pick(child, mpos, level + 1)
			if c != null:
				return c
			else:
				node = child
		else:
			var c = _pick(child, mpos, level + 1)
			if c != null:
				return c
	
	return node


func _on_ShowInInspectorCheckbox_toggled(button_pressed):
	pass

