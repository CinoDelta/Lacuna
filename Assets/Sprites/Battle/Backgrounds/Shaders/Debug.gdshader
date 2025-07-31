shader_type canvas_item;

uniform float screen_height = 324.0;
uniform int screen_width = 576;

void fragment() {
	// Place fragment code here.
	// float diff_x = -0.1 * sin((9.0 * UV.y) + (1.0 * TIME));
	float diff_x = 0.05 * cos(UV.x/2.0 + (TIME));
	float diff_y = 0.05 * sin(UV.y/2.0 + TIME);
	
	COLOR = texture(TEXTURE, vec2(UV.x + diff_x, UV.y + diff_y));
	COLOR = mix(vec4(0.5), COLOR, float(int(UV.x * screen_height) % 5));
}