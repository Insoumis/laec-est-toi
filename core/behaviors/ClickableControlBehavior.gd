extends Node
class_name ClickableControlBehavior


# IF set, will open that URL
export var url_to_open := ""


onready var clickable_parent: Control = $'..'


func _input(event):
	if (event is InputEventMouseButton) and event.pressed:
		if self.clickable_parent.get_rect().has_point(event.position):
			if self.url_to_open:
				var opened = OS.shell_open(self.url_to_open)
				if opened != OK:
					printerr("Failed to open link")
