shader_type sky;
render_mode
		use_half_res_pass;

group_uniforms sky_colours;
// colours
uniform vec3 day_top_colour : source_color = vec3(0.0);
uniform vec3 day_bottom_colour : source_color = vec3(0.0);

uniform vec3 sunset_top_colour : source_color = vec3(0.0);
uniform vec3 sunset_bottom_colour : source_color = vec3(0.0);

uniform vec3 night_top_colour : source_color = vec3(0.0);
uniform vec3 night_bottom_colour : source_color = vec3(0.0);
uniform float night_darkness : hint_range(0.0, 1.0, 0.01);

// Sunset and sun parameters
group_uniforms sun;
uniform float SUNSET_SIZE : hint_range(0.01, 3.0) = 0.5;
uniform float SUNSET_OPACITY : hint_range(0.0, 1.0) = 1.0;
uniform vec3 SUN_COLOUR: source_color = vec3(1.0);
uniform float SUN_SIZE: hint_range(0.01, 1.0) = 0.2;
uniform float SUN_BLUR: hint_range(0.01, 1.0) = 0.01;

group_uniforms moon;
uniform float MOON_SIZE : hint_range(0.01, 3.0) = 0.5;
uniform vec3 MOON_COLOUR: source_color = vec3(1.0);
uniform float MOON_BLUR: hint_range(0.01, 1.0) = 0.01;
uniform float CRESCENT_SIZE : hint_range(0.0, 3.0) = 0.5;
uniform float CRESCENT_BLUR: hint_range(0.01, 1.0) = 0.01;
uniform vec3 CRESCENT_OFFSET = vec3(0.0);

group_uniforms horizon;
uniform float HORIZON_HEIGHT: hint_range(0.0, 2.0) = 1.0;
uniform float HORIZON_OPACITY : hint_range(0.0, 1.0) = 1.0;
uniform vec3 HORIZON_COLOUR : source_color = vec3(0.0);
uniform vec3 HORIZON_SUNSET_COLOUR : source_color = vec3(0.0);

group_uniforms stars;
uniform sampler2D STARS_TEXTURE : filter_linear_mipmap, hint_default_black;
uniform float STARS_SPEED : hint_range( 0.0, 20.0, 0.01 ) = 1.0;

group_uniforms clouds;
uniform float CLOUD_TYPE : hint_range(0.0, 1.0, 0.01);
uniform float CLOUD_OPACITY : hint_range(0.0, 1.0, 0.01);
uniform sampler2D CLOUD_TEX_1 : filter_linear_mipmap;
uniform sampler2D CLOUD_TEX_2 : filter_linear_mipmap;
uniform sampler2D CLOUD_TEX_LARGE : filter_linear_mipmap;
uniform float CLOUD_SPEED : hint_range(0.0, 0.3, 0.001);
uniform float CLOUD_SIZE : hint_range(0.0, 1.0, 0.01);
uniform float CLOUD1_CLIP : hint_range(0.0, 2.0, 0.01) = 1.2;
uniform float CLOUD2_CLIP : hint_range(0.0, 2.0, 0.01) = 1.0;
uniform vec3 CLOUD_COLOUR : source_color = vec3(0.0);
uniform vec3 CLOUD_COLOUR_2 : source_color = vec3(0.0);
uniform float CLOUD_CUTTOFF_EDGE : hint_range(0.0, 1.0, 0.01);
uniform float CLOUD_CUTOFF_MAX : hint_range(0.0, 1.0, 0.01) = 0.6;
uniform float CLOUD_CUTOFF_MIN : hint_range(0.0, 1.0, 0.01) = 0.4;


// Voronoi method credit:
// The MIT License
// Copyright © 2013 Inigo Quilez
// https://www.shadertoy.com/view/ldl3Dl

vec3 hash( vec3 x ){
	x = vec3( dot(x,vec3(127.1,311.7, 74.7)),
			  dot(x,vec3(269.5,183.3,246.1)),
			  dot(x,vec3(113.5,271.9,124.6)));
	return fract(sin(x)*43758.5453123);
}

vec3 voronoi( in vec3 x ){
	vec3 p = floor( x );
	vec3 f = fract( x );
	
	float id = 0.0;
	vec2 res = vec2( 100.0 );
	for( int k=-1; k<=1; k++ )
	for( int j=-1; j<=1; j++ )
	for( int i=-1; i<=1; i++ ) {
		vec3 b = vec3( float(i), float(j), float(k) );
		vec3 r = vec3( b ) - f + hash( p + b );
		float d = dot( r, r );
		if( d < res.x ) {
			id = dot( p+b, vec3(1.0,57.0,113.0 ) );
			res = vec2( d, res.x );
		} else if( d < res.y ) {
			res.y = d;
		}
    }
    return vec3( sqrt( res ), abs(id) );
}
// Rotation Function UNUSED
mat3 y_3d_rotation_matrix(float angle) {
	float cos_angle = cos(angle);
	float sin_angle = sin(angle);
	// Create the 3x3 rotation matrix around the Y-axis
	mat3 m3 =  mat3(vec3(cos_angle, 0.0, sin_angle),vec3(0.0, 1.0, 0.0),vec3(-sin_angle, 0.0, cos_angle));
	return m3;
}

