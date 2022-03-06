extends Node

#  _____                   _   __  __
# |_   _|                 | | |  \/  |
#   | |  _ __  _ __  _   _| |_| \  / | __ _ _ __  _ __   ___ _ __
#   | | | '_ \| '_ \| | | | __| |\/| |/ _` | '_ \| '_ \ / _ \ '__|
#  _| |_| | | | |_) | |_| | |_| |  | | (_| | |_) | |_) |  __/ |
# |_____|_| |_| .__/ \__,_|\__|_|  |_|\__,_| .__/| .__/ \___|_|
#             | |                          | |   | |
#             |_|                          |_|   |_|
# 
# v0.1.0
#
# A Singleton to help deal with custom input mappings.
# This is a quick crutch, meant to be a standalone singleton in a single file.
# 
# This uses its own file to store user-set mappings, because:
# - can't figure out how to write new action mappings with ProjectSettings.save_custom()
# - default (reset) config can be retrieved from ProjectSettings (convenient)
# 
# Design
# ------
# 
# Built around a "diff" of the InputMap.
# You can add new action bindings (custom_
# 
# Usage Example
# -------------
# 
# InputMapper.show_mapping([
# 	{ 'action': 'move_left', 'title': tr('Move Left') },
# 	{ 'action': 'move_right', 'title': tr('Move Right') },
# ])
# 
# 
# Ideas
# -----
# 
# - Allow providing a style
# - Use a Resource for the numerous layout options
# 
# 


#   _____             __ _
#  / ____|           / _(_)
# | |     ___  _ __ | |_ _  __ _
# | |    / _ \| '_ \|  _| |/ _` |
# | |___| (_) | | | | | | | (_| |
#  \_____\___/|_| |_|_| |_|\__, |
#                           __/ |
#                          |___/
# 
# Use these to configure the InputMapper.
#
#     InputMapper.bindings_buttons_min_width = 42
#     InputMapper.show_mappings(…)
# 
# Really not sure about this configuration API.
# Resources ?

# Expected to hold a var2str() of our custom data
var custom_mapping_file := "user://custom_input_mapping.dat"

var binding_button_min_width := 150.0
var binding_button_min_height := 0.0
var binding_buttons_columns := 2
var action_label_min_width := 150.0
var action_label_min_height := 0.0

# WIP: not supported yet (no promises)
# If true, a single event may not be bound to more than one action
var exclusive := true


#  _____        _
# |  __ \      | |
# | |  | | __ _| |_ __ _
# | |  | |/ _` | __/ _` |
# | |__| | (_| | || (_| |
# |_____/ \__,_|\__\__,_|
#
#

# Scene "behind" the InputMapper, the game/menu scene that ran show_xxx()
var previous_scene : Node

# Dusty things
#var is_remapping = false
#var actions_to_remap : Array
#var action_to_remap_index : int

# These are what the player defines through the UI.
# Both are saved to a file (custom_mapping_file), in a dictionary.
var custom_mapping : Array  # of Dictionary with `action` and `event`
var custom_deletes : Array  # of Dictionary with `action` and `event`


#  _____       _                        _
# |_   _|     | |                      | |
#   | |  _ __ | |_ ___ _ __ _ __   __ _| |
#   | | | '_ \| __/ _ \ '__| '_ \ / _` | |
#  _| |_| | | | ||  __/ |  | | | | (_| | |
# |_____|_| |_|\__\___|_|  |_| |_|\__,_|_|
#
#


# We collect this if it is set, but don't use it (for now; can't figure it out)
var __project_settings_override := ""



#  _    _             _
# | |  | |           | |
# | |__| | ___   ___ | | _____
# |  __  |/ _ \ / _ \| |/ / __|
# | |  | | (_) | (_) |   <\__ \
# |_|  |_|\___/ \___/|_|\_\___/
#
#


func _ready():
	inform("%s is readying…" % self.name)
	
	assert(self.exclusive, "TODO: support non-exclusivity (and groups!)")
	
	self.__project_settings_override = ProjectSettings.get_setting(
		'application/config/project_settings_override'
	)
	
	__load_from_file()
	__apply_customizations()
	
	inform("%s is ready." % self.name)


func _input(event):
	if not __is_showing:
		return
	handle_inputs_of_mapping_buttons(event)
	
