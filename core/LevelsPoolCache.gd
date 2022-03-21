extends Resource
class_name LevelsPoolCache


# Indexation takes a long time, since it needs to "open" all the levels found in the filesystem.
# We do it during dev, and cache it in a file.  See LevelsPool.
# It can still be done at runtime, and we actually refresh part of the cache in the level explorer,
# to be able to see the levels made in the ingame editor, stored in user://
# The LevelsViz also recreates the cache file, in a thread (it takes forever but is smooth).


export var levels := Dictionary()  # filepath => LevelReference (is a Resource, actually)


func clear():
	self.levels.clear()

