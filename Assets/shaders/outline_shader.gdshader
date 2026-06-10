shader_type canvas_item;

// --- Uniforms ---
uniform float level = 1.0; 
uniform float outline_width : hint_range(0.0, 10.0) = 8.0;

// New Toggle and Charge uniforms
uniform bool use_charge_shader = false;
uniform float charge_progress : hint_range(0.0, 1.0) = 0.5;
uniform vec4 charge_color : source_color = vec4(0.0, 1.0, 0.0, 0.5);

// --- Level Color Logic ---
vec4 get_color_for_level(float lvl) {
    if (lvl <= 20.0) return mix(vec4(1.0, 1.0, 1.0, 1.0), vec4(1.0, 1.0, 0.0, 1.0), (lvl - 1.0) / 19.0);
    if (lvl <= 40.0) return mix(vec4(1.0, 1.0, 0.0, 1.0), vec4(0.0, 1.0, 0.0, 1.0), (lvl - 21.0) / 19.0);
    if (lvl <= 60.0) return mix(vec4(0.0, 1.0, 0.0, 1.0), vec4(0.0, 0.0, 1.0, 1.0), (lvl - 41.0) / 19.0);
    if (lvl <= 80.0) return mix(vec4(0.0, 0.0, 1.0, 1.0), vec4(0.5, 0.0, 0.5, 1.0), (lvl - 61.0) / 19.0);
    return mix(vec4(0.5, 0.0, 0.5, 1.0), vec4(1.0, 0.75, 0.8, 1.0), (lvl - 81.0) / 19.0);
}

void fragment() {
    vec4 current_color = texture(TEXTURE, UV);
    vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
    
    // --- Outline Calculation ---
    float max_alpha = 0.0;
    max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(size.x, 0.0)).a);
    max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(-size.x, 0.0)).a);
    max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(0.0, size.y)).a);
    max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(0.0, -size.y)).a);
    max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(size.x, size.y)).a);
    max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(-size.x, -size.y)).a);
    
    vec4 final_color = current_color;

    if (current_color.a < 0.5) {
        // Pixel is transparent, check for outline
        if (max_alpha > 0.5) {
            final_color = vec4(get_color_for_level(level).rgb, 1.0);
        }
    } else if (use_charge_shader) {
        float line_position = 1.0 - charge_progress;
        float line_thickness = 0.004; // Adjust this for a thicker or thinner line

        // Check if we are within the thickness range of the line
        if (abs(UV.y - line_position) < line_thickness) {
            // Draw the black line
            final_color = vec4(0.0, 0.0, 0.0, current_color.a);
        } else if (UV.y > line_position) {
            // Above the line
            final_color = current_color * 1.0;
        } else {
            // Below the line
            final_color = current_color * 0.5;
        }
    }
    
    COLOR = final_color;
}