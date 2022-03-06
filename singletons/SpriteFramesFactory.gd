tool
extends Node
# Singleton

#   _____            _ _       ______
#  / ____|          (_) |     |  ____|
# | (___  _ __  _ __ _| |_ ___| |__ _ __ __ _ _ __ ___   ___  ___
#  \___ \| '_ \| '__| | __/ _ \  __| '__/ _` | '_ ` _ \ / _ \/ __|
#  ____) | |_) | |  | | ||  __/ |  | | | (_| | | | | | |  __/\__ \
# |_____/| .__/|_|  |_|\__\___|_|  |_|  \__,_|_| |_| |_|\___||___/
#        | |
#        |_|
# 
# SpriteFramesFactory v0.0.0
# 
# Responsibilities:
# - Build the animation frames `SpriteFrames` for a specific item
# - Try hard to load appropriate sprites from fallbacks
# - Handle its own cache, since fetching is expensive
# 
# Does not know about all the available item concepts.
#   → would simflify our internal logic greatly and make it smarter with less
#   → would require Finder
#   → dependency tree 404 T_T


var sprites_directory = "res://sprites"

# You need to always have a file <sprites_directory>/<undefined>.png
var undefined = "undefined"

# could be autodetected perhaps?
# zero is not supported atm
var shiver_length := 3

# Building the SpriteFrames is expensive, so we cache them
var __cache := Dictionary()  # hash => SpriteFrames
var __colors_cache := Dictionary()  # hash => Color


func __hash_for_cache(
	concept: String,
	is_text := false,
	subdir := 'items'
) -> String:
	
	return "%s|%s|%s" % [
		subdir, concept, str(is_text)
	]


func __serialize(concept: String, is_text: bool):
	if is_text:
		# Here we could use `-` instead of `_` to avoid collisions,
		# at the expense of less mnemonic (uglier!) file names.
		# Don't name a concept `text`, and we may keep homogenous file names.
		concept = "text_%s" % [concept]
	return concept


func get_color_for_concept(
	concept: String,
	is_text := false,
	subdir := 'items'
) -> Color:
	
	var h = __hash_for_cache(concept, is_text, subdir)
	if not self.__colors_cache.has(h):
		self.__colors_cache[h] = find_color_for_concept(
			concept,
			is_text,
			subdir
		)
	return self.__colors_cache[h]


func find_color_for_concept(
	concept: String,
	is_text := false,
	subdir := 'items'
) -> Color:
	
	concept = __serialize(concept, is_text)
	var color_filename := "%s/%s/%s_color.png" % [
		sprites_directory, subdir, concept,
	]
	if ResourceLoader.exists(color_filename):
		var color_texture: StreamTexture = ResourceLoader.load(color_filename)
		if color_texture:
			var color_image: Image = color_texture.get_data()
			color_image.lock()
			var color_pixel := color_image.get_pixel(0, 0)
			color_image.unlock()
			return color_pixel
	
	return Color.white


func get_for_concept(
	concept: String,
	is_text := false,
	subdir := 'items'
) -> SpriteFrames:
	
	var h = __hash_for_cache(concept, is_text, subdir)
	if not self.__cache.has(h):
		self.__cache[h] = make_for_concept(concept, is_text, subdir)
	return self.__cache[h]


