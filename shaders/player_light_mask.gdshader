shader_type canvas_item;
render_mode unshaded;

uniform vec2 light_pos = vec2(0.5, 0.5);
uniform float radius = 0.18;
uniform float softness = 0.22;
uniform float darkness = 0.90;

void fragment() {
    vec2 p = SCREEN_UV - light_pos;

    float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
    p.x *= aspect;

    float d = length(p);
    float mask = smoothstep(radius, radius + softness, d);

    COLOR = vec4(0.0, 0.0, 0.0, darkness * mask);
}
