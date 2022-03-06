extends Node2D



func _on_PhiMapLevel_after_action_moved(_direction):
	self.queue_free()
