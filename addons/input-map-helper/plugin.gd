tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton('InputMapper', "res://addons/input-map-helper/InputMapper.gd")
	pass


func _exit_tree():
	remove_autoload_singleton('InputMapper')
	pass
