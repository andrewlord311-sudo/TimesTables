shader_type spatial;
render_mode diffuse_toon;
// Woven-twig nest: bands of light and dark brown wrapping round the ring.
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	float a = atan(lp.z, lp.x);
	float band = sin(a * 46.0 + lp.y * 30.0) * 0.5 + 0.5;
	float band2 = sin(a * 23.0 - lp.y * 44.0 + 1.3) * 0.5 + 0.5;
	vec3 dark = vec3(0.36, 0.24, 0.13), light = vec3(0.66, 0.48, 0.28);
	ALBEDO = mix(dark, light, smoothstep(0.35, 0.65, band * 0.6 + band2 * 0.4));
	ROUGHNESS = 0.95;
}
