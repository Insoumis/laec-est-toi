extends Node2D

# Draws the boundaries of the level's camera

export var color := Color.rebeccapurple
export var line_width := 3

var camera: Camera2D  # could use an export NodePath here instead of $adness

var is_ready := false

func _ready():
	self.camera = $"../Level".camera
	#assert(self.camera)
	self.is_ready = true


func _draw():
	if not self.is_ready:
		return
	if not self.camera or not is_instance_valid(self.camera):
		return
	if not self.camera.is_inside_tree():
		return
	
	# Wrong on fullscreen
#	var screen_size = get_node("/root").get_size()
	# Wrong viewport
#	var screen_size = get_viewport_rect().size
	# Works, but what happens when we let users change their resolution?
	var screen_size = Vector2(
		ProjectSettings.get_setting("display/window/size/width"),
		ProjectSettings.get_setting("display/window/size/height")
	)
	# Right now the values are:
#	var screen_size = Vector2(1024, 600)
	
	var half_screen : Vector2 = screen_size / 2.0
	var trans = self.camera.get_transform().affine_inverse()
	
#	print(self.camera.zoom)
	
	var endpoints = [
		trans.xform(- half_screen),
		trans.xform(Vector2(screen_size.x - half_screen.x, - half_screen.y)),
		trans.xform(Vector2(screen_size.x, screen_size.y) - half_screen),
		trans.xform(Vector2(- half_screen.x, screen_size.y - half_screen.y)),
	]
	
	for i in 4:
		var j : int = (i + 1) % endpoints.size()
		draw_line(
			endpoints[i] * self.camera.zoom,
			endpoints[j] * self.camera.zoom,
			color, line_width
		)
