shader_type spatial;

render_mode unshaded;

uniform vec3 start_point = vec3(0);
uniform float pulse_width = 2.0;
uniform float radius;
uniform vec3 color: source_color = vec3(1.0);
uniform sampler2D pulse_tex;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

varying mat4 CAMERA;
varying vec3 my_pos;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
	CAMERA = INV_VIEW_MATRIX;
	my_pos = VERTEX;
}

void fragment() {
	vec4 original = texture(SCREEN_TEXTURE, SCREEN_UV);
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	
	// Normalized Device Coords
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	 
	// Convert world space from ndc
	vec4 world = CAMERA * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;
	
	// Calculate how far the fragment is (world space) from start point
	float dist = distance(world_position, start_point);
	float mix_ratio = 0.0;
	
	if (dist < radius && dist > radius - pulse_width) {
		mix_ratio = 1.0 - max(radius - dist, 0.0);
		mix_ratio = clamp(mix_ratio, 0.0, 1.0);
	}
	
	vec4 tex_overlay = texture(pulse_tex, my_pos.xz);
	
	vec3 final_col = mix(tex_overlay.rgb, color, mix_ratio);
	
	ALBEDO = mix(original.rgb, final_col, mix_ratio);
}
