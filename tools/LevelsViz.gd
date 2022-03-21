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


# Let's try the singleton, so we don't have to free it.
#var levels_pool: LevelsPoolClass


onready var levels_table: DataTable = find_node("LevelsTable")


# Indexation takes a long time, so we thread it.
# We have crashes when we try to write the tres cache
# whether we're in thread or not.
var thread: Thread


func _ready():
	thread = Thread.new()
	var started = thread.start(self, "start")
	if OK != started:
		printerr("Cannot start indexation thread.")
	# or start it on the main thread:
#	start()


func _process(_delta):
	if thread and thread.is_active():
		if thread.is_alive():
			return
		thread.wait_to_finish()
		thread = null
		build_table()


func _input(_event):
	if Input.is_action_just_pressed("escape"):
		var _gone = Game.go_back()


func start():
	prints("Starting Levels Viz…")
	
	Chronometer.start()
	# We could also use the singleton LevelsPool, probably
#	self.levels_pool = LevelsPoolClass.new()
	LevelsPool.should_use_exclusion = false
#	LevelsPool.init()
	LevelsPool.init_full()  # FIXME crashes when writing cache to disk
	prints("LevelsPool#init_full():", Chronometer.stop(), "s")
	# LevelsPool#init_full(): 1.640474 s


func build_table():
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
	for level in LevelsPool.get_levels():
		
		var play_button = Button.new()
		play_button.text = tr("PLAY")
		play_button.connect("button_down", self, "on_level_play_button", [level])
		
		levels_table.add_row([
			play_button,
			level.level_filepath,
			level.title,
			bool_to_human(level.is_in_score),
#			bool_to_human(level.is_orphan),
			level.parents_filepaths,
			level.portals.size(),  # incorrect, since it also counts "invalid" portals
		])


func bool_to_human(value: bool):
	if value:
		return tr("YES")
	else:
		return tr("NO")


func on_level_play_button(level):
	Game.switch_to_scene_path(
		level.level_filepath,
		false, true, true
	)

