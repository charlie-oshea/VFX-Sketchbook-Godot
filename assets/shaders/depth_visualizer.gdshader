shader_type spatial;

render_mode unshaded;

uniform float zNear = 0.05;
uniform float zFar = 100.0;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	vec4 original = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	// Get depth value from hint_depth_texture
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	
	// Use to create Normalized Device Coordinates (sort of clip space)
	// Godot requires NDC to be -1 to 1
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	
	// Convert between NDC and viewspace to get distance to camera
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	
	float linear_depth = view.z;
	float scaled_depth = (zFar * zNear) / (zFar + (linear_depth * (zNear - zFar)));
	scaled_depth = clamp(scaled_depth, 0, 1);
	
	// Fog colour
	vec3 gray = vec3(0.2);
	
	//ALBEDO = vec3(scaled_depth);
	ALBEDO = mix(gray, original.rgb, scaled_depth);
}
