extends Resource
class_name PortalResource


# This is a lightweight representation of a Portal.
# Not used in-game, per se.  Well, it is, but only as a database entity of sorts.
# It's extracted from the portal nodes when we index all levels in LevelsPool.
# This helps visualize the levels and their connections, in LevelsViz.


# Full path (with `res://` or `user://` prefix) to the level file.
# For now, best only put paths to `.tscn` files in here.
# Ideally, we'd support all level files, including `.phiu` and `.png`.
# Perhaps it already works?  Untested.
export var target_level_path: String


func has_a_target_defined() -> bool:
	return self.target_level_path != ""
