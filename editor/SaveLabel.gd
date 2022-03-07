extends Label

func _ready():
	get_level_editor().connect("level_saved", self, "_on_level_saved")


func _on_level_saved(filepath):
	$AnimationPlayer.play("flash")


var __level_editor


func get_level_editor() -> Control:
	if __level_editor:
		return __level_editor
	
	# Dynamic loading to avoid cyclic deps, cheap but works
	var LevelEditor = load("res://editor/LevelEditor.gd")
	var le = get_parent()
	while le:
		if le and le is LevelEditor:
			__level_editor = le
			return le
		le = le.get_parent()
	breakpoint  # requires parent LevelEditor
	return null
