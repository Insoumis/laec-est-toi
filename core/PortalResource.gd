extends Resource
class_name PortalResource

# Not used in-game, per se.
# This is a lightweight representation of a Portal.
# It's extracted from the portal nodes when we index all levels in LevelsPool.
# This helps visualize the levels and their connections, in LevelsViz.

export var target_level_path: String
