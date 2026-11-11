shader_type spatial;
render_mode cull_back, specular_schlick_ggx;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(TIME * 1.3 + wpos.x * 0.6) * 0.03 + cos(TIME * 1.1 + wpos.z * 0.5) * 0.03;
}
void fragment() {
	float w = sin(wpos.x * 1.3 + TIME * 1.6) * 0.5 + sin(wpos.z * 1.7 - TIME * 1.2) * 0.5;
	float ring = smoothstep(0.75, 1.0, w);
	vec3 deep = vec3(0.01, 0.12, 0.2);
	vec3 shallow = vec3(0.05, 0.35, 0.4);
	ALBEDO = mix(deep, shallow, 0.35 + 0.25 * w) + ring * 0.12;
	ROUGHNESS = 0.35;
	METALLIC = 0.0;
	SPECULAR = 0.25;
}
