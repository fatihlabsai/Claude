// Shared flame code (see flame.gdshader / flame_body.gdshader).
uniform float intensity = 1.0;
uniform float speed = 1.0;
uniform bool particle = false;
uniform float seed = 0.0;

varying float life;
varying float rnd;

float h21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), u.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
	return vnoise(p) * 0.55 + vnoise(p * 2.03 + 7.1) * 0.3 + vnoise(p * 4.1 + 3.3) * 0.15;
}

void vertex() {
	// spherical billboard that keeps the node's scale
	vec3 sc = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sc.x, INV_VIEW_MATRIX[1] * sc.y, INV_VIEW_MATRIX[2] * sc.z, MODEL_MATRIX[3]);
	life = particle ? INSTANCE_CUSTOM.y : 0.5;
	rnd = particle ? fract(MODEL_MATRIX[3].x * 3.7 + MODEL_MATRIX[3].z * 5.3) : seed;
}

void fragment() {
	vec2 uv = vec2(UV.x, 1.0 - UV.y);
	float t = TIME * speed + rnd * 13.0;
	float n = fbm(vec2(uv.x * 3.2 + rnd * 5.0, uv.y * 2.4 - t * 2.1));
	float n2 = fbm(vec2(uv.x * 6.0 - rnd * 3.0, uv.y * 4.0 - t * 3.3));
	float sway = (n - 0.5) * 0.35 * uv.y + sin(t * 1.3 + uv.y * 3.0) * 0.03 * uv.y;
	float x = abs(uv.x - 0.5 + sway);
	float w = mix(0.46, 0.04, pow(clamp(uv.y, 0.0, 1.0), 1.15));
	float body = smoothstep(w, w * 0.15, x);
	float top = 1.0 - smoothstep(0.25, 0.95, uv.y + (n2 - 0.5) * 0.45);
	float f = body * top * smoothstep(0.0, 0.1, uv.y);
	if (particle) f *= sin(clamp(life, 0.0, 1.0) * 3.14159) * 1.2;
	float heat = clamp(f * (1.05 - uv.y * 0.75), 0.0, 1.0);
	vec3 col = mix(vec3(0.45, 0.04, 0.0), vec3(1.0, 0.32, 0.02), smoothstep(0.05, 0.35, heat));
	col = mix(col, vec3(1.0, 0.68, 0.18), smoothstep(0.35, 0.7, heat));
	col = mix(col, vec3(1.0, 0.86, 0.55), smoothstep(0.8, 1.0, heat));
	ALBEDO = col * intensity * 0.95;
	ALPHA = clamp(f * 1.15, 0.0, 1.0);
}
