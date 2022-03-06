extends "res://addons/open-hexes.appsettings/types/type_factory.gd"


"""
Create a slider field allowing toselect a value within a range.
"""


func create_input_field(setting:Dictionary) -> Control:
	var field = HSlider.new()
	
	if setting.has('minimum'):
		field.min_value = setting['minimum']
	
	if setting.has('maximum'):
		field.max_value = setting['maximum']
	
	if setting.has('step'):
		field.step = setting['step']
	
	return field

