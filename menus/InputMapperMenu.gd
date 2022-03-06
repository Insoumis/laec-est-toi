extends Control

var panel : Panel
var gui : Control


func _enter_tree():
	self.panel = Panel.new()

	add_child(self.panel)
	self.panel.anchor_top = 0.08
	self.panel.anchor_left = 0.08
	self.panel.anchor_right = 0.92
	self.panel.anchor_bottom = 0.92
	self.gui = InputMapper.get_mapping_ui(Game.input_mapper_config)
	add_child(self.gui)
	InputMapper.__is_showing = true


func _exit_tree():
	if self.gui:
		if is_instance_valid(self.gui) and not self.gui.is_queued_for_deletion():
			self.gui.queue_free()


func _input(event):
	#print(event)
	#print("InputMapperMenu: is_showing: ", InputMapper.is_showing())
	if not InputMapper.__is_showing:
		return
	InputMapper.handle_inputs_of_mapping_buttons(event)

