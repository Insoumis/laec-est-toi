extends Node
class_name AppSettingsGenericInput
#class_name AppSettingsGenericField


export var setting : Dictionary


func _ready():
	on_ready()


# Override
func on_ready():
	pass


# Main Override point
# name TBD
func apply_value(value):
	pass
