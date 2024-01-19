shader_type spatial;

uniform sampler2D water_tex : filter_linear_mipmap;

uniform float displacement_amount : hint_range(0.0, 10.0, 0.01);
uniform float distortion_scale : hint_range(-10.0, 10.0, 0.01) = 1.0;
uniform vec3 distortion_offset = vec3(0.0);
uniform float distortion_speed : hint_range(0.0, 10.0, 0.01);

void vertex() {
	float distortion_tex = texture(water_tex,
	UV * vec2(distortion_scale) + distortion_offset.xy * distortion_speed * TIME).z;
	
	VERTEX += distortion_tex * displacement_amount * NORMAL;
}

void fragment() {
	// Place fragment code here.
}
