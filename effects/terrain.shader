shader_type canvas_item;

varying vec2 vert;

void vertex(){
    vert = VERTEX;
}

void fragment() {
	vec4 tile_color = texture(TEXTURE, UV);
	vec3 black = vec3(0.0, 0.0, 0.0);
	if (tile_color.a > 0.0) {
		COLOR.rgb = mix(tile_color.rgb, black, 0.3);
	} else {
		COLOR = tile_color;
	}
}