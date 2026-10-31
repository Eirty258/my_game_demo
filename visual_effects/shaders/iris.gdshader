shader_type canvas_item;

uniform float progress : hint_range(-0.1, 1.5) = 0.1;
uniform vec2 center = vec2(0.5, 0.5);
uniform float egg_ratio = 1.0;
uniform float softness : hint_range(0.0, 0.1) = 0.02;
uniform float sharpness : hint_range(0.0, 0.4) = 0.12;

void fragment() {
    vec2 uv = UV - center;

    // 按 ColorRect 宽高比修正，让距离和角度在屏幕上等距
    vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
    float aspect = screen_size.x / screen_size.y;
    uv.x *= aspect;

    // 上下拉长
    uv.y /= egg_ratio;

    // atan(y,x) 0度朝右，减去PI/2，把0度转到朝上
    float theta = atan(uv.y, uv.x) - PI * 0.5;
    float egg_r = 1.0 + sharpness * (-pow(cos(theta), 3.0));

    float dist = length(uv);
    float radius = progress * 1.5 - 0.05;

    float mask = smoothstep(radius * egg_r, radius * egg_r + softness, dist);
    COLOR = vec4(0.0, 0.0, 0.0, mask);
}