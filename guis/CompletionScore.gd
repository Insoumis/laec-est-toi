extends Control

# Shows the percentage of completion of the game.

func _ready():
	refresh()

func refresh():
	# has_singleton() returns false somehow?
#	if not Engine.has_singleton("Game"):
	if not Game:
		printerr("%s needs singleton `Game`." % self.name)
		return
	var score = Game.get_completion_score()
	$Label.text = "%3.0f%%" % [score * 100.0]
