shader_type spatial;
render_mode
		blend_mix,
		depth_prepass_alpha,
		cull_disabled,
		unshaded,
		alpha_to_coverage_and_one,
		world_vertex_coords;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : 
		source_color,
		filter_linear_mipmap,
		repeat_enable;

uniform vec3 uv_scale = vec3(1,1,0);
uniform vec3 uv_offset;

uniform vec4 texture_colour_front : source_color;
uniform vec4 texture_colour_back : source_color;

uniform float erosion_val : hint_range(0.0, 1.0, 0.1);
uniform float erosion_offset = 0.1;

varying float dot_value;

void vertex() {
	UV = UV * uv_scale.xy + uv_offset.xy * TIME;
	
	vec3 cam_dir = CAMERA_POSITION_WORLD - VERTEX;
	
	
	dot_value = dot(NORMAL, cam_dir);
	dot_value = sign(dot_value);
	
	dot_value = fma(dot_value, 0.5, 0.5);
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	albedo_tex *= COLOR;
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALPHA_ANTIALIASING_EDGE = 0.1;
	
	vec4 colour_tex = mix(
		texture_colour_back,
		texture_colour_front,
		dot_value
	);
	
	ALBEDO = albedo_tex.rgb * colour_tex.rgb;
	ALPHA = albedo.a * albedo_tex.a;
	
	float erosion = smoothstep(
			erosion_val,
			erosion_val + erosion_offset,
			albedo_tex.r
	);
	
	ALPHA *= erosion;
}
