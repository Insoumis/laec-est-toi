shader_type canvas_item;


// A shader for transitions without backbuffer.
// Apply it for example to a ColorRect inside a CanvasLayer.


uniform bool is_playing = false;

uniform float start_time_ms = 0.0;  // ms, from OS.get_ticks_ms()
uniform float current_time_ms = 0.0;  // ms, from OS.get_ticks_ms()
uniform float duration_ms = 1000.0;  // ms

uniform vec4 fade_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform bool is_fade_out = false;

uniform bool is_fade = false;
uniform bool is_vertical_stripes = false;
uniform bool is_horizontal_stripes = false;
uniform bool is_checkerboard = false;
uniform bool is_dots = false;
uniform bool is_clock = false;
uniform bool is_wavy = false;
uniform bool is_diamond = false;
uniform bool is_clock_grid = false;
uniform bool is_circly = false;


// Some options for the effects
uniform bool is_reversed = false;
uniform bool is_centered = false;
uniform bool is_flip_h = false;
uniform bool is_flip_v = false;

uniform float random_ratio = 0.0;  // between 0 and 1, included
uniform int cell_size = 50;  // pixels
varying float f_cell_size;  // memoization, float of cell_size

const float SQRT_2 = 1.4142135623730951; // square root of 2
const float TAU = 6.283185307179586; // circle constant

// These are computed in the vertex(), for performance
varying float progress_time_ms; // ms
varying float progress; // 0 to 1
varying float progress_reverse; // 1 to 0 (memoization)


void vertex() {
	//float current_time_ms = TIME * 1000.0;
	
	// We need a call to max() because somehow, it starts negative
	progress_time_ms = max(0.0, current_time_ms - start_time_ms);
	progress = progress_time_ms / duration_ms;
	progress_reverse = 1.0 - progress;
	f_cell_size = float(cell_size);
}


