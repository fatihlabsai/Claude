// Sky gradient with sun glow and drifting clouds over the northern horizon.
shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;
uniform float phase = 0.2;
uniform float top_y = -760.0;
uniform float horizon_y = -40.0;
uniform vec2 sun_pos = vec2(1020.0, -205.0);

varying vec2 wp;

void vertex() {
	wp = VERTEX;
}

void fragment() {
	float v = clamp((wp.y - top_y) / (horizon_y - top_y), 0.0, 1.0);
	vec3 top_c = mix(vec3(0.27, 0.58, 0.90), vec3(0.30, 0.33, 0.62), phase);
	vec3 hor_c = mix(vec3(0.80, 0.92, 0.99), vec3(1.00, 0.72, 0.48), phase);
	vec3 col = mix(top_c, hor_c, pow(v, 1.7));
	vec2 sp = sun_pos + vec2(0.0, phase * 70.0);
	float d = length(wp - sp);
	vec3 sun_c = mix(vec3(1.0, 0.95, 0.75), vec3(1.0, 0.62, 0.35), phase);
	col += sun_c * (smoothstep(30.0, 26.0, d) * 0.9 + exp(-d / 110.0) * (0.25 + phase * 0.45));
	vec2 uv = wp / vec2(1100.0, 300.0) + vec2(TIME * 0.004, 0.0);
	float n = texture(noise_tex, uv).r * 0.65 + texture(noise_tex, uv * 2.3 + vec2(TIME * 0.006, 0.0)).r * 0.35;
	float cl = smoothstep(0.52, 0.72, n) * (1.0 - v * 0.7);
	vec3 cloud = mix(vec3(1.0), vec3(1.0, 0.84, 0.76), phase);
	col = mix(col, cloud, cl * 0.8);
	COLOR = vec4(col, 1.0);
}
