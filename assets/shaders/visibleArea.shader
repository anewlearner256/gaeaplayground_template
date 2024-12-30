shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disable, depth_draw_never;
uniform float far;
uniform float near;
uniform float fov;
uniform float base_bais = 0.003;
uniform mat4 eye_transform;
uniform mat4 to_local;
uniform sampler2D depth_texture:hint_white;
uniform float mat11;
uniform float mat22;
uniform float mat33;
uniform float mat34;

vec3 world_pos_from_depth(float depth, vec2 screen_uv, mat4 inverse_proj, mat4 inverse_view) {
	float z = depth * 2.0 - 1.0;
	
	vec4 clipSpacePosition = vec4(screen_uv * 2.0 - 1.0, z, 1.0);
	vec4 viewSpacePosition = inverse_proj * clipSpacePosition;
	
	viewSpacePosition /= viewSpacePosition.w;
	
	vec4 worldSpacePosition = inverse_view * viewSpacePosition;
	
	return worldSpacePosition.xyz;
}
vec3 view_pos_from_depth(sampler2D depth_tex, vec2 screen_uv, mat4 inverse_proj, mat4 inverse_view) {
	float depth = texture(depth_tex, screen_uv).x;
	float z = depth * 2.0 - 1.0;
	
	vec4 clipSpacePosition = vec4(screen_uv * 2.0 - 1.0, z, 1.0);
	vec4 viewSpacePosition = inverse_proj * clipSpacePosition;
	
	viewSpacePosition /= viewSpacePosition.w;	
	return viewSpacePosition.xyz;
}
mat4 get_projection_matrix()
{

	mat4 projection_matrix = mat4(
		vec4(mat11, 0, 0, 0),
		vec4(0, mat22, 0, 0),
		vec4(0, 0, mat33, -1),
		vec4(0, 0, mat34, 0)
	);
	return projection_matrix;
}
vec3 tonemap_aces(vec3 color, float white) {
	const float exposure_bias = 0.85f;
	const float A = 2.51f * exposure_bias * exposure_bias;
	const float B = 0.03f * exposure_bias;
	const float C = 2.43f * exposure_bias * exposure_bias;
	const float D = 0.59f * exposure_bias;
	const float E = 0.14f;

	vec3 color_tonemapped = (color * (A * color + B)) / (color * (C * color + D) + E);
	float white_tonemapped = (white * (A * white + B)) / (white * (C * white + D) + E);

	return clamp(color_tonemapped / white_tonemapped, vec3(0.0f), vec3(1.0f));
}
void vertex() {
//  POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc0 = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	vec4 viewSpacePosition = INV_PROJECTION_MATRIX * vec4(ndc0, 1.0);
	viewSpacePosition /= viewSpacePosition.w;
	vec4 worldSpacePosition = CAMERA_MATRIX * viewSpacePosition;
//	vec3 world_pos = world_pos_from_depth(depth, SCREEN_UV, INV_PROJECTION_MATRIX, (CAMERA_MATRIX));
//	if(length(test_pos.xyz) > 100.0)
//	{
//		discard;
//	}
//	vec4 view_pos = inverse(WORLD_MATRIX) * vec4(worldSpacePosition.xyz, 1.0);
	vec4 view_pos = to_local * vec4(viewSpacePosition.xyz, 1.0);

	
	vec3 P  = viewSpacePosition.xyz;
	float xOffset = 1.0;
	float yOffset = 1.0;
	vec3 Pl = view_pos_from_depth(DEPTH_TEXTURE, SCREEN_UV + vec2(-xOffset, 0.0) / VIEWPORT_SIZE, INV_PROJECTION_MATRIX, CAMERA_MATRIX);
	vec3 Pr = view_pos_from_depth(DEPTH_TEXTURE, SCREEN_UV + vec2(xOffset, 0.0) / VIEWPORT_SIZE, INV_PROJECTION_MATRIX, CAMERA_MATRIX);
	vec3 Pu = view_pos_from_depth(DEPTH_TEXTURE, SCREEN_UV + vec2(0.0, -yOffset) / VIEWPORT_SIZE, INV_PROJECTION_MATRIX, CAMERA_MATRIX);
	vec3 Pd = view_pos_from_depth(DEPTH_TEXTURE, SCREEN_UV + vec2(0.0, yOffset) / VIEWPORT_SIZE, INV_PROJECTION_MATRIX, CAMERA_MATRIX);
	vec3 leftDir = min(P - Pl, Pr - P);//求出最小的变换量
    vec3 upDir   = min(P - Pd, Pu - P);//求出最小的变换量
    vec3 normal = -normalize(cross(leftDir,upDir));
	normal = (to_local * vec4(normal, 0.0)).xyz;
//	normal = (CAMERA_MATRIX * vec4(normal, 0.0)).xyz;
//	normal = (inverse(WORLD_MATRIX) * vec4(normal.xyz, 0.0)).xyz;
		
//	float dis = length(view_pos) / 100.0;
//	float dis = -view_pos.z / far;
	float dis = log2(-view_pos.z + 1.0) / log2(far + 1.0);
//	float dis = length(world_pos - eye_pos) / far;
//	if(length(test_pos.xyz) < 50.0)
//	{
//		discard;
//	}
	vec4 project_pos = get_projection_matrix() * view_pos;

	vec3 ndc = project_pos.xyz / project_pos.w;
//	if(ndc_x > 1.0 || ndc_x < -1.0 || ndc_y > 1.0 || ndc_y < -1.0 || length(view_pos) > 100.0)
	ndc = (ndc + 1.0) / 2.0;
//	float view_depth = texture(depth_texture, vec2(ndc_x, 1.0 - ndc_y)).x;
	vec3 color = texture(depth_texture, vec2(SCREEN_UV.x, 1.0 - SCREEN_UV.y)).xyz;
	float view_depth = texture(depth_texture, vec2(ndc.x, 1.0 - ndc.y)).x;
//	float view_depth = texture(depth_texture, vec2(SCREEN_UV.x, 1.0 - SCREEN_UV.y)).x;
//	if(view_depth <= 0.5)
//	if(dis <= 0.5)
//	float bias = base_bais;
    float dota = dot(normal, normalize(view_pos.xyz));
	float bias = max(base_bais * (1.0 - dota), base_bais * 0.4);
	if(dis - bias < view_depth)
	{
		if(dota <= 0.0)
		{
			ALBEDO = vec3(0, 1, 0);
		}
		else
		{
			ALBEDO = vec3(1, 0, 0);
		}
//		ALBEDO = vec3(0, 1, 0);
		ALPHA = 0.8;
	}
	else
	{
		ALBEDO = vec3(1, 0, 0);
		ALPHA = 0.8;
	}
	if(ndc.x > 1.0 || ndc.x < 0.0 || ndc.y > 1.0 || ndc.y < 0.0 || ndc.z > 1.0 || length(view_pos) > far)
	{
//		ALPHA = 0.5;
		ALBEDO = vec3(1.0);
		discard;
	}
//	if(dot(normal, normalize(view_pos.xyz)) <= 0.0)
//	{
//		ALBEDO = vec3(0, 1, 0);
//	}
//	else
//	{
//		ALBEDO = vec3(1, 0, 0);
//	}

}