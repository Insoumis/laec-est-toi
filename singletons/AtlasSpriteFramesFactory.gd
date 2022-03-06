tool
extends Node

#          _   _            _____            _ _       ______
#     /\  | | | |          / ____|          (_) |     |  ____|
#    /  \ | |_| | __ _ ___| (___  _ __  _ __ _| |_ ___| |__ _ __ __ _ _ __ ___   ___  ___
#   / /\ \| __| |/ _` / __|\___ \| '_ \| '__| | __/ _ \  __| '__/ _` | '_ ` _ \ / _ \/ __|
#  / ____ \ |_| | (_| \__ \____) | |_) | |  | | ||  __/ |  | | | (_| | | | | | |  __/\__ \
# /_/    \_\__|_|\__,_|___/_____/| .__/|_|  |_|\__\___|_|  |_|  \__,_|_| |_| |_|\___||___/factory
#                                | |
#                                |_|
# 
# Meant to be used as a singleton.
# 
# Ideas for future improvements:
# - Dynamic atlas side size
# - Untangle spaghetti

# Try out exports instead of consts → easier override
const TEXTURE_SIZE = 2048
const QUADRANT_SIZE = 64

# Will look for sprites in here to include them in one of the atlases
export var sprites_directory := "res://sprites/items/"

# Atlas of item sprites not prefixed with `text_`
export var item_atlas_path := "res://sprites/atlas_items.png"
# Atlas of item sprites prefixed with `text_`
export var text_atlas_path := "res://sprites/atlas_texts.png"

export var atlas_data_path := "res://sprites/AtlasSpriteFramesDataCache.tres"


const AtlasSpriteFramesDataCacheType = preload("res://singletons/AtlasSpriteFramesDataCache.gd")
const SpriteFramesExporter = preload("res://core/SpriteFramesExporter.gd")

# @read_only
var item_atlas_image: StreamTexture
# @read_only
var text_atlas_image: StreamTexture

var final_result: AtlasSpriteFramesDataCacheType


class BlitLoadResult:
	extends Reference
	var region
	var error


func _init():
	initialize()


func initialize():
#	print("Readying atlas sprites frames factory…")
	set_name("AtlasSpriteFramesFactory")
	
	var are_file_requirements_satisfied := true
	var required_files = [
		self.item_atlas_path,
		self.text_atlas_path,
		self.atlas_data_path,
	]
	var file_tool := File.new()
	for required_file in required_files:
		if not file_tool.file_exists(required_file):
			are_file_requirements_satisfied = false
			print("Required file `%s' was not found." % required_file)
	
	# Forcing re-regen for now
	if not are_file_requirements_satisfied:
		print("Re-generating concepts atlasses and region data.")
		generate_spriteframes(collect_items())
#		yield(get_tree().create_timer(2), "timeout")
#		print("Done waiting.")
	#print("Loading…")
	load_from_files()


func collect_items():
	return ItemsPool.list_items_sorted()


func load_from_files():
	self.item_atlas_image = ResourceLoader.load(self.item_atlas_path)
	self.text_atlas_image = load(self.text_atlas_path)
	self.final_result = load(self.atlas_data_path)
	self.final_result.item_atlas_texture = ImageTexture.new()
	self.final_result.text_atlas_texture = ImageTexture.new()
	
	if self.item_atlas_image is StreamTexture:
		self.final_result.item_atlas_image = self.item_atlas_image.get_data().duplicate()
	else:
		printerr("AtlasSpriteFramesFactory: can't load item atlas texture")
	
	if self.text_atlas_image is StreamTexture:
		self.final_result.text_atlas_image = self.text_atlas_image.get_data().duplicate()
	else:
		printerr("AtlasSpriteFramesFactory: can't load text atlas texture")
	
	self.final_result.item_atlas_texture.create_from_image(self.final_result.item_atlas_image)
	self.final_result.text_atlas_texture.create_from_image(self.final_result.text_atlas_image)
	self.final_result.item_sprite_frames = SpriteFramesExporter.import_sprite_frames_dictionary(
		self.final_result.item_sprite_frames_dictionary,
		self.final_result.item_atlas_texture
	)
	self.final_result.text_sprite_frames = SpriteFramesExporter.import_sprite_frames_dictionary(
		self.final_result.text_sprite_frames_dictionary,
		self.final_result.text_atlas_texture
	)


