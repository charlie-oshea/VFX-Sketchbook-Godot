shader_type spatial;
render_mode
		blend_mix,
		unshaded,
		world_vertex_coords;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float BLACK_HOLE_SIZE = 3.0;
uniform float BLACK_HOLE_FRESNEL = 1.0;

// ** Fresnel function from https://godotshaders.com/snippet/fresnel/ **
float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void _raycast_float(vec3 ray_origin, vec3 ray_dir, vec3 sphere_origin, float sphere_size,
out float hit, out vec3 hit_pos, out vec3 hit_normal){
	hit_pos = vec3(0.0);
	hit_normal = vec3(0.0);
	
	float t = 0.0;
	vec3 L = sphere_origin - ray_origin;
	float tca = dot(L, ray_dir);
	
	if (tca < 0.0) {
		hit = 0.0;
		return;
	}
	
	float d2 = dot(L, L) - tca * tca;
	float radius2 = sphere_size * sphere_size;
	
	if (d2 > radius2) {
		hit = 0.0;
		return;
	}
	
	float thc = sqrt(radius2 - d2);
	t = tca - thc;
	
	hit = 1.0;
	hit_pos = ray_origin - ray_dir * t;
	hit_normal = normalize(hit_pos - sphere_origin);
}

void fragment() {
	// get ray origin and direction
	vec3 world_space_pixel_pos = ((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec3 ray_origin = CAMERA_POSITION_WORLD;
	vec3 ray_dir = normalize(world_space_pixel_pos - ray_origin);
	
	// Out variables for raycast
	float hit; vec3 hit_pos; vec3 hit_normal;
	
	// Raycast
	_raycast_float(ray_origin, ray_dir, vec3(0.0), BLACK_HOLE_SIZE, hit, hit_pos, hit_normal);
	
	// Apply fresnel
	float blackhole_fresnel = fresnel(BLACK_HOLE_FRESNEL, hit_normal, CAMERA_POSITION_WORLD);
	vec3 blackhole_col = vec3(blackhole_fresnel);
	blackhole_col *= 0.01;
	
	// Fresnel UV distortion falloff
	float f = dot(NORMAL, normalize(CAMERA_POSITION_WORLD - VERTEX));
	f = clamp(f, 0.0, 1.0);
	f = (1.0 - acos(f)/1.57) * 0.4;
	f = pow(f, 1.0);
	
	// Distance scaling NOT WORKIN RN
//	float dist = distance(CAMERA_POSITION_WORLD, VERTEX) * 2.0;
//	float tangent = tan(radians(70.0 * 0.5));
//	float d = (dist*tangent);
//
	
	
	// Get distance from center to pixel
	vec4 blackhole_center = vec4(0.0) * VIEW_MATRIX;
	vec2 distance_to_center = -normalize(blackhole_center.xy - SCREEN_UV) * f;
	
	// UV distortion
	// Test Distorion vec2 base_uv = vec2(sin(TIME + SCREEN_UV.g) * 0.1, 0.0) + SCREEN_UV;
	vec2 base_uv = SCREEN_UV + distance_to_center;
	
	
	
	
	vec3 scene_col = texture(screen_texture, base_uv, 0.0).xyz;
	
	ALBEDO = mix(scene_col, blackhole_col, hit);
	
}
