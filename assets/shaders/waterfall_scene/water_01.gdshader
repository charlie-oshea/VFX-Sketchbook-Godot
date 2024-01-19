shader_type spatial;
render_mode cull_back;

group_uniforms textures;
uniform sampler2D DEPTH_TEXTURE: hint_depth_texture;
uniform sampler2D water_tex : filter_linear_mipmap;

group_uniforms colours;
uniform float alpha : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform vec3 top_detail_colour : source_color = vec3(0.0);
uniform vec3 bottom_detail_colour : source_color = vec3(0.0);
uniform vec3 base_colour : source_color = vec3(0.0);

group_uniforms water;
uniform float water_scale : hint_range(-10.0, 50.0, 0.01) = 1.0;
uniform vec3 water_offset = vec3(0.0);
uniform float water_speed : hint_range(0.0, 10.0, 0.01);
uniform vec3 second_layer_offset = vec3(0.0);
uniform float second_layer_speed : hint_range(0.0, 10.0, 0.01) = 1.0;

group_uniforms waves;
uniform float edge_distance = 0.1;
uniform float edge_toggle : hint_range(0.0, 1.0, 1.0) = 1.0;
uniform float wave_size : hint_range(0.0, 20.0, 0.01) = 0.5;
uniform float wave_speed : hint_range(0.0, 20.0, 0.01) = 4.0;

group_uniforms displacement;
uniform float displacement_amount : hint_range(0.0, 1.0, 0.01) = 0.0;

group_uniforms distortion;
uniform float distortion_amount : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float distortion_scale : hint_range(-10.0, 10.0, 0.01) = 1.0;
uniform vec3 distortion_offset = vec3(0.0);
uniform float distortion_speed : hint_range(0.0, 10.0, 0.01);

group_uniforms side_mask;
uniform float offset : hint_range(-1.0, 1.0) = 0.5;
uniform float fade : hint_range(0.0, 1.0) = 0.1;

void vertex() {
	float distortion_tex = texture(water_tex,
	UV * vec2(distortion_scale) + distortion_offset.xy * distortion_speed * TIME).z;
	
	VERTEX = vec3(distortion_tex) * vec3(displacement_amount) * NORMAL + VERTEX;
}

void fragment() {
	// Apply distortion to UVs
	float distortion_tex = texture(water_tex,
	UV * vec2(distortion_scale) + distortion_offset.xy * distortion_speed * TIME).z;
	vec2 base_uv = UV;
	base_uv.y += distortion_tex * distortion_amount;
	
	// Apply movement to textures
	vec2 texture_water = texture(water_tex,
	base_uv * vec2(water_scale) + water_offset.xy * water_speed * TIME).xy;
	vec2 texture_water_2 = texture(water_tex,
	base_uv * vec2(water_scale) + water_offset.xy * second_layer_speed * water_speed * TIME + second_layer_offset.xy).xy;
	
	// Blend colours
	float detail_blend = step(0.5, 1.0 - ((1.0-texture_water.x) * texture_water_2.x));
	vec3 detail_colour = mix(bottom_detail_colour, top_detail_colour, detail_blend);
	float base_blend = step(0.5 ,texture_water.x + texture_water_2.x);
	vec3 colour = mix(base_colour, detail_colour, base_blend);
	
	// Proximity fade from proximity fade node
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV,0.0).r;
	
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float depth_texture_y = world.y / world.w;
	float vertex_y = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;
	
	// World normal modified from https://github.com/Arnklit/TutorialResources/blob/main/world_normal_mix_shader_4/world_normal_mix_4.gdshader
	
	vec3 up_vector_viewspace = mat3(VIEW_MATRIX) * vec3(0.0, 1.0, 0.0);
	float dot_product = dot(up_vector_viewspace, NORMAL);
	float side_mask = smoothstep(offset - fade, offset + fade, dot_product);
	
	float prox_blend = 1.0 - clamp((vertex_y - depth_texture_y) / edge_distance, 0.0, 1.0);
	float sin_ripple = abs(sin((prox_blend + TIME * wave_speed) * wave_size)) * prox_blend;
	float waves_mask = step(1.0, pow(prox_blend, 8.0) + sin_ripple);
	waves_mask = mix(0.0 ,waves_mask , side_mask);
	
	ALBEDO = mix(colour, top_detail_colour, waves_mask * edge_toggle);
	
	
	ALPHA = alpha;
}
