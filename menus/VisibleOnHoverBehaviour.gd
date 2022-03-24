extends Node

export var button : NodePath

func _ready():
	if is_instance_valid(get_node(button)):
		var _c = get_node(button).connect("focus_entered", self, "on_focus_entered")
		_c = get_node(button).connect("focus_exited", self, "on_focus_exited")

func on_focus_entered():
	get_parent().visible = true

func on_focus_exited():
	get_parent().visible = false
