shader_type spatial;
render_mode unshaded, blend_mix;

uniform sampler2D image: filter_linear_mipmap;
uniform sampler2D image_normal: filter_linear_mipmap;

uniform vec3 light_direction = vec3(0.0);

uniform vec3 atmosphere_colour: source_color;
uniform float min_atmosphere: hint_range(0.0, 1.0, 0.01) = 0.05;
uniform float max_atmosphere: hint_range(0.0, 1.0, 0.01) = 0.6;
uniform float atmos_amount: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float atmos_haloblend: hint_range(0.0, 5.0, 0.01) = 3.0;

uniform float planet_radius: hint_range(0.0, 5.0, 0.01) = 1.0;
uniform float planet_tiling_scale: hint_range(0.0, 10.0, 0.01) = 1.0;
uniform float planet_spin_speed: hint_range(0.0, 10.0, 0.01) = 0.0;
uniform float planet_pitch: hint_range(-1.0, 1.0, 0.01) = 0.0;
uniform float planet_roll: hint_range(-1.0, 1.0, 0.01) = 0.0;

uniform float distance_threshold: hint_range(0.0, 1.0, 0.01) = 0.5;

// rotation matrix
mat3 create_rotation_matrix(float pitch, float roll) {
	float cosPitch = cos(pitch);
	float sinPitch = sin(pitch);
	float cosRoll = cos(roll);
	float sinRoll = sin(roll);
	
	mat3 result = mat3(
		vec3(cosRoll, -sinRoll * cosPitch, sinRoll * sinPitch),
		vec3(sinRoll, cosRoll * cosPitch, -cosRoll * sinPitch),
		vec3(0.0, sinPitch, cosPitch));
		
	return result;
}


// circle mask
float circle_mask(vec2 uv, float radius) {
	return length(uv) < radius? 1.0: 0.0;
}

// reconstruct z surface normal
vec3 reconstruct_surface(vec2 uv) {
	float z_sqrd = 1.0 - dot(uv, uv);
	float z = sqrt(z_sqrd);
	return vec3(uv, z);
}


// combine above functions into one
vec4 generate_sphere_surface_with_mask(vec2 uv, float radius) {
	float radius_sqrd = radius * radius;
	float uv_length_sqrd = dot(uv, uv);
	float mask = step(uv_length_sqrd, radius * radius);
	vec3 surface = vec3(0.0);
	if(mask > 0.0) {
		surface = vec3(uv / radius, sqrt(radius_sqrd - uv_length_sqrd));
	}
	return vec4(surface, mask);
}



// create spherical UVs
vec2 generate_spherical_uv(vec3 position, float scale, float spin) {
	float width = sqrt(1.0 - position.y * position.y);
	float generatrix_x = position.x / width * sign(position.z);
	vec2 generatrix = vec2(generatrix_x, position.y);
	vec2 uv = asin(generatrix) / PI * scale + vec2(0.5 + spin, 0.5);
	return vec2(uv);
}

vec2 polar_patch_mapping(vec3 position, float scale, float spin) {
	float width = sqrt(1.0 - position.y * position.y);
	float generatrix_x = position.x / width * sign(position.z);
	vec2 generatrix = vec2(generatrix_x, position.y);
	vec2 uv = asin(generatrix) / PI * scale + vec2(0.5 + spin, 0.5);
	return vec2(uv);
}

vec4 atmosphere( vec4 sphereSurfaceWithMask){
    vec3 atmosphereColor = vec3(1.0, 0.0, 0.0);
    float minAtmosphere = 0.05;
    float maxAtmosphere = 0.6;
    float fresnelBlend = pow(1.0 - sphereSurfaceWithMask.z, 2.5);
    float amount = mix(minAtmosphere, maxAtmosphere, fresnelBlend);
    vec3 normal = sphereSurfaceWithMask.xyz;
    if(sphereSurfaceWithMask.w < 0.5)
    {
        float haloBlend = pow(max(1.0 - sphereSurfaceWithMask.z*5.0, 0.0), 3.0);
        amount = haloBlend * maxAtmosphere;
        normal = vec3(sphereSurfaceWithMask.xy, 0.0);
    }
    float light = max(dot(normal, light_direction) + 0.3, 0.0)*1.5;
    vec3 litAtmosphere =  light * atmosphereColor;
    return vec4(litAtmosphere, amount);
}


// basic light
float lambertian_light(vec3 normal, vec3 light_direction_) {
	float NdotL = max(dot(normal, light_direction_), 0.0);
	return NdotL;
}


void fragment() {
	// Get vertex position in world space
	vec3 vertex_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	vec4 sphere_surface_with_mask = generate_sphere_surface_with_mask(UV, planet_radius);
	float mask = clamp(sphere_surface_with_mask.w, 0.0, 1.0);
	
	// set up tbn
	vec3 tangent = normalize(TANGENT);
	vec3 bitangent = normalize(BINORMAL);
	vec3 surface_normal = normalize(NORMAL);
	mat3 TBN = mat3(tangent, bitangent, surface_normal);
	
	
	
	float light = clamp(lambertian_light(sphere_surface_with_mask.xyz, normalize(light_direction)), 0.003, 1.0);
	
	mat3 rotation_matrix = create_rotation_matrix(planet_pitch, planet_roll);
	vec3 rotated_sphere = rotation_matrix * (sphere_surface_with_mask.xyz * mask);
	
	vec2 spherical_uv = generate_spherical_uv(rotated_sphere, planet_tiling_scale, TIME * planet_spin_speed);
	vec3 surface_texture = texture(image, spherical_uv).rgb;
	vec3 normal_texture = texture(image_normal, spherical_uv).rgb;
	
	normal_texture = normal_texture * 2.0 - 1.0;
	vec3 world_normal = TBN * normal_texture;
	
	vec4 _atmosphere = atmosphere(sphere_surface_with_mask);
	
	vec3 planet = mix(vec3(0.0), surface_texture * (light), mask);
	vec3 result = mix(planet, _atmosphere.xyz, _atmosphere.w);
	
	float distance_surface = distance(mask, distance_threshold);
	float uv_length = 1.0 - length(UV);
	float atmos_mask = smoothstep(min_atmosphere, max_atmosphere, uv_length) - mask;
	
	float atmos_light = max(dot(sphere_surface_with_mask.xyz, light_direction) + 0.3, 0.0)*1.5;
	vec3 full_atmos = (abs(atmos_mask) * atmosphere_colour) * (atmos_light+0.2);
	
	ALBEDO = planet + (full_atmos * atmos_amount);
	//ALBEDO = vec3(atmos_light);
	NORMAL_MAP = world_normal;
	ALPHA = mask + atmos_mask;
}
