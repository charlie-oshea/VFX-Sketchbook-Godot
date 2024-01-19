shader_type spatial;
render_mode
		blend_mix,
		depth_draw_opaque,
		cull_back,
		diffuse_burley,  
		specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : 
		source_color,
		filter_linear_mipmap,
		repeat_enable;

uniform float roughness : hint_range(0.0, 1.0);

uniform vec3 uv_scale;
uniform vec3 uv_offset;

uniform float vertex_offset_intensity = 0.1;

void vertex() {
	UV = UV * uv_scale.xy + uv_offset.xy * TIME;
	
	vec4 albedo_tex = textureLod(texture_albedo, UV, 0);
	VERTEX += NORMAL * albedo_tex.r * vertex_offset_intensity;
}


void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo, UV);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	ROUGHNESS = roughness;
}
