extends Control


const PortalScript := preload("res://addons/laec-is-you/entity/Portal.gd")


onready var label := find_node("PortalTitle")


var portal: PortalScript  # instance of the portal on the map


func _ready():
	hide()
	if OK != label.connect("gui_input", self, "_on_label_gui_input"):
		printerr("Failed to connect() to portal title label.")


func _exit_tree():
	self.portal = null


func copy_from_portal(that_portal) -> void:
	assert(that_portal)
	assert(is_instance_valid(that_portal))
	if not that_portal or not is_instance_valid(that_portal):
		return
	
	self.portal = that_portal
	
	# The business with `visible` is to trick Godot into resizing adequately
	self.visible = false
	label.bbcode_text = "[center][shake rate=3 level=4]%s[/shake][/center]" % [
		self.portal.title_displayed,
	]
	label.minimum_size_changed()
	self.visible = true


func _on_label_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			var _opened = self.portal.perhaps_open()


# No need, this is a CanvasItem ; override these to add a fade in/out?
#func show():
#	self.visible = true
#
#
#func hide():
#	self.visible = false

