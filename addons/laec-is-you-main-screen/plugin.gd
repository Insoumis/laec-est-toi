tool
extends EditorPlugin


var main_screen_panel : Control
var play_button : Button
var create_new_level : Button
var create_new_item : Button
var show_new_level_tutorial : Button
var show_new_item_tutorial : Button
var run_features_button : Button
var level_editor : EditorPlugin setget set_level_editor


func get_plugin_name():
	return "YOU MAKE LAEC"

func get_plugin_icon():
	# Must return some kind of Texture for the icon.
	return get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")

func _enter_tree():
	setup()

func _exit_tree():
	cleanup()

func handles(object):
	pass
	#print("handling: ", object)

func has_main_screen():
	return true

func make_visible(visible):
	if main_screen_panel:
		main_screen_panel.visible = visible

func set_level_editor(p_level_editor : EditorPlugin):
	level_editor = p_level_editor

func setup():
	main_screen_panel = preload("res://addons/laec-is-you-main-screen/TutorialPanel.tscn").instance()
	main_screen_panel.you_make_laec = self
	create_new_item = main_screen_panel.find_node("CreateNewItem")
	create_new_level = main_screen_panel.find_node("CreateNewLevel")
	play_button = main_screen_panel.find_node("Play")
	show_new_item_tutorial = main_screen_panel.find_node("ShowItemTutorial")
	show_new_level_tutorial = main_screen_panel.find_node("ShowLevelTutorial")
	run_features_button = main_screen_panel.find_node("RunFeatures")
	play_button.connect("pressed", self, "play_button_pressed")
	create_new_item.connect("pressed" , self, "new_item_pressed")
	create_new_level.connect("pressed" , self, "new_level_pressed")
	show_new_level_tutorial.connect("pressed" , self, "show_level_tutorial")
	show_new_item_tutorial.connect("pressed" , self, "show_item_tutorial")
	run_features_button.connect("pressed" , self, "run_features")
	# Add the main panel to the editor's main viewport.
	
#	yield(get_tree(), "idle_frame")
	get_editor_interface().get_editor_viewport().add_child(main_screen_panel)
	make_visible(false)
	# Hide the main panel. Very much required.


func cleanup():
	self.create_new_item.queue_free()
	self.create_new_level.queue_free()
	self.play_button.queue_free()
	self.show_new_item_tutorial.queue_free()
	self.show_new_level_tutorial.queue_free()
	self.run_features_button.queue_free()


func play_button_pressed():
	get_editor_interface().play_main_scene()


func run_features():
	get_editor_interface().play_custom_scene("res://features/FeaturesRunner.tscn")
	

func show_level_tutorial():
	pass

func show_item_tutorial():
	pass

func new_level_pressed():
	level_editor.new_level_pressed()
	pass

func new_item_pressed():
	pass
#	connect("main_screen_changed", self, "on_main_scene_changed")

