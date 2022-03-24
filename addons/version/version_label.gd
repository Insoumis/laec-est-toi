tool
extends Label


export var template := "%s"


func _enter_tree():
	# Trying to access Version fails when it is not autoloadded yet.
#	if Version:
#		set_text(Version.get_full())
	
	# but... DO NOT USE Engine.has_singleton() IT DOES NOT DO WHAT YOU THINK
	#if not Engine.has_singleton('Version'):
	
	# So we try a more cautious approach
	var __Version = get_node('/root/Version')
	if not __Version:
		printerr('Version singleton is not defined.')
		return
	
	set_text(self.template % [__Version.get_full()])

