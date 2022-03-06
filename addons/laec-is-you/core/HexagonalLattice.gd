extends Reference
class_name HexagonalLattice

#  _    _                       _           _   _   _
# | |  | |                     | |         | | | | (_)
# | |__| | _____  ____ _       | |     __ _| |_| |_ _  ___ ___
# |  __  |/ _ \ \/ / _` |      | |    / _` | __| __| |/ __/ _ \
# | |  | |  __/>  < (_| |      | |___| (_| | |_| |_| | (_|  __/
# |_|  |_|\___/_/\_\__,_|gonal |______\__,_|\__|\__|_|\___\___|
#
# HexagonalLattice v0.0.0
# -----------------------
# 
# Hasty, incomplete abstraction of a hexagonal lattice.
# You should be able to store anything in it.
# 
# It also handles conversion from and to pixel space, to patch Godot3 TileMap's
# incorrect conversion, since it does not natively support hexagons (yet).
# That is likely to change in Godot4.
# 
# This is essentially a wrapper for a Dictionary,
# storing a list of Items for each cell (Vector2).
# Eventually it will maintain an ordered index as well, for determinism.
#
#
# Semantics
# ---------
# 
# - Tile = Coordinates in offset-mode from the TileMap
# - Cell = Coordinates in cube-mode, but only x and z
# - Cube = Coordinates in cube-mode (Vector3)
# 
# 
# Features
# --------
# 
# - [x] Sparse
# - [x] Pointy Topped
# - [ ] Flat Topped
# - [~] Cell size  (world and pixelspace conversion)
# 


const SQRT_3 := 1.7320508075688772  # square root of three
const XY_RATIO := SQRT_3 / 2.0  # hexagon's bounding box ratio


# The thing is a Variant, and the cell is a Vector2 in cell space.  (see above)
signal thing_added(thing, on_cell)
signal thing_removed(thing, from_cell)

# Since our matrix is sparse, cells are added or removed automatically.
# We send signals whenever a cell is added or removed to the sparse matrix.
signal cell_added(cell)
signal cell_removed(cell)


#   _____             __ _                       _   _
#  / ____|           / _(_)                     | | (_)
# | |     ___  _ __ | |_ _  __ _ _   _ _ __ __ _| |_ _  ___  _ __
# | |    / _ \| '_ \|  _| |/ _` | | | | '__/ _` | __| |/ _ \| '_ \
# | |___| (_) | | | | | | | (_| | |_| | | | (_| | |_| | (_) | | | |
#  \_____\___/|_| |_|_| |_|\__, |\__,_|_|  \__,_|\__|_|\___/|_| |_|
#                           __/ |
#                          |___/

# Akin to the width in pixels of a pointy-topped hexagon (pth).
# Used in conversion to and from pixel space.
var hex_size := 64.0

# Y/X ratio to "flatten" the hexagons.
# Used in conversion to and from pixel space.
var aspect_ratio := 1.0

# Adjustment for kenney-style hexagon sprites.
var kenney := false


#  _____        _              __  __
# |  __ \      | |         _  |  \/  |
# | |  | | __ _| |_ __ _  (_) | \  / | __ _ _ __
# | |  | |/ _` | __/ _` |     | |\/| |/ _` | '_ \
# | |__| | (_| | || (_| |  _  | |  | | (_| | |_) |
# |_____/ \__,_|\__\__,_| (_) |_|  |_|\__,_| .__/
#                                          | |
#                                          |_|
# Each cell may hold an array of variants.
# The map is sparse, meaning that cells are created on-demand.
# Since our coordinates are Vectors, we have the same maximum limits.

# Vector2 cell => Array of Variants
var map := Dictionary()


func reset_map() -> void:
	# TBD: emit many cell_removed signals here?  Or a single cell_reset signal?
	self.map.clear()


func is_cell_used(cell: Vector2):
	return self.map.has(cell)


func get_used_cells() -> Array:
	return self.map.keys()  # consistent order not guaranteed (ours should be!)


func get_things() -> Array:
	var all_things := Array()
	
	for cell in get_used_cells():
		for thing in get_things_on_cell(cell):
			assert(not all_things.has(thing), "A thing is in two places at once !")
			all_things.append(thing)
	
	return all_things


