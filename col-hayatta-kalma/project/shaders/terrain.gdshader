// Desert terrain: world-projected PBR layers (Poly Haven, CC0) blended by biome weights
// stored in the vertex colour: r = rock, g = salt flat, b = oasis mud, a = dune shading.
// hq=false (Düşük) skips normal maps, triplanar rock and sparkle.
shader_type spatial;
render_mode cull_back;

uniform bool hq = true;
uniform float sparkle = 1.0;
uniform sampler2D sand_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_nrm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D sand2_alb : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_nrm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_arm : filter_linear_mipmap, repeat_enable;
uniform sampler2D salt_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D salt_nrm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D mud_alb : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D mud_nrm : hint_normal, filter_linear_mipmap, repeat_enable;

varying vec3 wpos;
varying vec3 wnrm;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

vec3 unpack(vec4 t) { vec3 n = t.xyz * 2.0 - 1.0; return n; }

// tangent-space normal sampled on the XZ plane -> world normal (whiteout blend)
vec3 top_n(vec2 tn, vec3 g) {
	return normalize(vec3(tn.x + g.x, g.y, tn.y + g.z));
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 uv = wpos.xz;
	float slope = 1.0 - wnrm.y;
	float rock = clamp(max(COLOR.r, smoothstep(0.32, 0.55, slope) * 0.85), 0.0, 1.0);
	float salt = COLOR.g * (1.0 - rock);
	float mud = COLOR.b * (1.0 - rock);
	float sand = max(0.0, 1.0 - rock - salt - mud);

	// --- sand: ripple texture + large-scale colour breakup
	vec2 suv = uv / 11.0;
	vec3 s_alb = texture(sand_alb, suv).rgb;
	float macro = texture(sand2_alb, uv / 53.0).r;
	s_alb *= vec3(1.18, 0.98, 0.74) * (0.82 + 0.4 * macro);
	vec3 alb = s_alb * sand;
	float rough = 0.93 * sand;
	vec3 n = wnrm;
	vec3 nsum = vec3(0.0);
	if (hq) nsum += unpack(texture(sand_nrm, suv)) * sand;

	if (rock > 0.01) {
		vec3 r_alb; vec3 rn = vec3(0.0); float r_r;
		if (hq) {
			vec3 bw = pow(abs(wnrm), vec3(4.0)); bw /= (bw.x + bw.y + bw.z);
			vec2 ux = wpos.zy / 4.5, uy = wpos.xz / 4.5, uz = wpos.xy / 4.5;
			r_alb = texture(rock_alb, ux).rgb * bw.x + texture(rock_alb, uy).rgb * bw.y + texture(rock_alb, uz).rgb * bw.z;
			r_r = texture(rock_arm, ux).g * bw.x + texture(rock_arm, uy).g * bw.y + texture(rock_arm, uz).g * bw.z;
			rn = unpack(texture(rock_nrm, uy)) * bw.y;
		} else {
			r_alb = texture(rock_alb, uv / 7.0).rgb; r_r = 0.85;
		}
		float rl = dot(r_alb, vec3(0.33));
		r_alb = mix(vec3(rl), r_alb, 0.55) * vec3(1.18, 0.95, 0.78);
		alb += r_alb * rock; rough += r_r * rock; nsum += rn * rock * 1.4;
	}
	if (salt > 0.01) {
		vec3 c = texture(salt_alb, uv / 6.0).rgb;
		float l = dot(c, vec3(0.33));
		vec3 sc = mix(vec3(l), c, 0.3) * 1.25 + vec3(0.1, 0.085, 0.06);
		alb += sc * salt; rough += 0.8 * salt;
		if (hq) nsum += unpack(texture(salt_nrm, uv / 6.0)) * salt * 0.8;
	}
	if (mud > 0.01) {
		vec3 c = texture(mud_alb, uv / 3.5).rgb * vec3(0.95, 0.92, 0.7);
		alb += c * mud; rough += 0.88 * mud;
		if (hq) nsum += unpack(texture(mud_nrm, uv / 3.5)) * mud;
	}
	if (hq) n = top_n(nsum.xy, wnrm);
	alb *= mix(0.86, 1.06, COLOR.a);
	ALBEDO = alb;
	ROUGHNESS = rough;
	SPECULAR = 0.35;
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	if (hq && sparkle > 0.0) {
		// tiny glints that twinkle as the camera moves
		vec2 cell = floor(wpos.xz * 28.0);
		float h = hash(cell + floor(CAMERA_POSITION_WORLD.xz * 1.7));
		float g = step(0.998, h) * sand * sparkle;
		EMISSION = vec3(1.0, 0.95, 0.82) * g * 1.6;
	}
}
