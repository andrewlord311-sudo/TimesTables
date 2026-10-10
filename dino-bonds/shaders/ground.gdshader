shader_type spatial;
render_mode diffuse_toon, specular_disabled;
// Grassy ground with soft patches, and a warm earth clearing round the nest.
uniform vec3 grass_a : source_color = vec3(0.40, 0.66, 0.27);
uniform vec3 grass_b : source_color = vec3(0.55, 0.74, 0.30);
uniform vec3 earth : source_color = vec3(0.72, 0.58, 0.38);
varying vec3 wp;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n = noise(wp.xz * 0.18) * 0.6 + noise(wp.xz * 0.7) * 0.4;
	vec3 g = mix(grass_a, grass_b, smoothstep(0.3, 0.75, n));
	float r = length(wp.xz * vec2(0.62, 1.0)) + (noise(wp.xz * 1.3) - 0.5) * 0.9;
	float dirt = 1.0 - smoothstep(2.6, 3.6, r);
	ALBEDO = mix(g, earth * (0.9 + 0.2 * n), dirt);
	ROUGHNESS = 1.0;
}
