# THIS TEST IS DISABLED
# We disabled WAT until it works again
#extends WAT.Test

# Unit tests for honey.
# Will Glomp for Pocky!

#class Bee:
#	pass
#
#func test_beeatrix() -> void:
#
#	var hive = HexagonalLattice.new()
#
#	var beeatrix = Bee.new()
#	var beechus = Bee.new()
#
#	asserts.is_not_equal(beeatrix, beechus, "All bees are unique.")
#
#	hive.add_thing_on_cell(beeatrix, Vector2(41, 43))
#	var things = hive.get(Vector2(41, 43))
#	asserts.is_equal(things[0], beeatrix, "get() works")
#
##	asserts.is_true(s.is_valid, "Sentence `%s` is valid." % [expectation['sentence']])
#
#
#func test_conversions() -> void:
#	var expectations = [
#		{
#			'tile': Vector2(0, 0),
#			'cell': Vector2(0, 0),
#		},
#		{
#			'tile': Vector2(1, 0),
#			'cell': Vector2(1, 0),
#		},
#		{
#			'tile': Vector2(0, -1),
#			'cell': Vector2(1, -1),
#		},
#		{
#			'tile': Vector2(-1, -1),
#			'cell': Vector2(0, -1),
#		},
#		{
#			'tile': Vector2(-1, 0),
#			'cell': Vector2(-1, 0),
#		},
#		{
#			'tile': Vector2(-1, 1),
#			'cell': Vector2(-1, 1),
#		},
#		{
#			'tile': Vector2(0, 1),
#			'cell': Vector2(0, 1),
#		},
#		{
#			'tile': Vector2(3, -1),
#			'cell': Vector2(4, -1),
#		},
#	]
#
#	var hive = HexagonalLattice.new()
#
#	for expectation in expectations:
#		asserts.is_equal(
#			expectation['tile'],
#			hive.tile_from_cell(expectation['cell']),
#			"tile_from_cell"
#		)
#		asserts.is_equal(
#			expectation['cell'],
#			hive.cell_from_tile(expectation['tile']),
#			"cell_from_tile"
#		)
