shader_type spatial;
render_mode cull_back;
uniform float storm = 0.0;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float r1 = sin(wpos.x * 1.6 + wpos.z * 0.8 + sin(wpos.z * 0.27 + wpos.x * 0.11) * 2.2);
	float r2 = sin(wpos.x * 0.45 - wpos.z * 0.6);
	float grain = fract(sin(dot(floor(wpos.xz * 6.0), vec2(12.9898, 78.233))) * 43758.5453);
	vec3 lin = mix(COLOR.rgb / 12.92, pow((COLOR.rgb + 0.055) / 1.055, vec3(2.4)), step(0.04045, COLOR.rgb));
	vec3 c = lin * (0.95 + 0.035 * r1 + 0.02 * r2 + 0.03 * (grain - 0.5));
	ALBEDO = c;
	ROUGHNESS = 0.92;
	SPECULAR = 0.15;
}