func has_thing_on_cell(cell: Vector2) -> bool:
	return not find_on_cell(cell).empty()


func has_thing_on_tile(tile: Vector2) -> bool:
	return not find_on_cell(cell_from_tile(tile)).empty()


func get_things_on_cell(cell: Vector2) -> Array:
	return self.map.get(cell, Array())

	
func get_on_cell(cell: Vector2) -> Array:
	return get_things_on_cell(cell)


func find_on_cell(cell: Vector2) -> Array:
	return get_things_on_cell(cell)


func find_at(cell: Vector2) -> Array:
	return get_things_on_cell(cell)


func find(cell: Vector2) -> Array:
	return get_things_on_cell(cell)


# You can also use get() to fetch things on the lattice.
# Override of a method doing totally something else.  Bad design, probably.
# That being said, the "official" get() API is absurd when used with Vectors,
# so we allow ourselves this sharp edge, and if it bleeds we'll learn!
# Use any other accessor alias if it bothers you.
func get(on_cell):
	if on_cell is Vector2:
		return get_on_cell(on_cell)
	
	# Pipe to the usual reflection method
	return .get(on_cell)


# Really not sure about the order of parameters here -_-
func add(thing, on_cell: Vector2):
	breakpoint  # Let's deprecate this for now, perhaps.
	add_thing_on_cell(thing, on_cell)


func add_thing_on_cell(thing, on_cell: Vector2):
	__perhaps_create_cell(on_cell)
	self.map[on_cell].append(thing)
	emit_signal("thing_added", thing, on_cell)


func remove_thing_on_cell(thing, on_cell: Vector2):
	if not is_cell_used(on_cell):
		return
	if not (thing in self.map[on_cell]):
		return
	self.map[on_cell].erase(thing)
	__perhaps_remove_cell(on_cell)
	emit_signal("thing_removed", thing, on_cell)


func remove_thing(thing):
	for cell in get_used_cells():
		remove_thing_on_cell(thing, cell)


func __perhaps_create_cell(cell: Vector2):
	if not is_cell_used(cell):
		self.map[cell] = Array()
		emit_signal("cell_added", cell)


func __perhaps_remove_cell(cell: Vector2):
	if not is_cell_used(cell):
		return
	if self.map[cell].empty():
		self.map.erase(cell)
		emit_signal("cell_removed", cell)



#  _____ _          _   _                     _
# |  __ (_)        | | | |                   | |
# | |__) |__  _____| | | |     __ _ _ __   __| |
# |  ___/ \ \/ / _ \ | | |    / _` | '_ \ / _` |
# | |   | |>  <  __/ | | |___| (_| | | | | (_| |
# |_|   |_/_/\_\___|_| |______\__,_|_| |_|\__,_|
#
#

func cell_to_pixel(cell: Vector2) -> Vector2:
	var hex_radius := self.hex_size / SQRT_3
	return cell_to_pix(cell, hex_radius, self.aspect_ratio, self.kenney)


func pixel_to_cell(pixel: Vector2) -> Vector2:
	var hex_radius := self.hex_size / SQRT_3
	return pix_to_cell(pixel, hex_radius, self.aspect_ratio, self.kenney)
	


static func cell_to_pix(
		cell: Vector2,
		hex_radius := 1.0,
		aspect_ratio := 1.0,
		kenney := false
	) -> Vector2:
	var offset = Vector2.ZERO
	if kenney:
		offset = Vector2(
			0,
			- hex_radius * XY_RATIO * aspect_ratio / (2.0 + 1.0)
		)
	return offset + Vector2(
		hex_radius * SQRT_3 * (cell.x + cell.y * 0.5),
		hex_radius * 1.5 * cell.y * aspect_ratio
	)


static func pix_to_cell(
		xy: Vector2,
		hex_radius := 1.0,
		aspect_ratio := 1.0,
		kenney := false
	) -> Vector2:
	if kenney:
		xy += Vector2(
			0,
			hex_radius * XY_RATIO * aspect_ratio / (2.0 + 1.0)
		)
	xy *= Vector2(1.0, 1.0/aspect_ratio)
	var q = (xy.x * SQRT_3/3.0 - xy.y/3.0) / hex_radius
	var r = xy.y * (2.0/3.0) / hex_radius
	return round_cell(Vector2(q, r))


