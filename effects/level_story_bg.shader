shader_type canvas_item;

uniform bool enable_zoom_effect = true;
uniform float zoom_scale_a = 9.0;
uniform float zoom_speed_a = 1.0;
uniform float zoom_duration_a = 60.0; // NEVER ZERO

uniform bool enable_glow = false;
uniform sampler2D glow_texture;

varying float zoom_time_a;
varying float zoom_time_b;

const vec2 center = vec2(0.5, 0.5);

void vertex() {
	zoom_time_a = mod(TIME * zoom_speed_a, zoom_duration_a) / zoom_duration_a;
	zoom_time_b = mod(TIME * zoom_speed_a + zoom_duration_a*0.5, zoom_duration_a) / zoom_duration_a;
}

void fragment() {
	vec4 pixel;
	
	if (enable_zoom_effect) {
		vec2 uv_a = (UV-center)*zoom_scale_a*(1.0-zoom_time_a)+center;
		vec4 texture_pixel_a = texture(TEXTURE, mod(uv_a, 1.0));
		vec2 uv_b = (UV-center)*zoom_scale_a*(1.0-zoom_time_b)+center;
		vec4 texture_pixel_b = texture(TEXTURE, mod(uv_b, 1.0));
		
		if (zoom_time_a > zoom_time_b) { // z-fighting ring
			pixel = texture_pixel_a;
			if (texture_pixel_a.rgb == vec3(0.0)) {
				pixel = texture_pixel_b;
			}
		} else {
			pixel = texture_pixel_b;
			if (texture_pixel_b.rgb == vec3(0.0)) {
				pixel = texture_pixel_a;
			}
		}
	} else {
		pixel = texture(TEXTURE, UV);
	}
	
	if (enable_glow) {
		vec4 glow_pixel = texture(glow_texture, UV);
		glow_pixel = mix(glow_pixel, vec4(0.0), 0.3);
		pixel = mix(pixel, glow_pixel, 1.0 - length(pixel.rgb) * 4.0);
//		pixel.a = length(pixel.rgb)*8.0;
	}
	
	COLOR = pixel;
}