tool
extends EditorPlugin


# A plugin adding *some* version utilities.
# 
# Things left to do:
# - In the Editor, automatically fetch version from `git describe`
#   if available, and then write it into the `VERSION` file.
#   → see `bin/get_version.sh`


func _enter_tree():
	add_autoload_singleton('Version', 'res://addons/version/Version.gd')
	#yield(get_tree(), "idle_frame")
	for i in 10:
		yield(get_tree(), "idle_frame")
	add_custom_type(
		'VersionLabel',
		'Label',
		preload('res://addons/version/version_label.gd'),
		preload('res://addons/version/version_label.png')
	)


func _exit_tree():
	remove_custom_type('VersionLabel')
	remove_autoload_singleton('Version')
