extends Reference
# Skip the class_name shenanigans until Godot handles cyclic deps.
#class_name AppSettingsTypeFactory


"""
Base class for type factories.
"""


func create_input_field(setting:Dictionary) -> Control:
	assert(false, "Override this!")
	var field = BaseButton.new()
	if setting.has('title'):
		field.text = setting['title']
	return field


func init_input_field_script(input_field, setting) -> void:
	input_field.setting = setting


func create_label_field(setting:Dictionary) -> Control:
	var label_field := Label.new()
	if setting.has('title'):
#		label_field.bbcode_enabled = true
		# I. This... well... nope.
#		label_field.push_align(RichTextLabel.ALIGN_RIGHT)
#		label_field.append_bbcode(setting['title'])
#		label_field.pop()
		# II. This works
#		label_field.bbcode_text = (
#			"[right]"+
#			setting['title']+
#			"[/right]"
#		)
		label_field.text = setting['title']
	
	return label_field

