extends RigidBody2D


# Somthing that repesents a level in our visualization.

func _process(_delta):
	# hack against physics rotation
	$Info.global_rotation = 0.0
	$Sprite.global_rotation = 0.0

func set_filepath(filepath: String):
	$Info/Info/Filepath.text = filepath


func _on_Interact_mouse_entered():
	$Info.visible = true


func _on_Interact_mouse_exited():
	$Info.visible = false
