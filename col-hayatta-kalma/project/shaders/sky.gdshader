// Procedural desert sky: gradient + sun disk/halo by day, stars + moon by night.
// At night the directional light is the moon, so LIGHT0 marks the moon's position.
shader_type sky;

uniform vec3 top_col : source_color = vec3(0.32, 0.55, 0.85);
uniform vec3 horizon_col : source_color = vec3(0.97, 0.85, 0.66);
uniform vec3 ground_col : source_color = vec3(0.85, 0.66, 0.42);
uniform float night = 0.0;
uniform float storm = 0.0;

float hash3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = d.y;
	vec3 col;
	if (h >= 0.0) {
		col = mix(horizon_col, top_col, pow(clamp(h, 0.0, 1.0), 0.5));
	} else {
		col = mix(horizon_col, ground_col, clamp(-h * 5.0, 0.0, 1.0));
	}
	vec3 ld = normalize(LIGHT0_DIRECTION);
	float sd = dot(d, ld);
	if (LIGHT0_ENABLED) {
		if (night < 0.5) {
			// sun disk + warm halo
			float disk = smoothstep(0.9991, 0.9996, sd);
			col += LIGHT0_COLOR * (pow(max(sd, 0.0), 10.0) * 0.28 + pow(max(sd, 0.0), 200.0) * 0.6) * (1.0 - storm);
			col = mix(col, vec3(1.0, 0.97, 0.88) * 3.5, disk * (1.0 - storm * 0.8));
		} else {
			// moon with faint maria and a soft glow
			float disk = smoothstep(0.99935, 0.99955, sd);
			vec3 mp = d - ld;
			float maria = hash3(floor(mp * 900.0)) * 0.15 + 0.85;
			col += vec3(0.55, 0.65, 0.9) * pow(max(sd, 0.0), 60.0) * 0.18;
			col = mix(col, vec3(0.92, 0.94, 1.0) * 1.6 * maria, disk * (1.0 - storm));
		}
	}
	if (night > 0.0 && h > 0.0) {
		vec3 cell = floor(d * 220.0);
		float r = hash3(cell);
		float star = step(0.9965, r) * (0.5 + 0.5 * sin(TIME * (1.0 + r * 4.0) + r * 60.0));
		float big = step(0.9993, r);
		col += vec3(0.9, 0.93, 1.0) * (star * 0.9 + big * 1.4) * night * smoothstep(0.0, 0.25, h) * (1.0 - storm);
		// milky band
		float band = exp(-pow(dot(d, normalize(vec3(0.3, 0.2, 1.0))) * 4.0, 2.0));
		col += vec3(0.12, 0.13, 0.2) * band * night * hash3(floor(d * 90.0)) * 0.6 * (1.0 - storm);
	}
	COLOR = col;
}
