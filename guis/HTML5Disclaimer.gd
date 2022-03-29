extends ColorRect


export(String, FILE, "*.tscn") var next_scene_path: String
#export(String, FILE, "*.tscn") var next_scene_path_if_html5: String


var is_gone := false


func _ready():
	find_node("OKButton").grab_focus()


func _on_OKButton_pressed():
#	queue_free()
	go_to_next()


func go_to_next():
	if self.is_gone:
		return
	self.is_gone = true
	if not self.next_scene_path:
		#breakpoint  # do set a scene path?
		return
	var scene_path := self.next_scene_path
#	if true or OS.has_feature("HTML5") and self.next_scene_path_if_html5:
#		scene_path = self.next_scene_path_if_html5
	Game.switch_to_scene_path(scene_path, true, false, true)
