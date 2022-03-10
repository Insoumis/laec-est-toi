tool
extends "res://addons/laec-is-you/entity/Item.gd"


export(String, MULTILINE) var contents := ""


func enter_tree():
	.enter_tree()
	hide_contents()
	if not Engine.is_editor_hint():
		get_level().connect("turn_spending_ended", self, "on_each_turn")


func exit_tree():
	.exit_tree()
	if not Engine.is_editor_hint():
		get_level().disconnect("turn_spending_ended", self, "on_each_turn")


func get_concept_name():
	return 'sign'


func update_sprite(_refresh_frames := true) -> void:
	pass  # nothing is cool
#	var concept := 'sign'
#	var sf = SpriteFramesFactory.get_for_concept(concept, false, 'signs')
#	$AnimatedSprite.frames = sf
#	$AnimatedSprite.animation = get_animation_name()
#	$AnimatedSprite.offset = Vector2(0.0, -12)


func on_each_turn():
	if is_piled_with_you():
		show_contents()
	else:
		hide_contents()


func show_contents():
	find_node("SignLabel").text = contents
	$Phylactere.visible = true


func hide_contents():
	$Phylactere.visible = false


func is_piled_with_you() -> bool:
	var level = get_level()
	if not level:
		printerr("This Portal has no level.  Skipping is_piled_with_you()…")
		return false
	
	var it_is := false
	for item in level.get_all_items():
		if is_piled_with(item) and item.is_you:
			it_is = true
			break
	
	return it_is


func is_piled_with(other_item) -> bool:
	return self.cell_position == other_item.cell_position
