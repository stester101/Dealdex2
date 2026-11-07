shader_type canvas_item;
// Battle intro wipe: diagonal bars sweep in. progress 0 -> 1.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float bars = 12.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float row = floor(uv.y * bars);
	float dir = mod(row, 2.0) < 1.0 ? uv.x : 1.0 - uv.x;
	float edge = progress * 1.4 - 0.2 * fract(row * 0.37);
	COLOR = vec4(0.06, 0.05, 0.1, dir < edge ? 1.0 : 0.0);
}
