extends Control

#  _____                       __  __
# |  __ \                     |  \/  |
# | |__) |_ _ _   _ ___  ___  | \  / | ___ _ __  _   _
# |  ___/ _` | | | / __|/ _ \ | |\/| |/ _ \ '_ \| | | |
# | |  | (_| | |_| \__ \  __/ | |  | |  __/ | | | |_| |
# |_|   \__,_|\__,_|___/\___| |_|  |_|\___|_| |_|\__,_|
#
#
# Shown during a level when the player hits the "escape" action.
#

const LevelScene := preload("res://addons/laec-is-you/entity/Level.gd")


onready var sentences_container := find_node("SentencesContainer")


# Injected level (upon initialization, before _ready)
# That level is not in the scene tree anymore. (probably)
var level: LevelScene


func _ready():
	find_node('ResumeButton').grab_focus()
	
	if level:
		for sentence in level.get_possible_sentences():
			var sentence_label = Label.new()
			sentence_label.align = Label.ALIGN_CENTER
			sentence_label.text = sentence.to_pretty_string()
			sentences_container.add_child(sentence_label)


func _input(_event):
	if (Input.is_action_just_pressed("undo") 
		or Input.is_action_just_pressed("pause") 
		or Input.is_action_just_pressed("escape")):
		if Game:
			Game.emit_signal("game_resumed")
			var _gone = Game.go_back(false)


# Called by Game or Level when creating this scene, I think
func initialize(for_level: LevelScene):
	assert(for_level)
	self.level = for_level


# Captures a frame of the game, and sets it as background
func update_background(viewport: Viewport):
	var img = viewport.get_texture().get_data()
	img.flip_y()  # usual screen XY convention woes
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	get_node("Background").texture = tex


func _on_ResumeButton_pressed():
	if not Game:
		return
	Game.emit_signal("game_resumed")
	var _gone = Game.go_back(false)


func _on_RestartButton_pressed():
	if not Game:
		return
	Game.go_back_and_reset()


func _on_ExitLevelButton_pressed():
	if not Game:
		return
	Game.go_back_twice()


func _on_SettingsButton_pressed():
	if not Game:
		return
	Game.switch_to_scene_path("res://menus/SettingsMenu.tscn")


func _on_BackToMenuButton_pressed():
	if not Game:
		return
	Game.go_back_to_main_menu()


func _on_ExitGameButton_pressed():
	if not App:
		return
	App.exit()
