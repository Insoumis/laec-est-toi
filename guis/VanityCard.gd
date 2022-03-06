extends Sprite


signal pouicked


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		
		emit_signal("pouicked")
		$AnimationPlayer.stop(true)
		$AnimationPlayer.play("Pouic")

