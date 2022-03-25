extends Sprite


signal pouicked


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		
		emit_signal("pouicked")
		$AnimationPlayer.stop(true)
		$AnimationPlayer.play("Pouic")

		# Show the old background animation as an easter egg
		if Input.is_key_pressed(KEY_CONTROL):
			var start_menu: Control = get_tree().get_root().find_node('StartMenu', false, false)
			if start_menu:
				var oldies = start_menu.find_node('OldBackground')
				oldies.visible = true
				self.visible = true
