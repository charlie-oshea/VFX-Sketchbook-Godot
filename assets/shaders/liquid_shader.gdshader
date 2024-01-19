shader_type spatial;
render_mode world_vertex_coords;

uniform float step_test;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 world_space = world_position - VERTEX;
	float top = step(world_space.y, step_test);
	ALPHA = top;
}