#	if not is_waiting_for_input():
#		if Input.is_action_just_released("escape"):
#			restore_previous_scene()
#		return


#  _____       _     _ _
# |  __ \     | |   | (_)
# | |__) |   _| |__ | |_  ___
# |  ___/ | | | '_ \| | |/ __|
# | |   | |_| | |_) | | | (__
# |_|    \__,_|_.__/|_|_|\___|
#


func is_showing() -> bool:
	return self.__is_showing


func reset():
	__initialize_empty()
	InputMap.load_from_globals()
	__save_to_file()


# Storage of the consumer-given actions we should show
var __provided_mapping_actions : Array

func show_mapping(actions: Array) -> void:
	__check_actions(actions)
	self.__provided_mapping_actions = actions
	__rebuild_mapping_ui()


func get_mapping_ui(actions: Array) -> Control:
	show_mapping(actions)
	return self.container


#   ____           _               _             _   _
#  / __ \         | |             | |           | | (_)
# | |  | |_ __ ___| |__   ___  ___| |_ _ __ __ _| |_ _  ___  _ __
# | |  | | '__/ __| '_ \ / _ \/ __| __| '__/ _` | __| |/ _ \| '_ \
# | |__| | | | (__| | | |  __/\__ \ |_| | | (_| | |_| | (_) | | | |
#  \____/|_|  \___|_| |_|\___||___/\__|_|  \__,_|\__|_|\___/|_| |_|
#
#
# Very, very basic.
# These are public, they could be useful.

# Is this node currently showing its UI?
var __is_showing := false


#func hide_previous_scene():
##	if self.previous_scene:
##		return  # kiss my idempotassy
#	self.__is_showing = true
#	self.previous_scene = get_tree().get_current_scene()
#	self.previous_scene.visible = false
#	self.previous_scene.set_process_input(false)

func go_to_previous_scene():
	self.__is_showing = false
	__destroy_ui()
	Game.go_back()

#func restore_previous_scene():
#	self.__is_showing = false
#	__destroy_ui()
#	self.previous_scene.visible = true
#	self.previous_scene.set_process_input(true)


#   _____       _          _
#  / ____|     | |        | |
# | (___  _   _| |__   ___| | __ _ ___ ___  ___  ___
#  \___ \| | | | '_ \ / __| |/ _` / __/ __|/ _ \/ __|
#  ____) | |_| | |_) | (__| | (_| \__ \__ \  __/\__ \
# |_____/ \__,_|_.__/ \___|_|\__,_|___/___/\___||___/
#
#

# Will be useful when refactoring for action "groups" and exclusivity by group.
class ActionBindings:
	extends Reference
	
	var bindings := Array()  # of ActionBinding
	
	func clear() -> ActionBindings:
		self.bindings.clear()
		return self
	
	func append(key: ActionBinding) -> ActionBindings:
		self.bindings.append(key)
		return self
	
	func has_for_button(button: Button) -> bool:
		for key in self.bindings:
			if key.button == button:
				return true
		return false
	
	func get_for_button(button: Button) -> ActionBinding:
		for key in self.bindings:
			if key.button == button:
				return key
		return null

	func update_button(button: Button, action: String, event: InputEvent) -> void:
		var updated := 0
		for binding in self.bindings:
			if binding.button == button:
				assert(binding.action == action, "PoM ; mixing up buttons?")
				binding.action = action
				binding.event = event
				updated += 1
		if 0 == updated:
			var binding = ActionBinding.new()
			binding.button = button
			binding.action = action
			binding.event = event
			self.bindings.append(binding)
		assert(2 > updated, "wannabe index has multiple times the same button?")


# → ActionKey?
# Key is too specific.  It can be any event, or even composites (modifiers!)
# → ActionInput?
# Input is very generic and already too much used
# → ActionBinding?
class ActionBinding:
	extends Reference
	
	var event : InputEvent
	var action : String
	var button : Button



#  ____            _
# |  _ \          (_)
# | |_) |_   _ ___ _ _ __   ___  ___ ___
# |  _ <| | | / __| | '_ \ / _ \/ __/ __|
# | |_) | |_| \__ \ | | | |  __/\__ \__ \
# |____/ \__,_|___/_|_| |_|\___||___/___/
#
#

func __initialize_empty():
	self.custom_mapping = Array()
	self.custom_deletes = Array()


