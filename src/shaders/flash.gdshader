shader_type canvas_item;
// Used on strain sprites: white flash on hit, tint for status, fade-to-white when caught.
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform float cut_y : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 c = COLOR;
	if (UV.y > cut_y) {
		c.a = 0.0;
	}
	c.rgb = mix(c.rgb, tint.rgb, tint.a);
	c.rgb = mix(c.rgb, vec3(1.0), flash);
	COLOR = c;
}
