shader_type spatial;

uniform sampler2D input_voronoi;


varying vec3 my_pos;

render_mode
		diffuse_toon,
		unshaded;

void fragment() {
	vec2 base_uv = UV;
	base_uv *= vec2(2.0);
	
	vec4 input_voronoi_tex = texture(input_voronoi, base_uv);
	
	
	ALBEDO = texture(input_voronoi, base_uv).rgb;
}
