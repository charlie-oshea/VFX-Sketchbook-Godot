// Optimized and Customizable Kuwahara Filter Shader for Godot 4
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform int radius : hint_range(2, 16, 2) = 4;
uniform float subsample_amount : hint_range(1.0, 16.0, 1.0) = 4.0;
uniform float edge_sensitivity : hint_range(0.0, 1.0) = 0.5;
uniform float smoothing_strength : hint_range(0.0, 1.0) = 0.5;

vec3 get_mean_color(sampler2D texture, vec2 uv, int region_radius) {
    vec4 mean = vec4(0.0);
    float count = 0.0;
    float step = 1.0 / subsample_amount;

    for (float x = float(-region_radius); x <= float(region_radius); x += step) {
        for (float y = float(-region_radius); y <= float(region_radius); y += step) {
            vec2 offset = vec2(x, y) / vec2(800.0, 600.0);
            mean += texture(texture, uv + offset);
            count += 1.0;
        }
    }

    return mean.rgb / count;
}

vec3 get_mean_square_color(sampler2D texture, vec2 uv, int region_radius) {
    vec4 meanSquare = vec4(0.0);
    float count = 0.0;
    float step = 1.0 / subsample_amount;

    for (float x = -float(region_radius); x <= float(region_radius); x += step) {
        for (float y = -float(region_radius); y <= float(region_radius); y += step) {
            vec2 offset = vec2(x, y) / vec2(800.0, 600.0);
            vec3 color = texture(texture, uv + offset).rgb;
            meanSquare += vec4(color * color, 1.0);
            count += 1.0;
        }
    }

    return sqrt(meanSquare.rgb / count);
}

vec3 kuwahara_filter(sampler2D texture, vec2 uv, int filter_radius) {
    vec3 meanColor = get_mean_color(texture, uv, filter_radius);
    vec3 meanSquareColor = get_mean_square_color(texture, uv, filter_radius);

    float minMeanDiff = 1e20;
    vec3 result = vec3(0.0);
    float step = 1.0 / subsample_amount;

    for (float x = -float(filter_radius); x <= float(filter_radius); x += step) {
        for (float y = -float(filter_radius); y <= float(filter_radius); y += step) {
            vec2 offset = vec2(x, y) / vec2(800.0, 600.0);
            vec3 color = texture(texture, uv + offset).rgb;
            vec3 mean = get_mean_color(texture, uv + offset, filter_radius);
            vec3 meanSquare = get_mean_square_color(texture, uv + offset, filter_radius);

            float meanDiff = length(meanSquare - mean * mean);
            float edgeDiff = length(color - mean);
            meanDiff = mix(meanDiff, edgeDiff, edge_sensitivity);

            if (meanDiff < minMeanDiff) {
                minMeanDiff = meanDiff;
                result = mean;
            }
        }
    }

    return mix(meanColor, result, smoothing_strength);
}

void fragment() {
    vec2 uv = UV;
    vec3 color = kuwahara_filter(screen_texture, uv, radius);
    COLOR = vec4(color, 1.0);
}