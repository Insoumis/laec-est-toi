shader_type canvas_item;

uniform vec4 primary_color : hint_color = vec4(1.0, 0.2, 0.0, 1.0);
uniform vec4 secondary_color : hint_color = vec4(0.0, 1.0, 0.618, 1.0);
uniform vec4 ternary_color : hint_color = vec4(0.1, 0.3, 1.0, 1.0);
uniform vec4 quaternary_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform bool use_primary_texture = false;
uniform sampler2D primary_texture;
uniform bool use_secondary_texture = false;
uniform sampler2D secondary_texture;
uniform bool use_ternary_texture = false;
uniform sampler2D ternary_texture;
uniform bool use_quaternary_texture = false;
uniform sampler2D quaternary_texture;


// Circle constant, not in GLSL (sigh)
const float TAU = 6.2831853071795864769252867665590057683943387987502116419;

varying float hopper;
varying float dopper;
varying float bopper;

varying float epi_a;
varying float epi_b;
varying float epi_c;
varying float epi_d;

void vertex() {
	float t = TIME * 0.25;
	hopper = abs(sin(t));
	dopper = sin(t+TAU/4.0) < 0.0 ? 1.0 : 0.0;
	bopper = sin(t+TAU/2.0) < 0.0 ? 1.0 : 0.0;
	
//	epi_a = 3125.0;
//	epi_a += epi_a * 0.618 * 0.618 * 0.618 * sin(t * 0.5);
//	epi_b = 12500.0;
//	epi_b += epi_b * 0.618 * 0.618 * 0.618 * sin(t * 8.0);
//	epi_c = 18750.0;
//	epi_c += epi_c * 0.618 * 0.618 * 0.618 * sin(t * 2.0);
//	epi_d = 1536.0;
//	epi_d += epi_d * 0.618 * 0.618 * 0.618 * sin(t * 4.0);
}

void fragment() {
	float x = UV.x;
	float y = UV.y;
	float xx = x*x;
	float yy = y*y;
	
	vec4 actual_primary_color = primary_color;
	vec4 actual_secondary_color = secondary_color;
	vec4 actual_ternary_color = ternary_color;
	vec4 actual_quaternary_color = quaternary_color;
	
	if (use_primary_texture) {
		actual_primary_color = texture(primary_texture, UV);
	}
	if (use_secondary_texture) {
		actual_secondary_color = texture(secondary_texture, UV);
	}
	if (use_ternary_texture) {
		actual_ternary_color = texture(ternary_texture, UV);
	}
	if (use_quaternary_texture) {
		actual_quaternary_color = texture(quaternary_texture, UV);
	}
	
	vec4 drape_color = vec4(0.0, 0.0, 0.0, 1.0);
	if (0.0 < x+yy-2.0*hopper) {
		if (dopper > 0.0) {
			drape_color = actual_primary_color;
		} else {
			drape_color = actual_secondary_color;
		}
	}
	else if (0.0 < xx+y-2.0*hopper) {
		if (dopper > 0.0) {
			drape_color = actual_secondary_color;
		} else {
			drape_color = actual_primary_color;
		}
	}
	else if (0.0 < xx*x+yy-1.0*hopper) {
		if (bopper > 0.0) {
			drape_color = actual_ternary_color;
		} else {
			drape_color = actual_quaternary_color;
		}
	} else {
		if (bopper > 0.0) {
			drape_color = actual_quaternary_color;
		} else {
			drape_color = actual_ternary_color;
		}
	}
	
	float xc = x*2.0-1.0;
	float yc = y*2.0-1.0;
	
	if (xc*xc*(1.0+0.1*hopper)+yc*yc*(1.0-0.1*hopper) < 0.5) {
		drape_color = quaternary_color;
	}
	
	// Too expensive
//	xc *= 1.618;
//
//	float y2 = yc*yc;
//	float y4 = y2*y2;
//	float y6 = y2*y4;
//	float y8 = y4*y4;
//	float x2 = xc*xc;
//	float x3 = x2*xc;
//	float x4 = x2*x2;
//	float x6 = x4*x2;
//	float x8 = x4*x4;
//	float e = 
//		epi_a*x8
//		+epi_b*x6*y2
//		-2500.0*x6
//		+epi_c*x4*y4
//		-7500.0*x4*y2
//		-50.0*x4
//		-512.0*x3
//		+12500.0*x2*y6
//		-7500.0*x2*y4
//		-100.0*x2*y2
//		-36.0*x2
//		+epi_d*xc*y2
//		+3125.0*y8
//		-2500.0*y6
//		-50.0*y4
//		-36.0*y2
//		-27.0;
//
//	if (e <= 0.0) {
//		drape_color = quaternary_color;
//		if (e < -450.0) {
//			drape_color.r = 0.8+0.2*hopper;
//			drape_color.g = 0.8;
//		}
//	}
	
	COLOR = drape_color;
}