extends Resource
class_name LevelsPoolCache


export var levels := Dictionary()  # filepath => LevelReference (is a Resource, actually)
#export var levels_links := Array()  # of LevelLink


func clear():
	self.levels.clear()
#	self.levels_links.clear()

