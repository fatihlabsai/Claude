// Soft vignette and hit/near-miss flash overlay.
shader_type canvas_item;

uniform float strength = 0.28;
uniform vec4 flash_col : source_color = vec4(1.0, 0.27, 0.27, 0.0);

void fragment() {
	vec2 uv = UV - 0.5;
	float v = smoothstep(0.35, 0.85, length(uv * vec2(1.0, 1.15)));
	vec4 c = vec4(0.04, 0.10, 0.20, v * strength);
	c = mix(c, vec4(flash_col.rgb, 1.0), flash_col.a);
	COLOR = c;
}
