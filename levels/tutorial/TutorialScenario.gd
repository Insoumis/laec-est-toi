extends Node


onready var level = $".."  # level may not be ready yet /!.


func _ready():
	$AnimationPlayer.play("Intro", -1, 0.012)
	var _c = self.level.connect("turn_spending_started", self, "on_level_turn_spent")


func on_level_turn_spent():
	$AnimationPlayer.seek($AnimationPlayer.current_animation_length)

