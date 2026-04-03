shader_type canvas_item;

uniform vec4 target_color1 : source_color;
uniform vec4 target_color2 : source_color;
uniform vec4 replace_color1 : source_color;
uniform vec4 replace_color2 : source_color;
uniform float tolerance : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec4 current_pixel = texture(TEXTURE, UV);
    
    // Calculate distance between current pixel and target color 1
    vec3 diff1 = abs(current_pixel.rgb - target_color1.rgb);
    float max_diff1 = max(diff1.r, max(diff1.g, diff1.b));

	// Calculate distance between current pixel and target color 2
    vec3 diff2 = abs(current_pixel.rgb - target_color2.rgb);
    float max_diff2 = max(diff2.r, max(diff2.g, diff2.b));
    
    // Swap color 1 if within tolerance
    if (max_diff1 < tolerance) {
        COLOR.rgb = replace_color1.rgb;
        COLOR.a = current_pixel.a; // Keep original alpha
    } else if (max_diff2 < tolerance) {
		COLOR.rgb = replace_color2.rgb;
        COLOR.a = current_pixel.a; // Keep original alpha
	} else {
        COLOR = current_pixel;
    }
	
}
