tool
extends Node

var target_node : Control
var parent_node : Control
export var target_node_path : NodePath
export var parent_node_path : NodePath

var x_max = 0
var y_max = 0

func update_max_sizes():
	x_max = 0
	y_max = 0
	if parent_node is VBoxContainer:
		for child_label in parent_node.get_children():
			if child_label is Control:
				y_max += child_label.rect_size.y
			if child_label is Label:
				x_max = max(float(x_max), child_label.rect_size.x)
	if parent_node is HBoxContainer:
		for child_label in parent_node.get_children():
			if child_label is Control:
				x_max += child_label.rect_size.x
			if child_label is Label:
				y_max = max(float(y_max), child_label.rect_size.y)
	if parent_node is Control:
		y_max += parent_node.margin_top
		y_max += parent_node.margin_bottom
		x_max += parent_node.margin_left
		x_max += parent_node.margin_right

func _ready():
	if target_node_path and target_node_path != "":
		target_node = get_node(target_node_path)
	if parent_node_path and parent_node_path != "":
		parent_node = get_node(parent_node_path)
	for child_label in parent_node.get_children():
		if child_label is Label:
			child_label.connect("resized", self, "label_resized")
	if not is_instance_valid(target_node) or not target_node is Control:
		printerr("CopyLabelSizeRToParent: target node is not a valid instance nor a control node")
		return
	if not is_instance_valid(parent_node) or not parent_node is Control:
		printerr("CopyLabelSizeRToParent: parent node is not a valid instance nor a control node")
		return
	update_max_sizes()
	target_node.rect_size.x = int(x_max)
	target_node.rect_size.y = int(y_max)

func label_resized():
	if not is_instance_valid(target_node) or not target_node is Control:
		printerr("CopyLabelSizeRToParent: target node is not a valid instance nor a control node")
		return
	if not is_instance_valid(parent_node) or not parent_node is Control:
		printerr("CopyLabelSizeRToParent: parent node is not a valid instance nor a control node")
		return
	update_max_sizes()
	target_node.rect_size.x = int(x_max)
	target_node.rect_size.y = int(y_max)