#   _____                              _
#  / ____|                            (_)
# | |     ___  _ ____   _____ _ __ ___ _  ___  _ __  ___
# | |    / _ \| '_ \ \ / / _ \ '__/ __| |/ _ \| '_ \/ __|
# | |___| (_) | | | \ V /  __/ |  \__ \ | (_) | | | \__ \
#  \_____\___/|_| |_|\_/ \___|_|  |___/_|\___/|_| |_|___/
#
#


static func cell_from_cube(cube) -> Vector2:
	return Vector2(cube.x, cube.z)


static func cube_to_cell(cube) -> Vector2:
	return cell_from_cube(cube)


static func cube_from_cell(cell) -> Vector3:
	var x = cell.x
	var z = cell.y
	var y = -x-z
	return Vector3(x, y, z)


static func cell_to_cube(cell) -> Vector3:
	return cube_from_cell(cell)


# From https://www.redblobgames.com/grids/hexagons/implementation.html
# There are four offset types: odd-r, even-r, odd-q, even-q.
# The “r” types are used with with pointy top hexagons
# and the “q” types are used with flat top.
# Whether it’s even or odd can be encoded as an offset direction +1 or -1.
# For pointy top, the offset direction tells us whether to slide alternate rows
# right or left.
# For flat top, the offset direction tells us whether to slide alternate columns
# up or down.


const OFFSET_EVEN = +1;
const OFFSET_ODD = -1;
const offset = OFFSET_ODD  # kiss it


static func tile_from_cell(cell) -> Vector2:
	return tile_from_cube(cube_from_cell(cell))


static func cell_to_tile(cell) -> Vector2:
	return tile_from_cell(cell)


static func cube_to_tile(cube) -> Vector2:
	return tile_from_cube(cube)


static func tile_from_cube(cube) -> Vector2:
	#int col = h.q + int((h.r + offset * (h.r & 1)) / 2)
	#int row = h.r
	return Vector2(
		cube.x + int((cube.z + offset * (int(cube.z) & 1)) / 2.0),
		cube.z
	)


static func tile_to_cell(tile) -> Vector2:
	return cell_from_tile(tile)


static func cell_from_tile(tile) -> Vector2:
#	int q = h.col - int((h.row + offset * (h.row & 1)) / 2.0);
#	int r = h.row;
#	int s = -q - r;
	return Vector2(
		tile.x - int((tile.y + offset * (int(tile.y) & 1)) / 2.0),
		tile.y
	)



# Flat-topped
#qoffset_from_cube(int offset, Hex h) {
##	assert(offset == EVEN || offset == ODD);
#	int col = h.q;
#	int row = h.r + int((h.q + offset * (h.q & 1)) / 2);
#	return OffsetCoord(col, row);
#}
#
#Hex qoffset_to_cube(int offset, OffsetCoord h) {
#	assert(offset == EVEN || offset == ODD);
#	int q = h.col;
#	int r = h.row - int((h.col + offset * (h.col & 1)) / 2);
#	int s = -q - r;
#	return Hex(q, r, s);
#}



#  _______          _ _
# |__   __|        | (_)
#    | | ___   ___ | |_ _ __   __ _
#    | |/ _ \ / _ \| | | '_ \ / _` |
#    | | (_) | (_) | | | | | | (_| |
#    |_|\___/ \___/|_|_|_| |_|\__, |
#                              __/ |
#                             |___/
# 

static func round_cube(cube: Vector3) -> Vector3:
	var rx = round(cube.x)
	var ry = round(cube.y)
	var rz = round(cube.z)

	var x_diff = abs(rx - cube.x)
	var y_diff = abs(ry - cube.y)
	var z_diff = abs(rz - cube.z)

	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry-rz
	elif y_diff > z_diff:
		ry = -rx-rz
	else:
		rz = -rx-ry

	return Vector3(rx, ry, rz)


static func round_cell(cell:Vector2) -> Vector2:
	return cell_from_cube(round_cube(cell_to_cube(cell)))



