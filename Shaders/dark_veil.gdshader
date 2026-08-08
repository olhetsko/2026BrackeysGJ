shader_type canvas_item;

// Churns the leading edge of the veil so it never reads as a straight line.

uniform float wisp_speed = 0.35;
uniform float wisp_strength = 0.06;
uniform float edge_softness = 0.35;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y);
}

void fragment() {
	// Drift the sample point over time so the darkness breathes.
	vec2 drift = vec2(TIME * wisp_speed * 0.2, TIME * wisp_speed);
	float n = noise(UV * vec2(4.0, 6.0) + drift);

	vec2 uv = UV + vec2((n - 0.5) * wisp_strength, 0.0);
	COLOR = texture(TEXTURE, uv);
	COLOR.a *= mix(1.0, n, edge_softness);
}
