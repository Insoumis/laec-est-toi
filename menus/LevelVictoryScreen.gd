extends Control

#   _____ _                      _____ _                         _
#  / ____| |                    / ____| |                       | |
# | (___ | |_ __ _  __ _  ___  | |    | | ___  __ _ _ __ ___  __| |
#  \___ \| __/ _` |/ _` |/ _ \ | |    | |/ _ \/ _` | '__/ _ \/ _` |
#  ____) | || (_| | (_| |  __/ | |____| |  __/ (_| | | |  __/ (_| |
# |_____/ \__\__,_|\__, |\___|  \_____|_|\___|\__,_|_|  \___|\__,_|
#                   __/ |
#                  |___/


# Level this Level Victory Screen is about.
# Injected in prepare() by the factory.
# It will be freed later when calling level.go_forward()
var level  # Level scene instance


onready var continue_button = find_node("ContinueButton")
onready var more_button = find_node("MoreButton")
onready var victory_label = find_node("VictoryLabel")
onready var title_label = find_node("LaecTitleLabel")
#onready var excerpt_label = find_node("LaecExcerptLabel")
onready var excerpt_label = find_node("LaecExcerptRtlQueue")
#onready var level_preview = find_node("Replay/*/Level")  # ? why null
onready var level_preview = find_node("Level")
onready var time_field = find_node("TimeField")
onready var moves_field = find_node("MovesField")


func _ready():
	self.continue_button.grab_focus()
	if self.level:
		self.title_label.text = self.level.get_title_displayed()
#		self.excerpt_label.text = tr(self.level.excerpt)
		var excerpt_lines : Array = self.level.get_excerpt_displayed().split("\n")
		for line in excerpt_lines:
			if line:
				self.excerpt_label.add_text(line, 25)
			self.excerpt_label.add_newline()
#		self.excerpt_label.add_text(self.level.get_excerpt_displayed(), 25)
		
		self.time_field.text = "%.1f s" % self.level.get_level_time()
		self.moves_field.text = "%d" % len(self.level.recorded_solution)
		
		self.level_preview.replay_run = true
		self.level_preview.items_palette = self.level.items_palette
		self.level_preview.setup_palettes()
		restart_replay()
		self.level_preview.connect("level_completed", self, "_on_replay_completed")
	else:
		self.level_preview.hide()
	
	self.victory_label.bbcode_text = \
		"[center][tornado radius=2 freq=1]%s[/tornado][/center]" \
		% tr('LEVEL COMPLETE !')


func _input(event):
	if event is InputEventMouseMotion:
		return
	if event is InputEventJoypadMotion:
		return
	self.excerpt_label.speed_up_for_real = 13


func _on_replay_completed(_won_level, _winning_cells) -> void:
	var _c = get_tree().create_timer(2.0).connect(
		"timeout", self, "restart_replay"
	)


func restart_replay() -> void:
	self.level_preview.load_from_pickle(self.level.initial_pickle)
	self.level_preview.camera.zoom *= 2.0
	self.level_preview.start_autoplay(
		self.level.recorded_solution
	)


func prepare(for_level) -> void:
	assert(for_level, "Cannot prepare a victory screen for an empty level.")
	self.level = for_level


func _on_ContinueButton_pressed():
	if not self.level:
		printerr("No level to continue from.")
		if not Game:
			printerr("`Game' singleton is not available.")
			return
		var _journey_back = Game.go_back()
		return
	
	self.level.go_forward()


func _on_MoreButton_pressed():
	if not self.level:
		return
	if self.level.link:
		var link = self.level.get_link_displayed()
		if link:
			var _opened = OS.shell_open(link)
