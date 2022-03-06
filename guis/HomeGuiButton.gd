extends Control


const Level = preload("res://addons/laec-is-you/entity/Level.gd")


func get_parent_level():
	var parent = get_parent()
	while null != parent:
		if parent is Level:
			return parent
		parent = parent.get_parent()
	return parent


func _on_HomeButton_button_down():
	var level = get_parent_level()
	if not level:
		breakpoint
		return
	
	if level.editor_live_preview:
		var _journey_back = Game.go_back()
	else:
		Game.go_to_pause_menu(level)


func _on_HomeButton_button_up():
	pass
#	Input.action_release("escape")

