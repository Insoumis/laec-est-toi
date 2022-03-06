extends "res://addons/open-hexes.appsettings/types/type_factory.gd"


"""
Create a input field where we can select *one* value amongst a few.
"""


func create_input_field(setting:Dictionary) -> Control:
	var field := OptionButton.new()
	if setting.has('title'):
		field.text = setting['title']
	
	var id := 0
	for option in setting['options']:
		field.add_item(option['title'], id)
		if setting.has('default'):
			if setting['default'] == option['value']:
				field.select(id)
		id += 1
	
	return field

