extends ColorRect


func _ready():
	find_node("OKButton").grab_focus()


func _on_OKButton_pressed():
	queue_free()
