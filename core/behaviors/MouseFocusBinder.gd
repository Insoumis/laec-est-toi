extends Node
class_name MouseFocusBinder
#class_name MouseGrabFocusBehavior

# The mouse will make the buttons it hovers grab keyboard focus.
# Works on sibling Buttons (for now, extend at will)

func _ready():
	setup()

func setup():
	var _c
	for button in get_buttons():
		#_c = button.connect("focus_entered", self, 'on_button_focused', [button])
		_c = button.connect("mouse_entered", self, 'on_button_mouse_entered', [button])

func on_button_mouse_entered(button: Button):
	button.grab_focus()

#func on_button_focused(button: Button):
#	breakpoint  # grab_focus above does trigger this, we can perhaps offer an APi to extend?

func get_buttons() -> Array:
	var buttons := Array()
	var possible_buttons := get_parent().get_children()
	for possible_button in possible_buttons:
		if possible_button is Button:
			buttons.append(possible_button)
	return buttons
