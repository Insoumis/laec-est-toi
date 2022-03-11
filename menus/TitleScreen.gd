extends Control

const TITLE_ANIMATION_COOLDOWN = 0.3
const PRESS_START_COOLDOWN = 0.6
var current_cooldown = TITLE_ANIMATION_COOLDOWN
var current_press_start_cooldown = PRESS_START_COOLDOWN
const IDLE_MENU_COOLDOWN = 7.0
var current_idle_menu_cooldown = IDLE_MENU_COOLDOWN


func _enter_tree():
	Game.emit_signal("main_menu_entered")
	current_idle_menu_cooldown = IDLE_MENU_COOLDOWN


func _process(delta):
	current_idle_menu_cooldown -= delta
	current_cooldown -= delta
	current_press_start_cooldown -= delta
	if current_cooldown < 0.0:
		$Title.frame = ($Title.frame + 1) % 3
		current_cooldown = TITLE_ANIMATION_COOLDOWN
	if current_press_start_cooldown < 0.0:
		$PressToContinue.visible = not $PressToContinue.visible
		current_press_start_cooldown = PRESS_START_COOLDOWN
	if current_idle_menu_cooldown < 0.0:
		Game.switch_to_scene_path('res://menus/IdleMenu.tscn')
		current_idle_menu_cooldown = IDLE_MENU_COOLDOWN


func _input(event):
	if Input.is_action_just_pressed("escape"):
		var _gone = Game.go_back()  # could also directly be App.exit() ?
		return
	if (event is InputEventJoypadMotion) or (event is InputEventMouseMotion):
		return
	if event.is_pressed():
		SoundFx.play("gui_start")
		Game.switch_to_scene_path('res://menus/StartMenu.tscn',
			false, true, true
		)
