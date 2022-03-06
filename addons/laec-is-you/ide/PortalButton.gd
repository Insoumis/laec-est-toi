tool
extends Button


var last_click_ticks := 0  # public


signal double_clicked()


# Deprecated — Remove dependency on LevelEditor and use a signal instead
var level_editor : Node setget set_level_editor
func set_level_editor(le:Node):
	level_editor = le


func _enter_tree():
	self.mouse_filter = MOUSE_FILTER_PASS
	set_process(false)


func _process(delta):
	if OS.get_ticks_msec() - last_click_ticks > 450:
		self.mouse_filter = MOUSE_FILTER_PASS
		set_process(false)


func _pressed():
	#print(OS.get_ticks_msec() - last_click_ticks)
	self.mouse_filter = MOUSE_FILTER_STOP
	set_process(true)
	if OS.get_ticks_msec() - last_click_ticks <= 450:
		emit_signal("double_clicked")
		level_editor.get_editor_interface().open_scene_from_path(level_editor.get_selection().get_selected_nodes()[0].level_path)
	last_click_ticks = OS.get_ticks_msec()

