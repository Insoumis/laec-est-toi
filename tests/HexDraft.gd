extends Node2D


var hex_radius := 64.0 / sqrt(3.0)

func _input(event):
	if event is InputEventMouseMotion:
		var mouse_position = get_global_mouse_position()
		var tile = $HexagonalTileMap.world_to_map(mouse_position)
		var tile_world = $HexagonalTileMap.map_to_world(tile)
		$HexagonGui2.position = tile_world
		
		var hexk = HexagonalLattice.pix_to_cell(mouse_position, hex_radius, 1.0, true)
		var pixk = HexagonalLattice.cell_to_pix(hexk, hex_radius, 1.0, true)
		$HexagonGuiOk.position = pixk
	
	if event is InputEventMouseButton and event.pressed:
		var mouse_position = get_global_mouse_position()
		var tile = $HexagonalTileMap.world_to_map(mouse_position)
		var cell = HexagonalLattice.tile_to_cell(tile)
		prints("Tile", tile, " — ", "Cell", cell)