func __apply_customizations():
	for mapping in self.custom_deletes:
		__unmap_input(mapping['action'], mapping['event'])
	for mapping in self.custom_mapping:
		__remap_input(mapping['action'], mapping['event'])


func __remap_input(action_to_remap: String, event: InputEvent):
	if self.exclusive:
		for action in InputMap.get_actions():
			if InputMap.action_has_event(action, event):
				__unmap_input(action, event)
	
	debug("%s adds input `%s` to action `%s`." % [
		self.name, get_event_string(event), action_to_remap,
	])
	InputMap.action_add_event(action_to_remap, event)


func __remap_custom(action_to_remap: String, event: InputEvent):
	__unmap_custom(action_to_remap, event)
	debug("%s adds custom `%s` of `%s`" % [
		self.name, get_event_string(event), action_to_remap,
	])
	self.custom_mapping.append({
		'action': action_to_remap,
		'event': event,
	})
	for i in range(self.custom_deletes.size()-1, -1, -1):
		if (
			self.custom_deletes[i]['event'].shortcut_match(event)
			and
			self.custom_deletes[i]['action'] == action_to_remap
		):
			debug("%s unmarks `%s` of `%s` as deleted" % [
				self.name, get_event_string(event), action_to_remap,
			])
			self.custom_deletes.remove(i)


func __unmap_input(action_to_unmap: String, event_to_unmap: InputEvent):
	debug("%s erases input `%s` from action `%s`." % [
		self.name, get_event_string(event_to_unmap), action_to_unmap,
	])
	InputMap.action_erase_event(action_to_unmap, event_to_unmap)


func __unmap_custom(action_to_unmap: String, event_to_unmap: InputEvent):
	var has_found_custom_mapping_to_delete := false
	
	for i in range(self.custom_mapping.size()-1, -1, -1):
		if self.custom_mapping[i]['event'].shortcut_match(event_to_unmap):
			debug("%s removes custom `%s` of `%s`" % [
				self.name, get_event_string(event_to_unmap), action_to_unmap,
			])
			self.custom_mapping.remove(i)
			has_found_custom_mapping_to_delete = true
	
	if not has_found_custom_mapping_to_delete:
		debug("%s marks `%s` of `%s` as deleted" % [
			self.name, get_event_string(event_to_unmap), action_to_unmap,
		])
		self.custom_deletes.append({
			'action': action_to_unmap,
			'event': event_to_unmap,
		})


func __unmap_ui(action_to_unmap: String, event_to_unmap: InputEvent):
	assert(self.exclusive, "todo")
	
	for i in range(self.all_actions_bindings.bindings.size()-1, -1, -1):
		var ab = self.all_actions_bindings.bindings[i]
		
		var does_match_event = ab.event.shortcut_match(event_to_unmap)
		if self.exclusive and does_match_event:
			debug("%s erasing button `%s` of `%s`" % [
				self.name, ab.action, get_event_string(ab.event),
			])
			__unmap_custom(ab.action, ab.event)
			self.all_actions_bindings.bindings.remove(i)
			ab.button.queue_free()



#  _    _ _____   ______         _
# | |  | |_   _| |  ____|       | |
# | |  | | | |   | |__ __ _  ___| |_ ___  _ __ _   _
# | |  | | | |   |  __/ _` |/ __| __/ _ \| '__| | | |
# | |__| |_| |_  | | | (_| | (__| || (_) | |  | |_| |
#  \____/|_____| |_|  \__,_|\___|\__\___/|_|   \__, |
#                                               __/ |
#                                              |___/

# Container of the UI generated by the InputMapper
var container : Container

# Flat container of Actions
var vbox : Container

# background of Actions
var panel : Panel

# of action_name => Container
var actions_mappings_containers := Dictionary()

var all_actions_bindings := ActionBindings.new()
var actions_buttons := Array()  # of Dictionary {'button', 'action', 'event'}

# We reconnect signals instead of using this
# of Button => {event, action?}
#var actions_mappings_buttons_bindings := Dictionary()

const LISTENER_MAPPING_BUTTON := "__on_action_mapping_button_pressed"


