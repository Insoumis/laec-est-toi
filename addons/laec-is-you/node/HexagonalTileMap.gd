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


func to_pickle() -> Dictionary:
	# We could also add the other properties (cell size, etc) in here later if we needed
	var rick := Dictionary()
	var cells := Array()
	for cell in get_used_cells():  # cell here means position in the dumb offset-based coords system
		var tile := get_cellv(cell)
		assert(tile != INVALID_CELL)
		cells.append({
			'cell': cell,
			'tile': tile,
			# transpose, flip, etc. left as an exercise to the reader
		})
	rick['cells'] = cells
	return rick


func from_pickle(rick: Dictionary) -> void:
	if not rick.has('cells'):
		printerr("%s.from_pickle: pickle lacks cells." % [get_name()])
		return
	if not (rick['cells'] is Array):
		printerr("%s.from_pickle: pickle cells are not an array." % [get_name()])
		return
	
	clear()
	for element in rick['cells']:
		if not element.has('cell'):
			printerr("%s.from_pickle: pickle cell is missing position." % [get_name()])
			continue
		if not element.has('tile'):
			printerr("%s.from_pickle: pickle cell is missing data." % [get_name()])
			continue
		var tile = int(element['tile'])  # contents
		var cell = element['cell']  # position
		if not cell is Vector2:
			printerr("%s.from_pickle: pickle cell has mangled vector data." % [get_name()])
		
		set_cellv(cell, tile)
