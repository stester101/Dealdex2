shader_type canvas_item;
// Animated pixel water: drifting light bands, dark troughs and twinkling sparkles.
uniform float speed = 1.0;
uniform vec3 shine = vec3(0.78, 0.9, 1.0);
varying vec2 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 c = COLOR;
	vec2 p = floor(wpos);
	float t = TIME * speed;
	float w1 = sin(p.x * 0.19 + t * 1.3 + sin(p.y * 0.31 + t * 0.4) * 2.2);
	float w2 = sin(p.y * 0.47 - t * 0.9 + p.x * 0.05);
	float band = w1 * 0.6 + w2 * 0.4;
	if (band > 0.86) {
		c.rgb = mix(c.rgb, shine, 0.42);
	} else if (band > 0.74) {
		c.rgb = mix(c.rgb, shine, 0.18);
	} else if (band < -0.88) {
		c.rgb *= 0.84;
	}
	float h = hash(floor(p / 2.0));
	if (h > 0.994 && fract(t * 0.6 + h * 37.0) > 0.82) {
		c.rgb = vec3(1.0);
	}
	COLOR = c;
}
