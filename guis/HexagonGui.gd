extends Node2D
class_name HexagonGui


var amount_of_filling_stages := 8


func mark_direction(direction:String) -> void:
	var offset_top_left = Directions.get_rotation(Directions.TOP_LEFT)
	$DirectionMarkers.rotation = Directions.get_rotation(direction) - offset_top_left
	$DirectionMarkers.visible = true


func release_direction() -> void:
	$DirectionMarkers.rotation = 0
	$DirectionMarkers.visible = false


func fill(how_much:float) -> void:
	assert(0 <= how_much)
	assert(1 >= how_much)
	var animation = 'empty'
	if 0 < how_much:
		var stage = floor(how_much * 0.999 * (amount_of_filling_stages))
		animation = "stage_%d" % [stage]
	$Filling.set_animation(animation)
	

func show_left_mouse_button_hint():
	$Mouse.set_visible(true)
	$Mouse.set_animation('Left')


func show_right_mouse_button_hint():
	$Mouse.set_visible(true)
	$Mouse.set_animation('Right')


func hide_mouse_button_hint():
	$Mouse.set_visible(false)
	$Mouse.set_animation('None')