func load_texture_and_blit(file_name, atlas_texture, index) -> BlitLoadResult: 
	var destination_rect = Rect2()
	destination_rect.size = Vector2(float(QUADRANT_SIZE), float(QUADRANT_SIZE))
	destination_rect.position = get_rect_pos_from_index(
		index, Vector2(float(TEXTURE_SIZE), float(TEXTURE_SIZE)), destination_rect.size
	)
	var texture_rect = Rect2(Vector2(0.0, 0.0), destination_rect.size)
	var result = BlitLoadResult.new()
	result.region = destination_rect
#	var texture = Image.new()
#	result.error = texture.load(file_name)
	var texture = load(file_name)
	if texture == null:
		result.error = ERR_CANT_OPEN
	else:
		result.error = OK
	if result.error == OK:
		#print("blitting %s at %d" % [file_name, index])
		atlas_texture.blit_rect(texture.get_data(), texture_rect, destination_rect.position)
		#print("done blitting")
	return result


func get_rect_pos_from_index(index, total_size, quadrant_size) -> Vector2:
	var x_flat_position = int(index * quadrant_size.x)
	var line_number = x_flat_position / int(total_size.x)
	var x = x_flat_position - line_number * int(total_size.x)
	var y = line_number * quadrant_size.y
#	print(Vector2(x, y))
	return Vector2(x, y)


func make_sprite_atlas_texture(atlas, region):
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = atlas
	atlas_texture.region = region
	return atlas_texture


func get_for_concept(_concept_name: String, is_text: bool) -> SpriteFrames:
	if not self.final_result:
		breakpoint  # make sure the cache is hydrated?  or remove me?
		return null
	
	if is_text:
		return self.final_result.text_sprite_frames
	else:
		return self.final_result.item_sprite_frames


func generate_spriteframes(items: Array):  # of PoolItem[]
	self.final_result = AtlasSpriteFramesDataCacheType.new()
	var text_index := 0
	var item_index := 0
	var items_sprite_frames = SpriteFrames.new()
	var texts_sprite_frames = SpriteFrames.new()
	
	self.final_result.item_atlas_image = Image.new()
	self.final_result.item_atlas_texture = ImageTexture.new()
	self.final_result.item_atlas_image.create(TEXTURE_SIZE, TEXTURE_SIZE, true, Image.FORMAT_RGBA8)
	self.final_result.item_atlas_texture.create_from_image(self.final_result.item_atlas_image)
	self.final_result.text_atlas_image = Image.new()
	self.final_result.text_atlas_texture = ImageTexture.new()
	self.final_result.text_atlas_image.create(TEXTURE_SIZE, TEXTURE_SIZE, true, Image.FORMAT_RGBA8)
	self.final_result.text_atlas_texture.create_from_image(self.final_result.text_atlas_image)
