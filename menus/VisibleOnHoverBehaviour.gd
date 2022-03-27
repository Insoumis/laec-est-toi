extends Node


# Button/Control whose focus we're following
export var button : NodePath

# Helps when focus_exited event was not triggered
# All behaviors under this node will receive a call to on_focus_exited()
# Make sure on_focus_exited() is idempotent, it may be ran twice,
# but at it'll run at least once in those cases where the signal is lost.
export var exclusive_under : NodePath


func _ready():
	connect_to_button()


func connect_to_button():
	var button_node: Control = get_node(self.button)
	if button_node and is_instance_valid(button_node):
		var _c
		_c = button_node.connect("focus_entered", self, "on_focus_entered")
		_c = button_node.connect("focus_exited", self, "on_focus_exited")


func on_focus_entered():
	get_parent().visible = true
	var others := list_other_behaviors()
	for other in others:
		other.on_focus_exited()


func on_focus_exited():
	get_parent().visible = false


func list_other_behaviors() -> Array:
	var others := Array()
	
	if not self.exclusive_under:
		return others
	
	var under_node = get_node(self.exclusive_under)
	if not under_node:
		breakpoint  # behavior is probably badly configured
		return others
	
	others.append_array(collect_behaviors_under(under_node))
	others.erase(self)  # we want the OTHER behaviors
	
	return others


func collect_behaviors_under(under_node: Node) -> Array:
	var behaviors := Array()
	var SelfScript = load(get_script().resource_path)
	if under_node is SelfScript:
		behaviors.append(under_node)
	for child in under_node.get_children():
		behaviors.append_array(collect_behaviors_under(child))
	return behaviors
