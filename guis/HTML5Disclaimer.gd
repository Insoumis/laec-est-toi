extends ColorRect


func _ready():
	find_node("OkButton").grab_focus()


func _on_OKButton_pressed():
	queue_free()
