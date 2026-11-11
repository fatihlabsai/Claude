// Screen-space heat shimmer (Orta/Yüksek only), strongest toward the top of the screen (distance).
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amount = 0.0;
void fragment() {
	vec2 uv = SCREEN_UV;
	float w = amount * (0.35 + 0.65 * (1.0 - uv.y));
	vec2 o = vec2(sin(uv.y * 90.0 + TIME * 3.1) + sin(uv.y * 37.0 - TIME * 1.7 + uv.x * 13.0),
			cos(uv.x * 70.0 + TIME * 2.3)) * 0.0011 * w;
	COLOR = vec4(texture(screen_tex, uv + o).rgb, 1.0);
}
