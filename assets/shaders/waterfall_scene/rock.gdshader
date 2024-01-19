shader_type spatial;

group_uniforms colours;
uniform vec3 top_colour : source_color = vec3(0.0);
uniform vec3 side_colour : source_color = vec3(0.0);

group_uniforms side_mask;
uniform float offset : hint_range(-1.0, 1.0) = 0.5;
uniform float fade : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	vec3 up_vector_viewspace = mat3(VIEW_MATRIX) * vec3(0.0, 1.0, 0.0);
	float dot_product = dot(up_vector_viewspace, NORMAL);
	float side_mask = smoothstep(offset - fade, offset + fade, dot_product);
	
	vec3 final_colour = mix(side_colour, top_colour, side_mask);
	
	ALBEDO = final_colour;
}
