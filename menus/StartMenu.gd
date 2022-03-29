extends Control
class_name StartMenu


export var idle_demo_cooldown := 20.0


onready var cursor := find_node("CursorAnimatedSprite")
onready var menu_buttons_container := find_node("MenuButtonsContainer")
onready var exit_button : Button = find_node("ExitButton")
onready var settings_button : Button = find_node("SettingsButton")

var current_idle_demo_cooldown := idle_demo_cooldown


func _ready():
	TranslationServer.set_locale('fr')
	if OS.has_feature("HTML5") or true:
		print("Start Menu is getting ready for HTML5...")
		self.exit_button.hide()
		self.settings_button.focus_neighbour_bottom = "./PlayStoryButton"
#		var html5_disclaimer = load(Game.html5_disclaimer_scene_path).instance()
#		add_child(html5_disclaimer)
#		html5_disclaimer.popup_centered()
	connect_cursor_to_buttons()
	start_idle_demo()


func _enter_tree():
	self.current_idle_demo_cooldown = idle_demo_cooldown
	reveal_secret_editor_perhaps()
#	focus_play_button()


func _on_StartMenu_visibility_changed():
	if self.visible:
		# Ugly timeout to make sure the button is in the scene tree
		var _c = get_tree().create_timer(0.3).connect("timeout", self, "focus_play_button")
		# Even uglier way of doing the same disgusting hack
#		yield(get_tree().create_timer(0.3), "timeout")
#		focus_play_button()


func _process(delta):
	self.current_idle_demo_cooldown -= delta
	if self.current_idle_demo_cooldown < 0.0:
		Game.switch_to_scene_path('res://menus/IdleMenu.tscn')
		self.current_idle_demo_cooldown = idle_demo_cooldown


func _input(event):
	if event is InputEventJoypadMotion:
		if event.axis_value < 0.666:
			return
	self.current_idle_demo_cooldown = idle_demo_cooldown
	if Input.is_action_just_pressed("undo"):
		var _gone = Game.go_back(true, true)
	if Input.is_action_just_pressed("escape"):
		var _gone = Game.go_back(true, false)  # could also directly be App.exit() ?
	if Input.is_action_just_pressed("cheat"):
		Game.switch_to_scene_path('res://tools/LevelsViz.tscn')


func focus_play_button():
	var default_focused_button = find_node("PlayStoryButton")
	if not default_focused_button.is_inside_tree():
		return
	# We have to defer those because we may not be _ready yet
	default_focused_button.call_deferred('grab_focus')
	call_deferred('_on_Menu_Button_focused', default_focused_button, true)


func connect_cursor_to_buttons():
	var buttons := Array()
	for hbox in self.menu_buttons_container.get_children():
		if hbox is HBoxContainer:
			for child in hbox.get_children():
				if child.name.ends_with("Button") and (child is Button):
					buttons.push_back(child)
	var _c
	for button in buttons:
		_c = button.connect("focus_entered", self, '_on_Menu_Button_focused', [button])
		_c = button.connect("mouse_entered", self, '_on_Menu_Button_focused', [button])


func start_idle_demo():
	var idle_demo_scene = preload("res://menus/IdleMenu.tscn")
	
	var idle_demo = idle_demo_scene.instance()
	Game.switch_to_scene(idle_demo, false, true, false)


func reveal_secret_editor_perhaps():
	var score = Game.get_completion_score()
	if score > 0.618:
		find_node("SecretEditorParticles").visible = true


func _on_Menu_Button_focused(button: Button, silent := false):
	if not button.is_inside_tree():
		return
	if not button.has_focus():
		button.grab_focus()  # re-triggers _on_Menu_Button_focused
		return
	self.cursor.position.y = button.get_parent().margin_top + menu_buttons_container.margin_top - 10
	self.cursor.position.x = button.get_parent().margin_right + menu_buttons_container.margin_left + 2
	if not silent:  # ineffective because of our deferred shenanigans, no time to untangle this
		#SoundFx.play('gui_pouic')
		SoundFx.play('gui_move')


func _on_PlayButton_pressed():
	SoundFx.play("gui_select")
	Game.switch_to_story_mode()
	# Disabling this to hotfix issue #101
#	Game.switch_to_scene_path(Game.entrypoint_tutorial_menu)


func _on_PlayTutosButton_pressed():
	SoundFx.play("gui_select")
	Game.enter_level(Game.entrypoint_tutos_level_scene_path)


func _on_PlayExtrasButton_pressed():
	SoundFx.play("gui_select")
	Game.enter_level(Game.entrypoint_extra_level_scene_path)


func _on_ControlsButton_pressed():
	SoundFx.play("gui_select")
	#InputMapper.log_level = InputMapper.LOG_LEVEL_DEBUG
	Game.switch_to_scene_path("res://menus/InputMapperMenu.tscn")


func _on_SettingsButton_pressed():
	SoundFx.play("gui_select")
	Game.switch_to_scene_path("res://menus/SettingsMenu.tscn")


func _on_ExitButton_pressed():
	App.exit()


func _on_SecretButton_pressed():
	SoundFx.play("gui_pouic")
	Game.switch_to_scene_path("res://editor/LevelsExplorer.tscn")

