shader_type spatial;
render_mode diffuse_toon, specular_toon, cull_disabled;
// A cartoon river: deep middle, shallow edges with foam, ripples flowing downstream.
uniform vec3 deep : source_color = vec3(0.16, 0.55, 0.80);
uniform vec3 shallow : source_color = vec3(0.38, 0.80, 0.90);
varying vec3 wp;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(wp.z * 1.3 + TIME * 2.0) * 0.02;
}
void fragment() {
	float edge = abs(UV.x - 0.5) * 2.0;
	vec3 col = mix(deep, shallow, smoothstep(0.35, 0.95, edge));
	float rip = noise(vec2(wp.x * 1.4, wp.z * 0.5 - TIME * 0.9)) * noise(vec2(wp.x * 2.3 + 4.0, wp.z * 0.9 - TIME * 1.4));
	col += vec3(0.9) * smoothstep(0.42, 0.55, rip) * 0.45;
	float foam = smoothstep(0.86, 0.97, edge + (noise(wp.xz * 3.0 + TIME) - 0.5) * 0.08);
	col = mix(col, vec3(0.96, 0.99, 1.0), foam);
	ALBEDO = col;
	ROUGHNESS = 0.15;
	SPECULAR = 0.6;
}
