tool
extends TileMap


#  _    _        _______ _ _      __  __
# | |  | |      |__   __(_) |    |  \/  |
# | |__| | _____  _| |   _| | ___| \  / | __ _ _ __
# |  __  |/ _ \ \/ / |  | | |/ _ \ |\/| |/ _` | '_ \
# | |  | |  __/>  <| |  | | |  __/ |  | | (_| | |_) |
# |_|  |_|\___/_/\_\_|  |_|_|\___|_|  |_|\__,_| .__/
#                                             | |
#                                             |_|
# HexagonalTileMap
# ----------------
# 
# Auto-configure a TileMap for regular hexagonal tiling
# and perhaps also provide some goodies.
# 
# - Aligns the origins between hex and pixel
# - Friendly Kenney friendly  https://www.kenney.nl/assets?s=hexagon
# 
# Tiles are in the dumb offset-mode coordinates system.
# It's not convenient for spatial operations.
# Use it in conjunction with HexagonalLattice.

# Ratio x/y of the bounding box of a pointy topped hexagon,
# or y/x for a flat topped hexagon.
const XY_RATIO := 0.8660254037844386  # sqrt(3) / 2.0


# Only regular ("square") hexs for simplicity with this parameter.
export(float) var hex_size := 64.0 setget set_hex_size, get_hex_size
export(float) var aspect_ratio := 1.0 setget set_aspect_ratio

# Like this, or experiment with transforms? Rotations would be nice too.
#export(float) var hex_size_x = 64.0 setget set_hex_size_x, get_hex_size_x
#export(float) var hex_size_y = 64.0 setget set_hex_size_y, get_hex_size_y

# The center gets slightly offseted to match the sprites
# Godot complains this variable is not used when it is used in a ternary?
# We moved to a regular `if` to bypass this issue.
export(bool) var kenney_tiles_friendly := true


func _ready():
	reconfigure()


func get_hex_size() -> float:
	return hex_size  # not self.…
func set_hex_size(new_value: float):
	hex_size = new_value  # not self.…
	reconfigure()


func set_aspect_ratio(new_value: float):
	aspect_ratio = new_value  # not self.aspect_ratio
	reconfigure()


func reconfigure() -> void:
	mode = MODE_CUSTOM
	cell_size = Vector2(self.hex_size, self.hex_size * self.aspect_ratio) # cell_custom_transform has priority
	cell_custom_transform = Transform2D(
		Vector2(self.hex_size, 0),
		Vector2(0, self.hex_size * XY_RATIO * self.aspect_ratio),
		Vector2(-0.5 * self.hex_size, -0.5 * self.hex_size * XY_RATIO * self.aspect_ratio)
	)
	cell_half_offset = TileMap.HALF_OFFSET_X


# Patch method to yield the center of the hexagon, for kenney or others.
# This is a confused workaround for cell_tile_origin to center being confusing
func map_to_world(map_position: Vector2, ignore_half_offset:=false) -> Vector2:
	var koff = 0
	if kenney_tiles_friendly:
		koff = 1
	return (
		.map_to_world(map_position, ignore_half_offset)
		+
		Vector2(
			hex_size * 0.5,
			hex_size * XY_RATIO * self.aspect_ratio / (2.0 + koff)
		)
	)
