// Oasis water: animated ripples, fresnel sky reflection faked with a uniform colour
// (no reflection probes / radiance maps -> cheap on WebGL), sun glints from the light.
shader_type spatial;
render_mode cull_back, specular_schlick_ggx;
uniform vec3 sky_col : source_color = vec3(0.6, 0.75, 0.9);
uniform float day = 1.0;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(TIME * 1.3 + wpos.x * 0.6) * 0.03 + cos(TIME * 1.1 + wpos.z * 0.5) * 0.03;
}
void fragment() {
	float w = sin(wpos.x * 1.3 + TIME * 1.6) * 0.5 + sin(wpos.z * 1.7 - TIME * 1.2) * 0.5;
	float w2 = sin(wpos.x * 3.1 - wpos.z * 2.3 + TIME * 2.4) * 0.5 + 0.5;
	vec3 deep = vec3(0.01, 0.09, 0.14);
	vec3 shallow = vec3(0.04, 0.27, 0.3);
	vec3 n = normalize(vec3(cos(wpos.x * 1.3 + TIME * 1.6) * 0.06 + (w2 - 0.5) * 0.05, 1.0, cos(wpos.z * 1.7 - TIME * 1.2) * 0.06));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	ALBEDO = mix(deep, shallow, 0.35 + 0.25 * w) * mix(0.35, 1.0, day);
	EMISSION = sky_col * fres * 0.6 * mix(0.25, 1.0, day);
	ROUGHNESS = 0.12;
	METALLIC = 0.0;
	SPECULAR = 0.5;
}
