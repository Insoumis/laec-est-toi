tool
extends EditorPlugin


const CHRONOMETER_SCRIPT_PATH := 'res://addons/laec.chronometer/Chronometer.gd'


func _enter_tree():
	add_autoload_singleton('Chronometer', CHRONOMETER_SCRIPT_PATH)


func _exit_tree():
	remove_autoload_singleton('Chronometer')
