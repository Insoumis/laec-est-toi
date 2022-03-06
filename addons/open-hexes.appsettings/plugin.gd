tool
extends EditorPlugin


var main_screen_panel : Control

func has_main_screen():
	return true

func get_plugin_name():
	return "AppSettings"

func make_visible(visible):
	if main_screen_panel:
		main_screen_panel.visible = visible

func _enter_tree():
	add_autoload_singleton("AppSettings", "res://addons/open-hexes.appsettings/singletons/AppSettings.gd")
	
	main_screen_panel = preload("res://addons/open-hexes.appsettings/editor/SettingsEditor.tscn").instance()
	main_screen_panel.parent_plugin = self
	get_editor_interface().get_editor_viewport().add_child(main_screen_panel)
	make_visible(false)


func _exit_tree():
	remove_autoload_singleton("AppSettings")
