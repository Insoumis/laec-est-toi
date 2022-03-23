extends Control

export var target : NodePath
export var grow_amount : Vector2

export var original_value := Vector2()

func _ready():
#	original_value.x = self.rect_min_size.x
#	original_value.y = self.rect_min_size.y
	get_node(target).connect("visibility_changed", self, "on_visibility_changed")
	pass

func on_visibility_changed():
	if not get_node(target).visible:
		self.rect_min_size += original_value + grow_amount
	else:
		self.rect_min_size = original_value
