shader_type canvas_item;

uniform float time;
uniform vec4 base_color : source_color = vec4(1.0, 0.75, 0.2, 1.0);
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float shine_width = 0.2;
uniform float speed = 1.5;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // base gold
    vec3 color = base_color.rgb;

    // moving shine (diagonal sweep)
    float shine_pos = fract(UV.x + time * speed);

    float shine = smoothstep(0.0, shine_width, shine_pos)
                * (1.0 - smoothstep(shine_width, shine_width * 2.0, shine_pos));

    color = mix(color, shine_color.rgb, shine * 0.8);

    COLOR = vec4(color, tex.a * base_color.a);
}