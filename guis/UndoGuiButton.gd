extends Control

const Level = preload("res://addons/laec-is-you/entity/Level.gd")


onready var sprite := $UndoButton/AnimatedSprite
onready var attention_seeker : CPUParticles2D = $LimboCPUParticles2D

var amount_of_frames := 0  # safe default

# Parent level (if any)
var level


func _ready():
	amount_of_frames = self.sprite.frames.get_frame_count('default')
	self.level = find_parent_level()
	if self.level:
		self.level.connect("limbo_entered", self, 'on_limbo_entered')
		self.level.connect("limbo_exited", self, 'on_limbo_exited')

func find_parent_level():
	var p = self
	while p:
		if p is Level:
			return p
		p = p.get_parent()
	return null

func on_limbo_entered():
	self.attention_seeker.emitting = true

func on_limbo_exited():
	self.attention_seeker.emitting = false



func _on_Button_button_down():
	Input.action_press("undo")
#	$UndoButton.icon.pause = false


func _on_Button_button_up():
	Input.action_release("undo")
#	$UndoButton.icon.pause = true


func advance():
	self.sprite.frame = (self.sprite.frame + 1) % self.amount_of_frames


func rewind():
	self.sprite.frame = (self.sprite.frame - 1 + amount_of_frames) % self.amount_of_frames
