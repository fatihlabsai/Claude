// Animated Bosphorus water: depth tint, flowing waves, glints and shore foam.
// Original shader written for Boğaz Vapuru.
shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;
uniform vec2 eu_pts[16];
uniform vec2 as_pts[16];
uniform float phase = 0.2;
uniform vec2 cur_vec = vec2(0.0, 10.0);

varying vec2 wp;

void vertex() {
	wp = VERTEX;
}

float shore_eu(float y) {
	if (y <= eu_pts[0].x) return eu_pts[0].y;
	for (int i = 1; i < 16; i++) {
		if (y <= eu_pts[i].x) {
			vec2 a = eu_pts[i - 1];
			vec2 b = eu_pts[i];
			float t = (y - a.x) / (b.x - a.x);
			float s = (1.0 - cos(3.14159265 * t)) * 0.5;
			return a.y + (b.y - a.y) * s;
		}
	}
	return eu_pts[15].y;
}

float shore_as(float y) {
	if (y <= as_pts[0].x) return as_pts[0].y;
	for (int i = 1; i < 16; i++) {
		if (y <= as_pts[i].x) {
			vec2 a = as_pts[i - 1];
			vec2 b = as_pts[i];
			float t = (y - a.x) / (b.x - a.x);
			float s = (1.0 - cos(3.14159265 * t)) * 0.5;
			return a.y + (b.y - a.y) * s;
		}
	}
	return as_pts[15].y;
}

void fragment() {
	float e = shore_eu(wp.y) + 4.0 * sin(wp.y * 0.021);
	float a = shore_as(wp.y) + 4.0 * sin(wp.y * 0.019 + 1.3);
	float d = min(wp.x - e, a - wp.x);
	float depth = smoothstep(0.0, 260.0, d);

	vec3 shallow = vec3(0.33, 0.78, 0.88);
	vec3 deep = vec3(0.09, 0.43, 0.70);
	vec3 col = mix(shallow, deep, depth);

	vec2 flow = cur_vec * TIME * 0.0011;
	vec2 uv1 = wp / 420.0 - flow * 0.5 + vec2(TIME * 0.010, TIME * 0.004);
	vec2 uv2 = wp / 190.0 - flow + vec2(-TIME * 0.012, TIME * 0.008);
	float n1 = texture(noise_tex, uv1).r;
	float n2 = texture(noise_tex, uv2).r;
	float w = n1 * 0.6 + n2 * 0.4;
	col += (w - 0.5) * 0.10;

	// rolling wave crests
	float ridge = 1.0 - abs(n2 * 2.0 - 1.0);
	ridge = pow(ridge, 10.0);
	float ridge2 = pow(1.0 - abs(texture(noise_tex, wp / 95.0 - flow * 1.4 + vec2(TIME * 0.02, -TIME * 0.015)).r * 2.0 - 1.0), 14.0);
	col += vec3(0.85, 0.96, 1.0) * (ridge * 0.12 + ridge2 * 0.07) * (0.4 + depth * 0.6);

	// sun glints
	float g1 = texture(noise_tex, wp / 55.0 + vec2(TIME * 0.05, -TIME * 0.03)).r;
	float g2 = texture(noise_tex, wp / 41.0 - vec2(TIME * 0.04, TIME * 0.05)).r;
	float glint = smoothstep(0.90, 0.95, g1 * g2 * 1.55);
	col += mix(vec3(1.0, 0.98, 0.9), vec3(1.0, 0.8, 0.55), phase) * glint * 0.5;

	// shore foam: a breaking band plus a second wave rolling in
	float fn = texture(noise_tex, wp / 38.0 + vec2(0.0, TIME * 0.05)).r;
	float band = 9.0 + 4.0 * sin(TIME * 1.6 + wp.y * 0.05);
	float foam = smoothstep(band, band - 5.0, d + (fn - 0.5) * 10.0);
	float roll = 20.0 + 7.0 * sin(TIME * 1.1 + wp.y * 0.031);
	float foam2 = smoothstep(2.5, 0.0, abs(d - roll + (fn - 0.5) * 8.0)) * smoothstep(0.35, 0.6, fn);
	col = mix(col, vec3(0.97, 0.99, 1.0), clamp(foam * 0.9 + foam2 * 0.55, 0.0, 1.0));

	// golden-hour tint
	col = mix(col, col * vec3(1.06, 0.86, 0.82) + vec3(0.07, 0.03, 0.0), phase * 0.7);
	COLOR = vec4(col, 1.0);
}