#	var destination_rect = Rect2(Vector2(0.0, 0.0), Vector2(float(QUADRANT_SIZE), float(QUADRANT_SIZE)))

	for item in items:
		for direction in item.animations:
			var animation = item.animations[direction]
			
			for animation_index in animation:
				var shivers_filepaths = animation[animation_index]
			
				var animation_name = "%s_%d" % [
					item.concept_full,
					animation_index
				]
				if direction != Directions.NONE:
					animation_name = "%s_%s_%d" % [
						item.concept_full,
						Directions.get_direction_string(direction),
						animation_index
					]
				
				if item.is_text:
					texts_sprite_frames.add_animation(animation_name)
					for frame_filepath in shivers_filepaths:
						
						var blit_load = load_texture_and_blit(
							frame_filepath,
							self.final_result.text_atlas_image, text_index
						)
						if blit_load.error == OK:
							var atlas_texture = make_sprite_atlas_texture(
								final_result.text_atlas_texture,
								blit_load.region
							)
							texts_sprite_frames.add_frame(animation_name, atlas_texture)
							text_index += 1
						else:
							printerr("Failed to load text texture and blit.")
				else:
					items_sprite_frames.add_animation(animation_name)
					for frame_filepath in shivers_filepaths:
						var blit_load = load_texture_and_blit(
							frame_filepath,
							self.final_result.item_atlas_image, item_index
						)
						if blit_load.error == OK:
							var atlas_texture = make_sprite_atlas_texture(
								final_result.item_atlas_texture,
								blit_load.region
							)
							
							items_sprite_frames.add_frame(animation_name, atlas_texture)
							item_index += 1
						else:
							printerr("Failed to load item texture and blit.")
	
	#print("Saving atlasses…")
	self.final_result.item_sprite_frames = items_sprite_frames
	self.final_result.text_sprite_frames = texts_sprite_frames
	self.final_result.items = items
	
	var error = self.final_result.item_atlas_image.save_png(self.item_atlas_path)
	if error != OK:
		printerr("AtlasSpriteFramesFactory: can't write item texture")
	error = self.final_result.text_atlas_image.save_png(self.text_atlas_path)
	if error != OK:
		printerr("AtlasSpriteFramesFactory: can't write text texture")
	
	var tex = load(self.item_atlas_path)
	if tex is StreamTexture:
		self.final_result.item_atlas_image = tex.get_data().duplicate()
	else:
		printerr("AtlasSpriteFramesFactory: can't load item atlas texture")
	tex = load(self.text_atlas_path)
	if tex is StreamTexture:
		self.final_result.text_atlas_image = tex.get_data().duplicate()
	else:
		printerr("AtlasSpriteFramesFactory: can't load text atlas texture")
	
#	final_result.item_atlas_image.take_over_path(self.item_atlas_path)
#	final_result.text_atlas_image.take_over_path(self.text_atlas_path)
	self.final_result.item_atlas_texture.create_from_image(final_result.item_atlas_image)
	self.final_result.text_atlas_texture.create_from_image(final_result.text_atlas_image)
	# A list of things I tried...
#	final_result.item_atlas_texture.set_data(final_result.item_atlas_image)
#	final_result.text_atlas_texture.set_data(final_result.text_atlas_image)
#	print(final_result.item_atlas_image)
#	print(final_result.text_atlas_image)
#	final_result.item_atlas_image.resource_path = "res://sprites/item_atlas_image.png"
#	final_result.text_atlas_image.resource_path = "res://sprites/text_atlas_image.png"
#	final_result.item_atlas_texture.image.resource_path = "res://sprites/item_atlas_image.png"
#	final_result.text_atlas_texture.image.resource_path = "res://sprites/text_atlas_image.png"
#	final_result.item_atlas_texture.image.take_over_path("res://sprites/item_atlas_image.png")
#	final_result.text_atlas_texture.image.take_over_path("res://sprites/text_atlas_image.png")
#	print(final_result.item_atlas_texture.image)
#	print(final_result.text_atlas_texture.image)
#	final_result.item_atlas_texture.create_from_image(final_result.item_atlas_image)
#	final_result.text_atlas_texture.create_from_image(final_result.text_atlas_image)
	self.final_result.item_sprite_frames_dictionary = SpriteFramesExporter.export_sprite_frames(items_sprite_frames)
	self.final_result.text_sprite_frames_dictionary = SpriteFramesExporter.export_sprite_frames(texts_sprite_frames)
	var flags = 0
#	ResourceSaver.save("res://sprites/AtlasSpriteFramesFactoryDataCacheItem.tres", final_result.item_sprite_frames, flags)
	self.final_result.item_atlas_image_path = self.item_atlas_path
	self.final_result.text_atlas_image_path = self.text_atlas_path
	var saved := ResourceSaver.save(self.atlas_data_path, final_result, flags)
	if OK != saved:
		printerr("AtlasSpriteFramesFactory: Could not save the altas sprite of items.")
	#final_result.take_over_path(self.atlas_data_path)
	
	self.final_result.item_sprite_frames = SpriteFramesExporter.import_sprite_frames_dictionary(
		self.final_result.item_sprite_frames_dictionary,
		self.final_result.item_atlas_texture
	)
	self.final_result.text_sprite_frames = SpriteFramesExporter.import_sprite_frames_dictionary(
		self.final_result.text_sprite_frames_dictionary,
		self.final_result.text_atlas_texture
	)


