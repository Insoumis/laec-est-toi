extends Control


export(String, FILE, "*.tscn") var next_scene_path: String

onready var timer: Timer = $Timer

var is_ready := false
var is_gone := false


func _ready():
	ready()


func ready():
	self.is_ready = true
	self.timer.start()


func _input(event):
	if (event is InputEventJoypadMotion) or (event is InputEventMouseMotion):
		return
	if event.is_pressed():
		if not Game.__is_currently_switching:
			prints("Intro skipped by user event", event.as_text())
			go_to_next()


func go_to_next():
	if self.is_gone:
		return
	self.is_gone = true
	Game.switch_to_scene_path(next_scene_path, true, false, true)


func _on_Timer_timeout():
	go_to_next()