#const ODDR_DIRECTIONS = [
#	[[+1,  0], [ 0, -1], [-1, -1], 
#	[-1,  0], [-1, +1], [ 0, +1]],
#	[[+1,  0], [+1, -1], [ 0, -1], 
#	[-1,  0], [ 0, +1], [+1, +1]],
#]
# x at 3 o'clock
# y at 7 o'clock (about)
const ODDR_DIRECTIONS = [
	{
		Directions.RIGHT: [+1,  0],
		Directions.UP_RIGHT: [0, -1],
		Directions.UP_LEFT: [-1, -1],
		Directions.LEFT: [-1, 0],
		Directions.DOWN_LEFT: [-1, +1],
		Directions.DOWN_RIGHT: [0, +1],
	},
	{
		Directions.RIGHT: [+1,  0],
		Directions.UP_RIGHT: [+1, -1],
		Directions.UP_LEFT: [0, -1],
		Directions.LEFT: [-1, 0],
		Directions.DOWN_LEFT: [0, +1],
		Directions.DOWN_RIGHT: [+1, +1],
	},
]


# We use an Array instead of a Dict to ensure determinism of order in for loops
const CELL_DIRECTIONS_TO_NEIGHBORS := [  # trigwise (CCW) from RIGHT
	Vector2(1, 0),    # RIGHT
	Vector2(1, -1),   # UP RIGHT
	Vector2(0, -1),   # UP LEFT
	Vector2(-1, 0),   # LEFT
	Vector2(-1, 1),   # DOWN LEFT
	Vector2(0, 1),    # DOWN RIGHT
]
const CELL_NEIGHBORS_AMOUNT := 6  # size of the above


static func find_adjacent_tile_position(tile_position: Vector2, direction) -> Vector2:
	var parity = int(tile_position.y) & 1
	var dir = ODDR_DIRECTIONS[parity][direction]
	return Vector2(tile_position.x + dir[0], tile_position.y + dir[1])


static func find_adjacent_cell_position(cell_position: Vector2, direction) -> Vector2:
	return cell_from_tile(find_adjacent_tile_position(
		tile_from_cell(cell_position), direction
	))


static func get_adjacent_tiles_positions(tile_position: Vector2) -> Array:
	var adjacent_positions := get_adjacent_cells_positions(
		cell_from_tile(tile_position)
	)
	
	for i in range(CELL_NEIGHBORS_AMOUNT):
		adjacent_positions[i] = tile_from_cell(adjacent_positions[i])
	
	return adjacent_positions


static func get_adjacent_cells_positions(cell_position: Vector2) -> Array:
	var adjacent_positions := Array()
	
	for cell_direction in CELL_DIRECTIONS_TO_NEIGHBORS:
		adjacent_positions.push_back(cell_position + cell_direction)
	
	return adjacent_positions


static func get_direction_to_adjacent(origin_cell: Vector2, adjacent_cell: Vector2):
	for cell_direction in CELL_DIRECTIONS_TO_NEIGHBORS:
		if origin_cell + cell_direction == adjacent_cell:
			return cell_direction
	#breakpoint  # only adjacent cells
	return Vector2(1, 0)


################################################################################
# Bleh ; bouerk.  Remove!
static func sort_by_direction(blob_a, blob_b) -> bool:
	var cell_a = blob_a['cell']
	var cell_b = blob_b['cell']
	var dir_a = blob_a['direction']
	var dir_b = blob_b['direction']
	
	if dir_a != dir_b:
		# Extremely unlikely case, artefact of the curryless custom sort
		# We could remove this by using Sorter.new(direction) instead
		# of a static method in here.
		var rot_a = Directions.get_rotation(dir_a)
		var rot_b = Directions.get_rotation(dir_b)
		return rot_a < rot_b
	
	var d = (cell_b - cell_a) * dir_a
	
	return 0 > d.x + d.y  # rude approximation
################################################################################


################################################################################
# Artifact to remove
func reindex_from_nodes(nodes: Array) -> void:
	reset_map()
	for node in nodes:
		add_thing_on_cell(node, node.cell_position)
################################################################################





