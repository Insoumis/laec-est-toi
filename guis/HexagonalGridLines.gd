tool
extends Sprite
class_name HexagonalGridLines


const DEFAULT_TEXTURE_PATH := "res://addons/laec-is-you/ide/editor_grid.png"


# In world or parent units, I think?  Really not sure.
export var side_size := 2000.0


func _ready():
	setup()


func setup():
	if not self.texture:
		self.texture = load(DEFAULT_TEXTURE_PATH)
	# magic numbers ; sorry about that
#	self.position = Vector2(-6.4, 11.0)
	self.position = Vector2(-22.318, 20.119)
	self.scale = Vector2(1, 0.711)
	self.region_enabled = true
	self.region_rect = Rect2(
		0.0,			0.0,
		self.side_size,	self.side_size
	)