func __rebuild_mapping_ui():
	__destroy_ui()
	__build_containers()
	self.all_actions_bindings.clear()
	var actions_container = self.vbox  # changeme
	var buttons_container = self.vbox  # changeme
	__build_back_button(buttons_container, true)
	for action in self.__provided_mapping_actions:
		__build_for_action(
			actions_container,
			action,
			150.0,
			self.binding_button_min_width,
			self.binding_buttons_columns
		)
	#__build_remap_button(buttons_container)
	__build_reset_button(buttons_container)
	__build_back_button(buttons_container)


func __destroy_ui():
	if not self.container:
		return
	if not is_instance_valid(self.container):
		return
	for child in self.container.get_children():
		if child.get_parent():
			child.get_parent().remove_child(child)
		child.queue_free()


# Pixels
var window_width := 800.0  # px
var window_height := 400.0  # px


func detect_window_size(ratio:=Vector2.ONE):
	# Convenience method
	assert(not "Implemented")


func __build_containers() -> void:
	if not is_instance_valid(self.container):
		self.container = CenterContainer.new()
		self.container.name = "MappingsContainer"
		self.container.anchor_left = 0.0
		self.container.anchor_top = 0.0
		self.container.anchor_right = 1.0
		self.container.anchor_bottom = 1.0
	
	var scroller = ScrollContainer.new()
	scroller.name = "MappingsScrollContainer"
	scroller.follow_focus = true
	scroller.anchor_left = 0.0
	scroller.anchor_top = 0.0
	scroller.anchor_right = 1.0
	scroller.anchor_bottom = 1.0
	scroller.rect_min_size = Vector2(self.window_width, self.window_height)
	
	self.container.add_child(scroller)
	
	self.vbox = VBoxContainer.new()
	self.vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.add_child(self.vbox)
#	self.container.add_child(self.vbox)
#	add_child(self.container)


func __build_for_action(
	into_control: Control,
	action: Dictionary,
	label_width := 150,
	buttons_width := 150,
	mapping_columns := 4
):
	var action_line = HBoxContainer.new()
#	action_line.valign = Label.VALIGN_BOTTOM
	var action_name = action['action']  # eg: "move_up_left"
	var action_label = Label.new()
	action_label.name = "%sLabel" % action_name
	
	action_label.rect_min_size = Vector2(label_width, 0)
	action_label.text = action['title']
	action_label.valign = Label.VALIGN_CENTER
#	action_label.align = Label.ALIGN_RIGHT
	action_label.size_flags_vertical = Label.SIZE_EXPAND_FILL
	action_label.size_flags_horizontal = Label.SIZE_EXPAND_FILL
	action_line.add_child(action_label)
	
	var mappings_grid = GridContainer.new()
	mappings_grid.columns = mapping_columns
	mappings_grid.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	self.actions_mappings_containers[action_name] = mappings_grid
	
	for event in InputMap.get_action_list(action_name):
		# The as_text() of these is way too long
		if event is InputEventMouse:
			continue
		if event is InputEventJoypadButton:
			continue
		
		var action_mapping_button := Button.new()
		action_mapping_button.text = get_event_string(event)
		action_mapping_button.rect_min_size = Vector2(buttons_width, 0)
		action_mapping_button.connect(
			"pressed", self, LISTENER_MAPPING_BUTTON, [
				action, event, action_mapping_button,
			])
		mappings_grid.add_child(action_mapping_button)
		__update_button_index(action_mapping_button, action_name, event)
	
	__build_action_mapping_button_more(mappings_grid, action)
	
	action_line.add_child(mappings_grid)
	into_control.add_child(action_line)
	into_control.add_child(HSeparator.new())


# Button [+]
func __build_action_mapping_button_more(into_control: Control, action: Dictionary):
	var action_mapping_button = Button.new()
	action_mapping_button.text = "+"
	action_mapping_button.connect(
		"pressed", self, LISTENER_MAPPING_BUTTON, [
			action, null, action_mapping_button,
		])
	into_control.add_child(action_mapping_button)

#func __build_action_mapping_button(
#	into_control: Control,
#	action: Dictionary,
#	event: InputEvent,
#	button_width: int
#):
#	var action_mapping_button = Button.new()
#	action_mapping_button.text = get_event_string(event)
#	action_mapping_button.rect_min_size = Vector2(button_width, 0)
#	action_mapping_button.connect(
#		"pressed", self,
#		LISTENER_MAPPING_BUTTON, [
#			action, event, action_mapping_button,
#		])
#	into_control.add_child(action_mapping_button)


