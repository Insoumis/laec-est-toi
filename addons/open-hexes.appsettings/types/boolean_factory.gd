extends "res://addons/open-hexes.appsettings/types/type_factory.gd"


"""
Create a simple ON/OFF toggler for boolean settings.
"""


func create_input_field(setting:Dictionary) -> Control:
	var field = CheckButton.new()
	# Do not use the text property, we are making our own rich text label
	# so we can align labels with inputs.
#	if setting.has('title'):
#		field.text = setting['title']
	return field

