shader_type canvas_item;
// Status vignette: red pulse (low health), white heat haze, blue cold edge, blur-ish thirst darkening.
uniform float hurt = 0.0;
uniform float heat = 0.0;
uniform float cold = 0.0;
uniform float thirst = 0.0;
uniform float night = 0.0;
void fragment() {
	float d = distance(UV, vec2(0.5)) * 1.4;
	float edge = smoothstep(0.45, 1.05, d);
	vec3 c = vec3(0.0);
	float a = 0.0;
	a += edge * night * 0.45;
	c = mix(c, vec3(0.75, 0.05, 0.05), clamp(hurt, 0.0, 1.0));
	a += edge * hurt * (0.55 + 0.25 * sin(TIME * 5.0));
	c = mix(c, vec3(1.0, 0.85, 0.5), heat * 0.6);
	a += edge * heat * 0.35;
	c = mix(c, vec3(0.55, 0.75, 1.0), cold * 0.7);
	a += edge * cold * 0.45;
	a += smoothstep(0.25, 1.0, d) * thirst * 0.4;
	COLOR = vec4(c, clamp(a, 0.0, 0.9));
}