func __adjust_mapping_button(button: Button):
	button.rect_min_size = Vector2(
		self.binding_button_min_width,
		self.binding_button_min_height
	)


func __append_mapping_button_more(action: Dictionary):
	__build_action_mapping_button_more(
		self.actions_mappings_containers[action['action']],
		action
	)


#func __move_to_next_action():
#	action_to_remap_index += 1
#	if action_to_remap_index >= actions_to_remap.size():
#		__save_to_file()
#		yield(get_tree().create_timer(1.618), "timeout")
#		is_remapping = false
#		restore_previous_scene()
##		container.get_parent().remove_child(container)
##		previous_scene.visible = true
#		return
#	var action_to_remap = actions_to_remap[action_to_remap_index]
#	build_for_action(action_to_remap, self.vbox)
#	action_mapping.text = "<"+tr('press key')+">"


#  __  __                   _               ____        _   _
# |  \/  |                 (_)             |  _ \      | | | |
# | \  / | __ _ _ __  _ __  _ _ __   __ _  | |_) |_   _| |_| |_ ___  _ __  ___
# | |\/| |/ _` | '_ \| '_ \| | '_ \ / _` | |  _ <| | | | __| __/ _ \| '_ \/ __|
# | |  | | (_| | |_) | |_) | | | | | (_| | | |_) | |_| | |_| || (_) | | | \__ \
# |_|  |_|\__,_| .__/| .__/|_|_| |_|\__, | |____/ \__,_|\__|\__\___/|_| |_|___/
#              | |   | |             __/ |
#              |_|   |_|            |___/


var __is_currently_mapping_through_button := false
var __current_mapping_button : Button
var __current_mapping_action # : Dictionary
var __current_mapping_event # : Event
var __current_mapping_name : String


func __on_action_mapping_button_pressed(action, event, button):
	# When a Mapping button is pressed,
	# the player should be able to press any keyboard key
	# (except escape and delete?)
	# to rebind the mapping of the button to the new key.
	
	self.__is_currently_mapping_through_button = true
	self.__current_mapping_name = button.text
	button.text = "<type anything>"
	button.disabled = true
	self.__current_mapping_action = action
	self.__current_mapping_button = button
	self.__current_mapping_event = event
	
	# and now we wait for _input, in handle_inputs_of_mapping_buttons() below


func handle_inputs_of_mapping_buttons(event):
	if not self.__is_currently_mapping_through_button:
		return
	if event is InputEventMouseMotion:
		return
	if event is InputEventJoypadMotion:
		return  # to test
	var action = self.__current_mapping_action
	assert(action)
	var action_name : String = action['action']
	var button = self.__current_mapping_button
	# Event that was previously held by the button
	var previous_event = self.__current_mapping_event
	
	if event is InputEventKey:
		if not event.pressed:
			return
		if event.scancode == KEY_DELETE:
			if action_name and previous_event:
				button.find_next_valid_focus().grab_focus()
				__unmap_ui(action_name, previous_event)
				__unmap_custom(action_name, previous_event)
				__unmap_input(action_name, previous_event)
				__save_to_file()
			else:
				__restore_button()
			__stop_mapping_through_button()
			return
		
		if event.scancode == KEY_ESCAPE:
			__cancel_mapping_button()
			return
	
	if event is InputEventMouseButton:
		if not event.pressed:
			return
		__cancel_mapping_button()
		return
	
	var is_event_unchanged := false
	if previous_event:
		is_event_unchanged = previous_event.shortcut_match(event)
	
	if is_event_unchanged:
		__cancel_mapping_button()
		return
	
	var action_already_has_event := false
	for action_event in InputMap.get_action_list(action_name):
		if action_event.shortcut_match(event):
			action_already_has_event = true
			break
	if action_already_has_event:
		__cancel_mapping_button()
		return
	
	# At this point, some user input was successfully recorded in the event.
	# Let's move on to business!
	
	var was_a_more_button : bool = not previous_event
	var should_append_more := was_a_more_button
	
	button.disconnect(
		"pressed", self,
		LISTENER_MAPPING_BUTTON
	)
	button.connect(
		"pressed", self,
		LISTENER_MAPPING_BUTTON, [ action, event, button ]
	)
	
	if previous_event:
		__unmap_input(action_name, previous_event)
		__unmap_custom(action_name, previous_event)
	
	__unmap_ui(action_name, event)
	__update_button_index(button, action_name, event)  # AFTER __unmap_ui()
	
	__remap_custom(action_name, event)
	__remap_input(action_name, event)
	
	button.text = get_event_string(event)
	__adjust_mapping_button(button)
	__stop_mapping_through_button()
	__save_to_file()
	
	if should_append_more:
		__append_mapping_button_more(action)


