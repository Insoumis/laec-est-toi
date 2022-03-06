extends Node2D


export(NodePath) var portal


func _enter_tree():
	if not self.portal:
		return
	var portal_node = get_node(self.portal)
	if portal_node and portal_node.is_completed():
		queue_free()

