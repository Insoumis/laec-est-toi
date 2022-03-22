shader_type canvas_item;

uniform float swirl_wobble_speed = 0.5;
uniform float swirl_amplitude_a = 0.011;
uniform float swirl_speed_a = 1.00;
uniform float swirl_amplitude_b = 0.003;
uniform float swirl_speed_b = -3.00;

const float TAU = 6.28;

varying vec2 current_offset_a;
varying vec2 current_offset_b;

void vertex() {
	float amplitude_a = abs(swirl_amplitude_a * sin(swirl_wobble_speed*TIME));
	float amplitude_b = abs(swirl_amplitude_b * sin(swirl_wobble_speed*TIME+TAU*0.25));
	current_offset_a = vec2(
		amplitude_a * sin(TIME*swirl_speed_a),
		amplitude_a * sin(TIME*swirl_speed_a + TAU*0.25)
	);
	current_offset_b = vec2(
		amplitude_b * sin(TIME*swirl_speed_b),
		amplitude_b * sin(TIME*swirl_speed_b + TAU*0.25)
	);
}

void fragment() {
	COLOR = vec4(UV.x, UV.y, 0.0, 1.0);
	COLOR = texture(TEXTURE, UV);
	vec4 pixel = texture(TEXTURE, UV);
	vec4 pixel_a = texture(TEXTURE, UV + current_offset_a);
	vec4 pixel_b = texture(TEXTURE, UV + current_offset_b);
	vec4 final_pixel;
	final_pixel = pixel;  // we do make a copy here
	final_pixel = mix(final_pixel, pixel_a, 0.38);
	final_pixel = mix(final_pixel, pixel_b, 0.38);
	COLOR = final_pixel;
//	COLOR = pixel;  // restore original behavior
}