func __cancel_mapping_button():
	__restore_button()
	__stop_mapping_through_button()


func __stop_mapping_through_button():
	self.__is_currently_mapping_through_button = false
	self.__current_mapping_button.disabled = false
	self.__current_mapping_action = null
	self.__current_mapping_button = null
	self.__current_mapping_event = null


func __restore_button():
	self.__current_mapping_button.text = self.__current_mapping_name


func __update_button_index(button, action_name, event):
	self.all_actions_bindings.update_button(button, action_name, event)



#  ____             _      ____        _   _
# |  _ \           | |    |  _ \      | | | |
# | |_) | __ _  ___| | __ | |_) |_   _| |_| |_ ___  _ __
# |  _ < / _` |/ __| |/ / |  _ <| | | | __| __/ _ \| '_ \
# | |_) | (_| | (__|   <  | |_) | |_| | |_| || (_) | | | |
# |____/ \__,_|\___|_|\_\ |____/ \__,_|\__|\__\___/|_| |_|
#

func __build_back_button(into_control: Control, focus := false) -> void:
	var back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = tr("Back")
	back_button.connect("pressed", self, "__on_Back")
	back_button.connect("tree_entered", self, "__on_BackButton_ready", [back_button, focus])
	into_control.add_child(back_button)


func __on_Back():
	go_to_previous_scene()


func __on_BackButton_ready(back_button, focus):
	if focus:
		back_button.grab_focus()



#  _____                _     ____        _   _
# |  __ \              | |   |  _ \      | | | |
# | |__) |___  ___  ___| |_  | |_) |_   _| |_| |_ ___  _ __
# |  _  // _ \/ __|/ _ \ __| |  _ <| | | | __| __/ _ \| '_ \
# | | \ \  __/\__ \  __/ |_  | |_) | |_| | |_| || (_) | | | |
# |_|  \_\___||___/\___|\__| |____/ \__,_|\__|\__\___/|_| |_|
#
#

func __build_reset_button(into_control: Control) -> void:
	var reset_button = Button.new()
	reset_button.text = tr("Reset")
	reset_button.connect("pressed", self, "__on_Reset")
	into_control.add_child(reset_button)


func __on_Reset():
	reset()
	__rebuild_mapping_ui()



#  _____                              ____        _   _
# |  __ \                            |  _ \      | | | |
# | |__) |___ _ __ ___   __ _ _ __   | |_) |_   _| |_| |_ ___  _ __
# |  _  // _ \ '_ ` _ \ / _` | '_ \  |  _ <| | | | __| __/ _ \| '_ \
# | | \ \  __/ | | | | | (_| | |_) | | |_) | |_| | |_| || (_) | | | |
# |_|  \_\___|_| |_| |_|\__,_| .__/  |____/ \__,_|\__|\__\___/|_| |_|
#                            | |
#                            |_|


#func build_remap_button(into_control: Control) -> void:
#	var remap_button = Button.new()
#	remap_button.text = tr('Remap')
#	remap_button.connect("pressed", self, "__on_Remap")
#	into_control.add_child(remap_button)
#
#
#func __on_Remap():
#	restore_previous_scene()
#	assert(__last_used_actions)
#	if __last_used_actions:
#		start_remapping(__last_used_actions)



#  ______ _ _        _____ ____
# |  ____(_) |      |_   _/ __ \
# | |__   _| | ___    | || |  | |
# |  __| | | |/ _ \   | || |  | |
# | |    | | |  __/  _| || |__| |
# |_|    |_|_|\___| |_____\____/
#
#


