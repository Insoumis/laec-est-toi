shader_type canvas_item;

uniform float time_multiplier;
uniform float texture_time_multiplier;
uniform sampler2D blurry_multiplier_texture;
uniform float strength_time_multiplier;
uniform float strength_offset;
uniform float strength_multiplier;
uniform sampler2D multiplier_texture;

void fragment() {
	vec2 uv = UV + TIME * time_multiplier;
	vec2 uv2;
	uv2.x = UV.x - TIME * texture_time_multiplier;
	uv2.x += sin(TIME*0.5)*0.002;
	uv2.y = UV.y + TIME * texture_time_multiplier;
	uv2.y += sin(TIME*0.5)*0.002;

	COLOR = texture(TEXTURE, uv)*texture(multiplier_texture, vec2(1.0)-uv2)*
		(sin(TIME*strength_time_multiplier)*strength_multiplier+1.0+strength_offset)*
		texture(blurry_multiplier_texture, UV+TIME*0.02);
}