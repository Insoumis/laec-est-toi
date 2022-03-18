extends "res://menus/Intro.gd"

var time_slice = 1.0/6.0

onready var source_granted_sprite = $Logo/SourceGranted
onready var power_button_sprite = $Logo/PowerButton
onready var name_on_screen_sprite = $Logo/NameOnScreen
onready var name_background = $Logo/NameBackground
onready var red_light_color_rect = $Logo/RedLight
onready var logo = $Logo

func _process(_delta):
	# TURN ON
	if timer.time_left > timer.wait_time * 5.0 * time_slice:
		var max_time_elapsed = timer.wait_time * time_slice
		var time_elapsed = timer.wait_time - timer.time_left
		if time_elapsed > max_time_elapsed / 2.0:
			power_button_sprite.position.y = -136.55
			red_light_color_rect.color.a = 1.0
	# FADE IN ROMCHECK
	elif (timer.time_left <= timer.wait_time * 5.0 * time_slice and
		timer.time_left > timer.wait_time * 4.0 * time_slice):
			var max_time_elapsed = timer.wait_time * time_slice
			var time_elapsed = timer.wait_time - timer.time_left - timer.wait_time * time_slice
			source_granted_sprite.modulate = Color(1.0, 1.0, 1.0, time_elapsed/max_time_elapsed)
	# PROGRESS ROMCHECK
	elif (timer.time_left <= timer.wait_time * 4.0 * time_slice and
		timer.time_left > timer.wait_time * 3.0 * time_slice):
			source_granted_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
			var max_time_elapsed = timer.wait_time * time_slice
			var time_elapsed = timer.wait_time - timer.time_left - timer.wait_time * time_slice * 2.0
			var romcheck_progress = source_granted_sprite.get_node("RomcheckProgress")
			romcheck_progress.margin_left = -38 + (166 * (time_elapsed / max_time_elapsed))
	# REMOVE ROMCHECK
	elif (timer.time_left <= timer.wait_time * 3.0 * time_slice and
		timer.time_left > timer.wait_time * 2.0 * time_slice):
			var max_time_elapsed = timer.wait_time * time_slice
			var time_elapsed = timer.wait_time - timer.time_left - timer.wait_time * time_slice * 3.0
			source_granted_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0 - time_elapsed/max_time_elapsed)
			var romcheck_progress = source_granted_sprite.get_node("RomcheckProgress")
			romcheck_progress.margin_left = -38 + 166 
	# ADD OPENXGAMES
	elif (timer.time_left <= timer.wait_time * 2.0 * time_slice and
		timer.time_left > timer.wait_time * 1.0 * time_slice):
			var max_time_elapsed = timer.wait_time * time_slice
			var time_elapsed = timer.wait_time - timer.time_left - timer.wait_time * time_slice * 4.0
			source_granted_sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)
			name_on_screen_sprite.modulate = Color(1.0, 1.0, 1.0, time_elapsed/max_time_elapsed)
			name_background.modulate = Color(1.0, 1.0, 1.0, time_elapsed/max_time_elapsed)
	# WAIT
	elif (timer.time_left <= timer.wait_time * 1.0 * time_slice):
			name_on_screen_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
			name_background.modulate = Color(1.0, 1.0, 1.0, 1.0)
