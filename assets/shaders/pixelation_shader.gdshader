shader_type canvas_item;
render_mode unshaded;

uniform float pixel_size : hint_range(0.0, 16.0, 0.1);

uniform sampler2D SCREEN_TEXURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	float x = FRAGCOORD.x - mod(FRAGCOORD.x, pixel_size);
	float y = FRAGCOORD.y - mod(FRAGCOORD.y, pixel_size);
	
	float pixel_shift = floor(pixel_size / 2.0);
	
	COLOR = texture(SCREEN_TEXURE, vec2(x + pixel_shift, y + pixel_shift) * SCREEN_PIXEL_SIZE);
}
