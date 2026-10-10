shader_type spatial;
render_mode diffuse_toon, specular_toon;
// Cream dinosaur egg with soft speckles.
varying vec3 lp;
float hash(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
void vertex() { lp = VERTEX; }
void fragment() {
	vec3 cell = floor(lp * 22.0);
	float spot = step(0.86, hash(cell));
	vec3 base = vec3(0.98, 0.93, 0.80);
	ALBEDO = mix(base, vec3(0.62, 0.48, 0.32), spot * 0.7);
	ROUGHNESS = 0.45;
	RIM = 0.4;
	RIM_TINT = 0.5;
}
