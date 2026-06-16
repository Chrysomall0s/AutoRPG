shader_type canvas_item;

// --- Uniforms ---
uniform float level = 0.0; 
uniform float outline_width : hint_range(0.0, 10.0) = 8.0;
uniform int index = 0; // 0 to 15 (4x4)

// New Toggle and Charge uniforms
uniform bool use_charge_shader = false;
uniform float charge_progress : hint_range(0.0, 1.0) = 1.0;
uniform vec4 charge_color : source_color = vec4(0.0, 1.0, 0.0, 0.5);

// --- New Level Color Logic ---
vec4 get_color_for_level(float lvl) {
    if (lvl >= 0.0)  return vec4(1.0, 1.0, 1.0, 1.0);       // White
    if (lvl >= -1.0) return vec4(1.0, 1.0, 0.0, 1.0);       // Yellow
    if (lvl >= -2.0) return vec4(0.0, 1.0, 0.0, 1.0);       // Green
    if (lvl >= -3.0) return vec4(0.0, 1.0, 1.0, 1.0);       // Cyan (Bright Blue)
    if (lvl >= -4.0) return vec4(0.5, 0.0, 1.0, 1.0);       // Violet
    return vec4(1.0, 0.4, 0.7, 1.0);                        // Pink (Bright)
}

void fragment() {
    // Calculate grid position (0-3) and create local UV
    vec2 cell_size = vec2(0.25, 0.25);
    vec2 offset = vec2(float(index % 4), float(index / 4)) * cell_size;
    vec2 local_uv = (UV - offset) / cell_size;
    
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
        if (max_alpha > 0.5) {
            final_color = vec4(get_color_for_level(level).rgb, 1.0);
        }
    } else if (use_charge_shader) {
        float line_position = 1.0 - charge_progress;
        float line_thickness = 0.01;

        if (abs(local_uv.y - line_position) < line_thickness) {
            final_color = vec4(0.0, 0.0, 0.0, current_color.a);
        } else if (local_uv.y > line_position) {
            final_color = current_color * 1.0;
        } else {
            final_color = current_color * 0.5;
        }
    }
    
    COLOR = final_color;
}