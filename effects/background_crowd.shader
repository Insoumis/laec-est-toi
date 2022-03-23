shader_type canvas_item;

const float CIRCLE = 6.28;

uniform float hop_amplitude = 0.004;
uniform float hop_speed = 1.1;  // hops per second

varying float hop;

void vertex() {
	hop = hop_amplitude * abs(sin(TIME*CIRCLE*hop_speed*0.5));
}
void fragment() {
	vec2 offset = vec2(0.0, 0.0);
	
	//offset.y += hop;
	
	offset.y += hop_amplitude * abs(sin(TIME*CIRCLE*hop_speed*0.5 - CIRCLE*abs(UV.x-0.5)*0.5));
	
	offset += vec2(0.0, 0.005*sin(UV.x*80.0+TIME));
	
	vec4 pixel = texture(TEXTURE, UV + offset);
	
	if (UV.y > 0.8) {
		//pixel.r = 1.0;
	}
	
	COLOR = pixel;
	
	
	
}