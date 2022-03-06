tool
extends Node2D


# 
# About making TileSets
# ---------------------
# 
# - Do NOT use translation (node transform)
# - Instead, use Sprite.offset
#   (this is why the Sprites are locked)
# - Sprite.centered is ignored when exporting to TileSet
# - Sprite.visibility is ignored when exporting to TileSet
# 
# 
# About this tool
# ---------------
# 
# This editor tool will not touch invisible sprites.
# We only reconfigure offsets of visible sprites.
# Use the button to reconfigure visible sprites.
# It helps defining a new "root", a new "origin", as an UV value.


# Use this as a Godot editor button
export var reconfigure_offsets := false setget set_reconfigure_offsets

# Will determinate the "root" of the sprite, relative to the sprite size.
export var offset_origin_in_uv_space := Vector2(0.5, 1.0)

# Adjust to your TileMap tile size, probably half of it (may vary)
# This is a raw offset to the sprite offset.
export var offset_origin_adjustment := Vector2(4, 4)


func set_reconfigure_offsets(value: bool) -> void:
	if not value:
		return
	reconfigure_offsets = false
	do_reconfigure_offsets()


func do_reconfigure_offsets():
	for sprite in get_children():
		if not sprite.visible:
			continue  # this tool is destructive enough already
		if sprite is Sprite:
			var sprite_size: Vector2 = sprite.get_texture().get_size()
			sprite.offset = (
				-1.0 * offset_origin_in_uv_space * sprite_size
				+
				offset_origin_adjustment
			)
		

