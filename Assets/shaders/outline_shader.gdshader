shader_type canvas_item;

uniform float level = 1.0; 
uniform float outline_width : hint_range(0.0, 10.0) = 8.0;

vec4 get_color_for_level(float lvl) {
    if (lvl <= 2.0) return mix(vec4(1.0, 1.0, 1.0, 1.0), vec4(1.0, 1.0, 0.0, 1.0), (lvl - 1.0) / 19.0);
    if (lvl <= 4.0) return mix(vec4(1.0, 1.0, 0.0, 1.0), vec4(0.0, 1.0, 0.0, 1.0), (lvl - 21.0) / 19.0);
    if (lvl <= 6.0) return mix(vec4(0.0, 1.0, 0.0, 1.0), vec4(0.0, 0.0, 1.0, 1.0), (lvl - 41.0) / 19.0);
    if (lvl <= 8.0) return mix(vec4(0.0, 0.0, 1.0, 1.0), vec4(0.5, 0.0, 0.5, 1.0), (lvl - 61.0) / 19.0);
    return mix(vec4(0.5, 0.0, 0.5, 1.0), vec4(1.0, 0.75, 0.8, 1.0), (lvl - 81.0) / 19.0);
}

void fragment() {
    vec4 current_color = texture(TEXTURE, UV);
    vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
    
    // Check a larger surrounding area to ensure no gaps
    float max_alpha = 0.0;
    max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(size.x, 0.0)).a);
    max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(-size.x, 0.0)).a);
    max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(0.0, size.y)).a);
    max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(0.0, -size.y)).a);
    // Include diagonals for a "thicker" filled look
    max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(size.x, size.y)).a);
    max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(-size.x, -size.y)).a);
    
    // Mix the outline color: if the sprite is transparent but a neighbor isn't
    if (current_color.a < 0.5) {
        if (max_alpha > 0.5) {
            vec4 outline = get_color_for_level(level);
            COLOR = vec4(outline.rgb, 1.0); // Full opacity for the outline
        } else {
            COLOR = vec4(0.0, 0.0, 0.0, 0.0);
        }
    } else {
        COLOR = current_color;
    }
}