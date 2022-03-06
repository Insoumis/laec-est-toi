extends Control


func _ready():
	find_node("YesButton").grab_focus()


func _on_YesButton_button_down():
	Game.switch_to_level(Game.entrypoint_button_check_level_scene_path, true, false)


func _on_NoButton_button_down():
	Game.switch_to_story_mode(true)
