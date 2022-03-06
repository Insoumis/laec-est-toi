tool
extends Node

static func export_sprite_frames(sprite_frames : SpriteFrames) -> Dictionary:
	var sprite_frames_dict = Dictionary()
	for animation_name in sprite_frames.get_animation_names():
		sprite_frames_dict[animation_name] = Array()
		for i in range(3):
			if sprite_frames.get_frame_count(animation_name) - 1 < i:
				continue
			var crop_texture = sprite_frames.get_frame(animation_name, i)
			if crop_texture:
				crop_texture.atlas = null
				sprite_frames_dict[animation_name].append(
						{
							"region" : crop_texture.region
						}
					)
	return sprite_frames_dict

static func import_sprite_frames_dictionary(dictionary : Dictionary, texture : Texture) -> SpriteFrames:
	var sprite_frames = SpriteFrames.new()
	for key in dictionary.keys():
		if key == "default":
			continue
		sprite_frames.add_animation(key)
		for i in range(3):
			if dictionary[key].size() -1 < i:
				continue
			var crop_texture = AtlasTexture.new()
			crop_texture.region = dictionary[key][i].region
			crop_texture.atlas = texture
			sprite_frames.add_frame(key, crop_texture)
	return sprite_frames
