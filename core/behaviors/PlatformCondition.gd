extends Node
class_name PlatformCondition


# Conditions the visibility of the parent node to the player's platform.


export var hide_by_default := false
export var show_if_html5 := false
# … add more conditions


func _ready():
	ready()


func ready():
	apply_conditions()


func apply_conditions():
	var target = get_parent()
	assert(target, "PlatformCondition acts on its parent.")
	if not target:
		return
	var is_in_html5 := OS.has_feature('HTML5')
	
	if hide_by_default:
		target.visible = false
	
	if show_if_html5 and is_in_html5:
		target.visible = true

