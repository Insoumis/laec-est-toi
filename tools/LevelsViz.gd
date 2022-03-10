extends Node2D

# This is a test, a draft, a PoC?  (Piece of Caca)
# Looks like a lot of work to get what I want.
# This shows levels and links betweeen them.
# 
# We'd need:
# - Mouse Drag & Drop
# - Keep levels up (don't rotate due to physics)
# - A less naive space repartition
# - …
# 


var levels_pool: LevelsPoolClass


onready var levels_table: DataTable = find_node("LevelsTable")


func _ready():
	
	prints("Starting Levels Viz…")
	
	Chronometer.start()
	# We could also use the singleton LevelsPool, probably
	self.levels_pool = LevelsPoolClass.new()
	self.levels_pool.should_use_exclusion = false
	self.levels_pool.init_full()
	prints("LevelsPool#init_full():", Chronometer.stop(), "s")
	# LevelsPool#init_full(): 1.640474 s
	
	var header_row = [
		tr("Action"),
		tr("Filepath"),
		tr("Title"),
		tr("Story"),
#		tr("Orphan"),
		tr("Parents"),
		tr("Children"),
	]
	levels_table.set_columns(header_row.size())
	levels_table.add_header_row(header_row)
	for level in self.levels_pool.get_levels():
		
		var play_button = Button.new()
		play_button.text = tr("PLAY")
		play_button.connect("button_down", self, "on_level_play_button", [level])
		
		levels_table.add_row([
			play_button,
			level.level_filepath,
			level.title,
			bool_to_human(level.is_in_score),
#			bool_to_human(level.is_orphan),
			level.parents,
			level.portals.size(),  # incorrect, since it also counts "invalid" portals
		])


func _input(event):
	if Input.is_action_just_pressed("escape"):
		var _gone = Game.go_back()


func on_level_play_button(level):
	Game.switch_to_scene_path(
		level.level_filepath,
		false, true, true
	)


func bool_to_human(value: bool):
	if value:
		return tr("YES")
	else:
		return tr("NO")


func _exit_tree():
	print("%s _exit_tree()" % self.name)  # nope, I never see this
	self.levels_pool.clear()

