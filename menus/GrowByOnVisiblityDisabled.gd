extends Control

export var target : NodePath
export var grow_amount : Vector2

export var original_value := Vector2()


func _ready():
#	original_value.x = self.rect_min_size.x
#	original_value.y = self.rect_min_size.y
	if self.target:
		var target_node = get_node(self.target)
		if target_node and is_instance_valid(target_node):
			var _c = target_node.connect("visibility_changed", self, "on_visibility_changed")


func on_visibility_changed():
	if is_instance_valid(get_node(target)):
		if not get_node(target).visible:
			self.rect_min_size += original_value + grow_amount
		else:
			self.rect_min_size = original_value
