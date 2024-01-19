shader_type spatial;
render_mode unshaded;

uniform vec3 colour : source_color = vec3(1.0);

uniform float fresnel_power : hint_range(0.0, 10.0, 0.01) = 0.2;
uniform float voronoi_scale : hint_range(0.0, 10.0, 0.01) = 1.0;
uniform float voronoi_speed : hint_range(-3.0, 3.0, 0.01) = 0.0;


varying vec3 current_pos;

// *** Worley function from https://godotshaders.com/snippet/voronoi/ ***
vec2 random(vec2 uv) {
	return vec2(fract(sin(dot(uv.xy,
		vec2(12.9898,78.233))) * 43758.5453123));
}

float worley(vec2 uv, float columns, float rows) {
	
	vec2 index_uv = floor(vec2(uv.x * columns, uv.y * rows));
	vec2 fract_uv = fract(vec2(uv.x * columns, uv.y * rows));
	
	float minimum_dist = 1.0;  
	
	for (int y= -1; y <= 1; y++) {
		for (int x= -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x),float(y));
			vec2 point = random(index_uv + neighbor);
			
			vec2 diff = neighbor + point - fract_uv;
			float dist = length(diff);
			minimum_dist = min(minimum_dist, dist);
		}
	}
	
	return minimum_dist;
}

// *** Fresnel function from https://godotshaders.com/snippet/fresnel/ ***
float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

// *** Random function from https://thebookofshaders.com/10/ ***
float randomf(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
	vec3 final_colour = colour * fresnel(fresnel_power, NORMAL, VIEW);
	
	float alpha_clip = mix(1.0, 0.0, COLOR.r);
	
	vec2 v_base_uv1 = UV - (TIME * voronoi_speed);
	vec2 v_base_uv2 = UV + (TIME * voronoi_speed);
	
	vec3 texture_voronoi_1 = vec3(worley(v_base_uv1, voronoi_scale, voronoi_scale));
	vec3 texture_voronoi_2 = vec3(worley(v_base_uv2, voronoi_scale, voronoi_scale));
	
	texture_voronoi_1 *= texture_voronoi_2;
	
	ALBEDO = final_colour;
	ALPHA = texture_voronoi_1.r;
	ALPHA_SCISSOR_THRESHOLD = alpha_clip;
}
