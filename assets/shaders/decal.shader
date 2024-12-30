shader_type spatial;
render_mode world_vertex_coords, unshaded, depth_test_disable, cull_disabled;

uniform vec4 albedo : hint_color = vec4(0.0);
uniform sampler2D texture_albedo : hint_albedo;

uniform float cube_half_size = 0.5;

uniform float min_height;//高度范围
uniform float max_height;
uniform vec3 invalid_color;
uniform vec2 wn; //底面四个顶点，顺时针
uniform vec2 en;
uniform vec2 es;
uniform vec2 ws;



vec2 ToUnit(vec2 v0, vec2 v1, vec2 v2, vec2 v3, float x, float y)
{
	float c = v0.x;
	float f = v0.y;
	float g = ((v0.x - v1.x + v2.x - v3.x) * (v3.y - v2.y) - (v0.y - v1.y + v2.y - v3.y) * (v3.x - v2.x)) /
		((v1.x - v2.x) * (v3.y - v2.y) - (v1.y - v2.y) * (v3.x - v2.x));
	float h = ((v0.x - v1.x + v2.x - v3.x) * (v1.y - v2.y) - (v0.y - v1.y + v2.y - v3.y) * (v1.x - v2.x)) /
		((v3.x - v2.x) * (v1.y - v2.y) - (v3.y - v2.y) * (v1.x - v2.x));
	float a = v1.x - v0.x + g * v1.x;
	float d = v1.y - v0.y + g * v1.y;
	float b = v3.x - v0.x + h * v3.x;
	float e = v3.y - v0.y + h * v3.y;
	float u = ((b - h*x)*(f - y) - (c - x)*(e - h*y))/((a - g*x)*(e - h*y) - (b - h*x)*(d - g*y));
	float v = (-(a - g*x)*(f - y) + (c - x)*(d - g*y))/((a - g*x)*(e - h*y) - (b - h*x)*(d - g*y));
	return vec2(u, v);
}
// Credit: https://stackoverflow.com/questions/32227283/getting-world-position-from-depth-buffer-value
vec3 world_pos_from_depth(float depth, vec2 screen_uv, mat4 inverse_proj, mat4 inverse_view) {
	float z = depth * 2.0 - 1.0;
	
	vec4 clipSpacePosition = vec4(screen_uv * 2.0 - 1.0, z, 1.0);
	vec4 viewSpacePosition = inverse_proj * clipSpacePosition;
	
	viewSpacePosition /= viewSpacePosition.w;
	
	vec4 worldSpacePosition = inverse_view * viewSpacePosition;
	
	return worldSpacePosition.xyz;
}

void fragment() {
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 world_pos = world_pos_from_depth(depth, SCREEN_UV, INV_PROJECTION_MATRIX, (CAMERA_MATRIX));
	vec4 test_pos = (inverse(WORLD_MATRIX) * vec4(world_pos, 1.0));
	
//	if (abs(test_pos.x) > cube_half_size ||abs(test_pos.y) > cube_half_size || abs(test_pos.z) > cube_half_size) {
//		discard;
//	}
	vec2 uv = ToUnit(wn, en, es, ws, test_pos.x, test_pos.z);
	if(abs(test_pos.y) >= max_height || abs(test_pos.y) <= min_height || 
	uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
	{
		discard;
	}
//	else
//	{
//		ALBEDO = vec3(1, 0, 0);
//	}
//	if(uv.x > 0.0 && uv.x < 0.1)
//	{
//		ALBEDO = vec3(1, 0, 0);
//	}
	vec4 color = texture(texture_albedo, uv) ;
	if(color.xyz == invalid_color)
	{
		discard;
	}
	else
	{
		ALBEDO = color.xyz;
	}
	ALPHA = color.a;
	
}
