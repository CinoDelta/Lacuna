shader_type canvas_item;

uniform float screen_height = 500;
uniform int screen_width = 500;

void vertex() {
	// Called for every vertex the material is visible on.
	
}

void fragment() {
	// Called for every pixel the material is visible on.
	float diff_x = sin(TIME)/20.0;
	float diff_y = 0.2 * UV.y/2.0 - TIME/5.0;
	
	COLOR = texture(TEXTURE, vec2(UV.x + diff_x/1000.0, UV.y + diff_y));
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
