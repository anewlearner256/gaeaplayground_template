shader_type spatial;
render_mode cull_disabled;
uniform float factor;
void vertex(){
}
void fragment(){
	float fresnel  = 1.0 - dot(NORMAL, VIEW);
	ALBEDO = vec3(0.1, 0.3, 0.5) * pow(fresnel, factor);
	ALPHA = pow(fresnel, factor);
	EMISSION = vec3(1, 1, 1) * pow(fresnel, factor);
}