void sky() {
	vec2 sky_uv = EYEDIR.xz / EYEDIR.y;
	
	// Horizon
	float horizon_mask = 1.0 - smoothstep(0.55, 0.45, pow(SKY_COORDS.y, HORIZON_HEIGHT));
	vec3 horizon = vec3(horizon_mask) * HORIZON_OPACITY;
	
	
	// Detect when light is pointing in certain directions
	float day_amount = clamp(LIGHT0_DIRECTION.y, 0.0, 1.0);
	vec3 day_gradient = mix(day_bottom_colour, day_top_colour, clamp(EYEDIR.y, 0.0, 1.0)) * day_amount;
	
	float sunset_amount = clamp(1.0 - abs(LIGHT0_DIRECTION.y), 0.0, 1.0);
	vec3 sunset_gradient= mix(sunset_bottom_colour, sunset_top_colour,  clamp(EYEDIR.y, 0.0, 1.0)) * sunset_amount;
	
	// Sunset Sky Falloff
	float sun_distance = distance(EYEDIR.xyz, LIGHT0_DIRECTION) + 0.3;
	float sunset_power = 1.0 - clamp(sun_distance / SUNSET_SIZE, 0.0, 1.0);
	float sunset_disc = clamp(sunset_power / 1.0, sunset_power, 1.0);
	vec3 sunset_sky = sunset_gradient * (sunset_disc * SUNSET_OPACITY);
	
	float night_amount = clamp(-LIGHT0_DIRECTION.y, 0.0, 1.0);
	vec3 night_gradient = mix(night_bottom_colour, night_top_colour, clamp(EYEDIR.y, 0.0, 1.0)) * night_amount;
	
	// Horizon colouring at sunset
	vec3 horizon_colour_amount_sunset = clamp(horizon * clamp(1.0 - abs(LIGHT0_DIRECTION.y), 0.0, 1.0), 0.0, 1.0) * HORIZON_SUNSET_COLOUR;
	vec3 horizon_col = HORIZON_COLOUR * horizon_colour_amount_sunset;
	// Horizon sun scattering "logic" <- reeeallly stretching the word logic here
	horizon = mix(horizon, vec3(0.0), night_amount) * horizon_col * vec3(pow(sunset_disc, 2.0));
	horizon = mix(horizon, vec3(horizon_mask) * HORIZON_OPACITY, day_amount);
	
	// Sun
	float sun_power = 1.0 - clamp(sun_distance / SUN_SIZE, 0.0, 1.0);
	float sun_disc = clamp(sun_power / SUN_BLUR, sun_power, 1.0);
	vec3 sun = SUN_COLOUR * sun_disc;
	
	// Moon
	float moon_distance = distance(EYEDIR.xyz, -LIGHT0_DIRECTION) + 0.3;
	float moon_power = 1.0 - clamp(moon_distance / MOON_SIZE, 0.0, 1.0);
	float moon_disc = clamp(moon_power / MOON_BLUR, moon_power, 1.0);
	// Moon Crescent
	float crescent_distance = distance(EYEDIR.xyz + CRESCENT_OFFSET, -LIGHT0_DIRECTION) + 0.3;
	float crescent_power = 1.0 - clamp(crescent_distance / CRESCENT_SIZE, 0.0, 1.0);
	float crescent_disc = 1.0 - clamp(crescent_power / CRESCENT_BLUR, crescent_power, 1.0);
	vec3 moon = MOON_COLOUR * moon_disc * crescent_disc;
	
	// Add all sky gradients together
	vec3 sky_gradient = day_gradient + sunset_sky + night_gradient;
	
	// Clouds
	float cloud_movement = TIME * CLOUD_SPEED;
	float cloud_noise_1 = texture(CLOUD_TEX_1, (sky_uv + cloud_movement * 1.1) * CLOUD_SIZE).r;
	float cloud_noise_2 = texture(CLOUD_TEX_2, (sky_uv - cloud_movement) * CLOUD_SIZE).r;
	float cloud_noise_large = texture(CLOUD_TEX_LARGE, (sky_uv * 0.2) * CLOUD_SIZE).r;
	// Combine all noises
	vec3 cloud_colour = vec3(step(CLOUD1_CLIP, cloud_noise_1 + cloud_noise_2)) * CLOUD_COLOUR;
	cloud_colour += vec3(step(CLOUD2_CLIP, cloud_noise_1 + cloud_noise_2)) * CLOUD_COLOUR_2;
	
	vec3 cloud_smooth_colour = vec3(smoothstep(CLOUD1_CLIP, 0.1, cloud_noise_1 + cloud_noise_2)) * CLOUD_COLOUR;
	cloud_smooth_colour += vec3(smoothstep(CLOUD2_CLIP, 0.1, cloud_noise_1 + cloud_noise_2)) * CLOUD_COLOUR_2;
	// Make clouds more opaque at night
	float _cloud_opacity = mix(CLOUD_OPACITY, CLOUD_OPACITY - 0.2, night_amount);
	
	vec3 cloud_final_colour = mix(cloud_colour, cloud_smooth_colour, CLOUD_TYPE);
	cloud_final_colour = mix(vec3(0.0), cloud_final_colour, _cloud_opacity);
	cloud_final_colour *= vec3(smoothstep(CLOUD_CUTOFF_MAX, CLOUD_CUTOFF_MIN, pow(SKY_COORDS.y, CLOUD_CUTTOFF_EDGE)));
	
	// Stars ** Inspired by Gotibo - https://godotshaders.com/shader/stylized-sky/
	
	vec2 stars = voronoi(EYEDIR * 25.0).xz;
	vec3 star_colour = vec3(smoothstep(0.025 + ((1.0 + sin(TIME + stars.y)) / 2.0) * 0.05, 0.0, stars.x));
	star_colour = mix(star_colour, vec3(0.0), 1.0 - pow(night_amount, 4.0));
	
	
	// Add all elements of sky together
	vec3 sky_col = sky_gradient + cloud_final_colour + moon + horizon + sun + star_colour;
	
	COLOR = sky_col;
}