func make_for_concept(
	concept: String,
	is_text := false,
	subdir := 'items'
) -> SpriteFrames:
	
	var sf := SpriteFrames.new()
	concept = __serialize(concept, is_text)
	
	for direction in Directions.STRINGS.values():
		var more := true  # ざわ…
		var state := 0  # animation states cursor, when many are provided
		while more:
			var animation := "%s_%d" % [direction, state]
			
			sf.add_animation(animation)
			
			for shiver in range(self.shiver_length):
				var found_it := false
				var flip_x := false
				
				# I.a Try the full path, with direction + animation + shiver
				# res://sprites/items/example_top_left_0_0.png
				var frame_filename := "%s/%s/%s_%s_%d.png" % [
					sprites_directory, subdir, concept, animation, shiver
				]
				
				# I.b Try the full path, with direction + shiver
				# res://sprites/items/example_left_0.png
				if not ResourceLoader.exists(frame_filename):
					frame_filename = "%s/%s/%s_%s_%d.png" % [
						sprites_directory, subdir,
						concept, direction,
						shiver,
					]
					more = false
				else:
					found_it = true
				
				# II.a Perhaps there's a direction we can degrade to?
				#      left|right + animation + shiver
				# res://sprites/items/example_left_0_0.png
				if not found_it and not ResourceLoader.exists(frame_filename):
					frame_filename = "%s/%s/%s_%s_%d_%d.png" % [
						sprites_directory, subdir,
						concept, Directions.coerce_to_left_or_right(direction),
						state, shiver,
					]
					if ResourceLoader.exists(frame_filename):
						found_it = true
						more = true
				else:
					found_it = true
				
				# II.b Perhaps there's a direction we can degrade to?
				#      left|right + shiver
				# res://sprites/items/example_left_0.png
				if not found_it and not ResourceLoader.exists(frame_filename):
					frame_filename = "%s/%s/%s_%s_%d.png" % [
						sprites_directory, subdir,
						concept, Directions.coerce_to_left_or_right(direction),
						shiver,
					]
					more = false
				else:
					found_it = true
				
				# III.a Perhaps there's an inverse direction we can degrade to?
				#      left|right + animation + shiver
				# res://sprites/items/example_left_0_0.png
				if not found_it and not ResourceLoader.exists(frame_filename):
					frame_filename = "%s/%s/%s_%s_%d_%d.png" % [
						sprites_directory, subdir,
						concept, Directions.inverse(
							Directions.coerce_to_left_or_right(direction)
						),
						state, shiver,
					]
					if ResourceLoader.exists(frame_filename):
						more = true
						flip_x = true
						found_it = true
				else:
					found_it = true
				
				# III.b Perhaps there's an inverse direction we can degrade to?
				#      left|right + shiver
				# res://sprites/items/example_left_0.png
				if not found_it and not ResourceLoader.exists(frame_filename):
					frame_filename = "%s/%s/%s_%s_%d.png" % [
						sprites_directory, subdir,
						concept, Directions.inverse(
							Directions.coerce_to_left_or_right(direction)
						),
						shiver,
					]
					if ResourceLoader.exists(frame_filename):
						flip_x = true
						found_it = true
				else:
					found_it = true
				
				# V. Ignore direction and animation, just try with shiver
				# This is how most of the `text` sprites work.
				# res://sprites/items/example_0.png
				if not found_it and not ResourceLoader.exists(frame_filename):
#					print("Nothing found at `%s`…" % frame_filename)
					frame_filename = "%s/%s/%s_%d.png" % [
						sprites_directory, subdir, concept, shiver,
					]
					more = false
				else:
					found_it = true
				
				# VI. Ignore direction, animation, shiver, everything.
				# res://sprites/items/example.png
				if not found_it and not ResourceLoader.exists(frame_filename):
					frame_filename = "%s/%s/%s.png" % [
						sprites_directory, subdir, concept,
					]
					more = false
				else:
					found_it = true
				
				# X.a When all else fails, go for shivering trolls
				if not found_it and not ResourceLoader.exists(frame_filename):
					frame_filename = "%s/%s/%s_%d.png" % [
						sprites_directory, subdir, self.undefined, shiver,
					]
#					printerr("Missing sprite for `%s` (animation=%s) (state=%d) (filename=%s)." % [
#						concept, animation, state, frame_filename,
#					])
				else:
					found_it = true
				
				# X.b When all else fails, go for static trolls
				if not found_it and not ResourceLoader.exists(frame_filename):
					frame_filename = "%s/%s/%s.png" % [
						sprites_directory, subdir, self.undefined,
					]
				else:
					found_it = true
				
				assert(
					ResourceLoader.exists(frame_filename),
					"Best make sure there's always an 'undefined' sprite " +
					"at " + frame_filename
				)
				
				var animation_texture = ResourceLoader.load(frame_filename)
				if flip_x:
					var animation_image : Image = animation_texture.get_data()
					animation_image.flip_x()
					#animation_texture.free() # is a Reference already
					animation_texture = ImageTexture.new()
					animation_texture.create_from_image(animation_image)
				sf.add_frame(animation, animation_texture)
			
			if state > 0 and not more:
				sf.remove_animation(animation)
			
			state += 1
		
	
	return sf

