shader_type canvas_item;

// appearance
uniform vec4 color_a : source_color = vec4(0.95, 0.95, 0.95, 1.0);
uniform vec4 color_b : source_color = vec4(0.15, 0.15, 0.15, 1.0);

// tile size in pixels (square)
uniform float tile_size = 32.0;

// scrolling speed (tiles per second)
uniform vec2 speed = vec2(0.5, 0.0);

// anti-alias smoothing (0 = crisp)
uniform float smoothness = 1.0;

// deterministic offset / seed
uniform vec2 seed = vec2(0.0, 0.0);

void fragment() {
    vec2 uv_px = FRAGCOORD.xy;
    vec2 p = uv_px / max(tile_size, 0.0001);

    vec2 offset = TIME * speed + seed;
    vec2 q = p + offset;

    vec2 cell = floor(q);
    float checker = mod(cell.x + cell.y, 2.0);

    vec2 f = fract(q);
    float dx = min(f.x, 1.0 - f.x);
    float dy = min(f.y, 1.0 - f.y);
    float edge_dist = min(dx, dy);

    float aa = (abs(dFdx(q.x)) + abs(dFdy(q.y))) * 0.5 * smoothness;

    float soft = smoothstep(0.0, aa + 0.000001, edge_dist);

    float mix_val = (smoothness <= 0.0)
        ? checker
        : mix(checker, 1.0 - checker, 1.0 - soft);

    COLOR = mix(color_a, color_b, mix_val);
}