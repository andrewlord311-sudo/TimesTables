shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_disabled;
// Leaves, grass and flowers from the nature kit, swaying gently in the wind.
uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 tint : source_color = vec4(1.0);
uniform float sway = 0.1;
void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = max(VERTEX.y, 0.0);
	float s = sin(TIME * 1.7 + wp.x * 0.55 + wp.z * 0.35) * sway * h;
	s += sin(TIME * 3.1 + wp.x * 1.7) * sway * 0.25 * h;
	VERTEX.x += s;
	VERTEX.z += s * 0.6;
}
void fragment() {
	vec4 c = texture(tex, UV) * tint;
	if (c.a < 0.45) discard;
	ALBEDO = c.rgb * 1.08;
	ROUGHNESS = 0.9;
}