func __load_from_file():
	var file := File.new()
	if not file.file_exists(self.custom_mapping_file):
		__initialize_empty()
		return
	var err = file.open(self.custom_mapping_file, File.READ)
	if err != OK:
		shout("Failed to load input mapping `%s`." % custom_mapping_file)
		__initialize_empty()
		return
	
	var custom_data = str2var(file.get_as_text())
	
	# Backward-compat with 0.0.x  (remove me at some point)
	if custom_data is Array:
		custom_data = {
			'mappings': custom_data,
			'deletes': [],
		}
	#######################################################
	
	if custom_data is Dictionary:
		self.custom_mapping = custom_data['mapping']
		self.custom_deletes = custom_data['deletes']
	else:
		printerr("%s cannot read data in %s as Dictionary" % [
			self.name,
			self.custom_mapping_file,
		])
		__initialize_empty()


func __save_to_file():
	var file := File.new()
	var err = file.open(self.custom_mapping_file, File.WRITE)
	if err != OK:
		printerr("Failed to save input mapping `%s`." % custom_mapping_file)
		return
	file.store_string(var2str({
		'mapping': self.custom_mapping,
		'deletes': self.custom_deletes,
	}))
	#print("Saved custom input mapping to file `%s`." % custom_mapping_file)
	
	# This do not save mappings written with InputMap.action_add_event()
	# Perhaps there's another way?
#	if self.__project_settings_override:
#		ProjectSettings.save_custom(self.__project_settings_override)



#   _____           _       _ _          _   _
#  / ____|         (_)     | (_)        | | (_)
# | (___   ___ _ __ _  __ _| |_ ______ _| |_ _  ___  _ __
#  \___ \ / _ \ '__| |/ _` | | |_  / _` | __| |/ _ \| '_ \
#  ____) |  __/ |  | | (_| | | |/ / (_| | |_| | (_) | | | |
# |_____/ \___|_|  |_|\__,_|_|_/___\__,_|\__|_|\___/|_| |_|
#


func get_string_for_event(event: InputEvent) -> String:
	if event is InputEventKey:
		return OS.get_scancode_string(event.scancode)
	# … add more
	return event.as_text()


func get_event_string(event: InputEvent) -> String:
	return get_string_for_event(event)


func e2str(event: InputEvent) -> String:
	return get_string_for_event(event)


#  _                       _
# | |                     (_)
# | |     ___   __ _  __ _ _ _ __   __ _
# | |    / _ \ / _` |/ _` | | '_ \ / _` |
# | |___| (_) | (_| | (_| | | | | | (_| |
# |______\___/ \__, |\__, |_|_| |_|\__, |
#               __/ | __/ |         __/ |
#              |___/ |___/         |___/
# Logging Trait v0.0.0

const LOG_LEVEL_DEBUG := 'debug'
const LOG_LEVEL_INFO := 'info'
const LOG_LEVEL_WARN := 'warn'
const LOG_LEVEL_ERROR := 'error'
const LOG_LEVEL_SILENT := 'silent'  # risky!

export(String, 'debug', 'info', 'warn', 'error', 'silent') \
var log_level := LOG_LEVEL_WARN

func debug(msg:String):
	if self.log_level == LOG_LEVEL_DEBUG:
		print(msg)

func info(msg:String):
	inform(msg)

func inform(msg:String):
	if self.log_level == LOG_LEVEL_DEBUG || self.log_level == LOG_LEVEL_INFO:
		print(msg)

func warn(msg:String):
	if self.log_level != LOG_LEVEL_ERROR && self.log_level != LOG_LEVEL_SILENT:
		printerr(msg)

func error(msg:String):
	shout(msg)

func shout(msg:String):
	if self.log_level != LOG_LEVEL_SILENT:
		printerr(msg)


#  __  __ _
# |  \/  (_)
# | \  / |_ ___  ___
# | |\/| | / __|/ __|
# | |  | | \__ \ (__
# |_|  |_|_|___/\___|
#


func __check_actions(actions: Array):
	assert(
		actions,
		"Provide an array of Dictionaries with keys `title` and `action`. \n"+
		"Use it to choose which actions you want to let users customize."
	)
	# We should also provide an API to build a default dict from project settings


# mmmmh
#func get_action_display_string(action_name: String) -> String:
#	var s = ""
#	for event in InputMap.get_action_list(action_name):
#		# The as_text() of these is way too long
#		if event is InputEventMouse:
#			continue
#		if event is InputEventJoypadButton:
#			continue
#
#		if s != "":
#			s += ", "
#
#		s += event.as_text()
#	return s
