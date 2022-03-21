extends Control

# old and dusty and not used but perhaps someday

# This needs to be run whenever we add new levels that will matter for score
# It takes too long to run on clients. (it instantiates ALL levels)

signal module_loaded

func _ready():
	LevelsPool.init_full()
	emit_signal("module_loaded")
