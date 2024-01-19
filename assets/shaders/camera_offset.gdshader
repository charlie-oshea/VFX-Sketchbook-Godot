shader_type spatial;

render_mode
		blend_add,
		unshaded,
		world_vertex_coords; // Important!

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : 
		source_color,
		filter_linear_mipmap,
		repeat_enable;

uniform vec3 uv_scale = vec3(1,1,0);
uniform vec3 uv_offset;

uniform float cam_offset = 0.0;

uniform float CAM_DIST_LIMIT = 0.1;

void vertex() {
	UV = UV * uv_scale.xy + uv_offset.xy;
	
	// Calculate direction from camera to vertex
	vec3 cam_dir = CAMERA_POSITION_WORLD - VERTEX;
	vec3 cam_dir_norm = normalize(cam_dir);
	float cam_dir_dist = length(cam_dir_norm);
	
	// Offset vertices without clamp
	//VERTEX += cam_offset * cam_dir_norm;
	
	// Offset vertices and clamp so doesnt go past camera
	VERTEX += min(cam_offset, cam_dir_dist - CAM_DIST_LIMIT) * cam_dir_norm;
	
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb + albedo_tex.rgb;
	
	ALPHA = albedo.a * albedo_tex.r;
}
