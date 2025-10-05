shader_type canvas_item;

uniform float screen_height = 324.0;
uniform int screen_width = 576;

void fragment() {
	// Place fragment code here.
	// float diff_x = -0.1 * sin((9.0 * UV.y) + (1.0 * TIME));
	float diff_x = 0.2 * UV.x/2.0 - TIME/5.0;
	float diff_y = 0.2 * UV.y/2.0 - TIME/5.0;
	
	COLOR = texture(TEXTURE, vec2(UV.x + diff_x, UV.y + diff_y));
}