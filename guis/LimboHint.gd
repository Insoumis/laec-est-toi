extends Control

const Level = preload("res://addons/laec-is-you/entity/Level.gd")


onready var animation_player = $AnimationPlayer


var level


func _ready():
	self.visible = false
	self.level = find_parent_level()
#	assert(self.level)
	if self.level:
		self.level.connect("limbo_entered", self, 'on_limbo_entered')
		self.level.connect("limbo_exited", self, 'on_limbo_exited')

func find_parent_level():
	var p = get_parent()
	while p:
		if p is Level:
			return p
		p = p.get_parent()
	return null


func on_limbo_entered():
	self.animation_player.play("Appear")


func on_limbo_exited():
	self.animation_player.play_backwards("Appear")
