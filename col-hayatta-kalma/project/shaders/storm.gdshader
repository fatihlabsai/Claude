shader_type canvas_item;
// Full-screen sandstorm overlay: scrolling streaks + orange haze + vignette.
uniform float amount = 0.0;
uniform vec2 wind = vec2(1.0, 0.2);
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
void fragment() {
	vec2 uv = UV;
	vec2 p = uv * vec2(6.0, 3.0) - wind * TIME * 1.8;
	float n = noise(p) * 0.6 + noise(p * 2.7 + 3.1) * 0.3 + noise(p * 7.0 - TIME) * 0.1;
	float streak = smoothstep(0.55, 0.95, noise(vec2(uv.x * 2.0 - TIME * 3.2 * wind.x, uv.y * 40.0)));
	vec3 col = mix(vec3(0.86, 0.6, 0.32), vec3(0.98, 0.82, 0.55), n);
	float d = distance(uv, vec2(0.5));
	float a = amount * (0.55 + 0.35 * n + 0.25 * streak + d * 0.5);
	COLOR = vec4(col + streak * 0.08, clamp(a, 0.0, 0.93));
}