void fragment() {
	if (is_playing) {
		if (progress >= 0.0 && progress <= 1.0) {
			
			// I. Prepare some variables
			
			vec2 fragment_coord = FRAGCOORD.xy;
			vec2 uv_coord = UV;
			if (is_flip_h) {
				uv_coord.x = 1.0 - uv_coord.x;
			}
			if (is_flip_v) {
				uv_coord.y = 1.0 - uv_coord.y;
			}
			
			vec3 final_color = fade_color.rgb;
			float opacity = 0.0;
			
			// II. Apply chosen effects
			
			if (is_fade) {
				opacity = fade_color.a * progress;
			}
			
			if (is_vertical_stripes || is_checkerboard) {
				float local = float(int(fragment_coord.x) % cell_size);
				float threshold = progress * f_cell_size;
				if (is_reversed) {
					local = f_cell_size - local;
				}
				if (is_centered) {
					local = abs(local - f_cell_size*0.5);
					threshold = progress * f_cell_size * 0.5;
				}
				if (local < threshold) {
					opacity = fade_color.a;
				}
			}
			
			if (is_horizontal_stripes || is_checkerboard) {
				float local = float(int(fragment_coord.y) % cell_size);
				float threshold = progress * f_cell_size;
				if (is_reversed) {
					local = f_cell_size - local;
				}
				if (is_centered) {
					local = abs(local - f_cell_size*0.5);
					threshold = progress * f_cell_size * 0.5;
				}
				if (local < threshold) {
					opacity = fade_color.a;
				}
			}
			
			if (is_dots) {
				vec2 local = vec2(
					float(int(fragment_coord.x) % cell_size),
					float(int(fragment_coord.y) % cell_size)
				);
				if (is_centered) {
					local = local - vec2(f_cell_size/2.0, f_cell_size/2.0);
				} else {
					local = local / 2.0;
				}
				if (
					length(local) * SQRT_2
					<=
					progress * float(cell_size)
				) {
					opacity = fade_color.a;
				}
			}
			
			if (is_clock) {
				vec2 local = vec2(
					uv_coord.x - 0.5,
					uv_coord.y - 0.5
				);
				
				float angle = atan(local.x, local.y) + TAU / 2.0;
				if (is_reversed) {
					angle = TAU - angle;
				}
				
				if (angle <= TAU * progress) {
					opacity = fade_color.a;
				}
			}
			
			if (is_wavy) {
				
				vec2 local_uv = vec2(
					uv_coord.x - 0.5,
					uv_coord.y - 0.5
				);
				if (is_centered) {  // rotated, since centered means little here
					local_uv = vec2(local_uv.y, local_uv.x);
				}
				// SNIPPET
//				vec2 ratio_in_cell = vec2(
//					float(int(fragment_coord.x) % cell_size) / float(cell_size),
//					float(int(fragment_coord.y) % cell_size) / float(cell_size)
//				);
//				vec2 ratio_in_cell_centered = ratio_in_cell - vec2(0.5, 0.5);
				float p3 = progress * progress * progress;
				float p5 = progress * progress * progress * progress * progress;
				if (is_reversed) {
					p3 = pow(1.0 - progress, 3.0);
					p5 = pow(1.0 - progress, 5.0);
				}
				float wave = 0.1 * sin(local_uv.x * 42.0 * p3);
				float epsilon = 0.0001;
				
				if (is_reversed) {
					if (
						(local_uv.y > wave + p5 - epsilon)
						||
						(local_uv.y < wave - p5 + epsilon)
					) {
						opacity = fade_color.a;
					}
				} else {
					if (
						(local_uv.y < wave + p5 - epsilon)
						&&
						(local_uv.y > wave - p5 + epsilon)
					) {
						opacity = fade_color.a;
					}
				}
			}
			
			if (is_diamond) {
				
				float delay = UV.x;
//				if (is_reversed) {
//					delay = 1.0 - delay;
//				}
				
				vec2 ratio_in_cell = vec2(
					float(int(fragment_coord.x) % cell_size) / float(cell_size),
					float(int(fragment_coord.y) % cell_size) / float(cell_size)
				);
				vec2 ratio_in_cell_centered = ratio_in_cell - vec2(0.5, 0.5);
				vec2 abs_ratio_in_cell = abs(ratio_in_cell_centered);
				if (
					(abs_ratio_in_cell.x + abs_ratio_in_cell.y < progress)
				) {
					opacity = fade_color.a;
				}
				
			}
			
			if (is_clock_grid) {
				
				vec2 ratio_in_cell = vec2(
					float(int(fragment_coord.x) % cell_size) / float(cell_size),
					float(int(fragment_coord.y) % cell_size) / float(cell_size)
				);
				vec2 ratio_in_cell_centered = ratio_in_cell - vec2(0.5, 0.5);
				
				float angle = atan(ratio_in_cell_centered.x, ratio_in_cell_centered.y) + TAU / 2.0;
				if (is_reversed) {
					angle = TAU - angle;
				}
				
				if (angle <= TAU * progress) {
					opacity = fade_color.a;
				}
			}
			
			if (is_circly) {
				
				vec2 ratio_in_cell = vec2(
					float(int(fragment_coord.x) % cell_size) / float(cell_size),
					float(int(fragment_coord.y) % cell_size) / float(cell_size)
				);
				vec2 ratio_in_cell_centered = ratio_in_cell - vec2(0.5, 0.5);
				
				float angle = atan(ratio_in_cell_centered.x, ratio_in_cell_centered.y) + TAU / 2.0;
				if (is_reversed) {
					angle = TAU - angle;
				}
				
				float dist = length(ratio_in_cell_centered) / (0.7071);
				float sind = sin(dist+(random_ratio*random_ratio*180.0*dist));
				
				if (sind*sind*sind - 1.0 + progress * 2.0 >= 0.0) {
					opacity = fade_color.a;
				}
			}
			
			// III. 
			
			// IV. Invert when relevant
			
			if (is_fade_out) {
				opacity = 1.0 - opacity;
			}
			
			// V. Finally, set the color
			
			COLOR = vec4(final_color, opacity);
		} else {
			if (is_fade_out) {
				COLOR.a = 0.0;
			} else {
				COLOR = fade_color;
			}
		}
	} else {
		// The transition is not playing → let's be transparent
		COLOR.a = 0.0;
//		COLOR.r = 1.0;
	}
}