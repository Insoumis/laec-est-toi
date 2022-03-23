extends Node

export var button : NodePath

func _ready():
	get_node(button).connect("focus_entered", self, "on_focus_entered")
	get_node(button).connect("focus_exited", self, "on_focus_exited")

func on_focus_entered():
	get_parent().visible = true

func on_focus_exited():
	get_parent().visible = false
