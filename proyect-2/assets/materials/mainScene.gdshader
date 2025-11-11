shader_type canvas_item;

uniform float grain_strength : hint_range(0, 1) = 0.1;
uniform float grain_speed : hint_range(0, 5) = 0.1;
uniform float vignette_intensity : hint_range(0, 1) = 0.6; // 0 = nada, 1 = negro medio

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

float random(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // --- Grain animado ---
    vec2 seed = uv + vec2(TIME * grain_speed);
    float noise = random(seed) * 2.0 - 1.0;
    vec3 color = texture(SCREEN_TEXTURE, uv).rgb;
    color += noise * grain_strength;
    
    // --- Vignette en BORDES: de 0 (invisible) a 1 (negro medio) ---
    vec2 dist_to_edges = min(uv, vec2(1.0) - uv);
    float edge_dist = min(dist_to_edges.x, dist_to_edges.y);
    float vignette_factor = 1.0 - smoothstep(0.0, 0.15, edge_dist); // 1 en bordes, 0 en centro
    
    // Aplicar: 1.0 → sin oscurecer, 0.5 → negro medio
    float darken = mix(1.0, 0.5, vignette_factor * vignette_intensity);
    color *= darken;
    
    COLOR = vec4(color, 1.0);
}