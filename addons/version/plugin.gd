tool
extends EditorPlugin


# A plugin adding *some* version utilities.
# 
# Things left to do:
# - In the Editor, automatically fetch version from `git describe`
#   if available, and then write it into the `VERSION` file.
#   → see `bin/get_version.sh`


func _enter_tree():
	#add_autoload_singleton('Version', 'res://addons/version/Version.gd')
	add_custom_type(
		'VersionLabel',
		'Label',
		# load instead of preload, for when .import/ does not exist (fresh clone)
		# preload will fail hard and the whole plugin will be disabled.
		load('res://addons/version/version_label.gd'),
		load('res://addons/version/version_label.png')
	)


func _exit_tree():
	remove_custom_type('VersionLabel')
	#remove_autoload_singleton('Version')
