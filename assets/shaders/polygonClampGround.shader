shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disable, depth_draw_never;

uniform vec4 albedo : hint_color = vec4(1.0, 0, 0, 1);
uniform sampler2D texture_albedo : hint_albedo;
uniform vec2 uv_scale = vec2(1.0, 1.0);

uniform bool userollerblind = false;
uniform vec2 splitline;
uniform int splitdirection;

// Credit: https://stackoverflow.com/questions/32227283/getting-world-position-from-depth-buffer-value
vec3 world_pos_from_depth(float depth, vec2 screen_uv, mat4 inverse_proj, mat4 inverse_view) {
	float z = depth * 2.0 - 1.0;
	
	vec4 clipSpacePosition = vec4(screen_uv * 2.0 - 1.0, z, 1.0);
	vec4 viewSpacePosition = inverse_proj * clipSpacePosition;
	
	viewSpacePosition /= viewSpacePosition.w;
	
	vec4 worldSpacePosition = inverse_view * viewSpacePosition;
	
	return worldSpacePosition.xyz;
}


varying flat vec2 v1;
varying flat vec2 v2;
varying flat vec2 v3;

varying flat vec2 uv1;
varying flat vec2 uv2;
varying flat vec2 uv3;

vec3 getzhonxing(vec2 p, vec2 a, vec2 b, vec2 c)
{
	float q = ((p.y - a.y) * (c.x - a.x) - (p.x - a.x) * (c.y - a.y)) / ((b.y - a.y) * (c.x - a.x) - (b.x - a.x) * (c.y - a.y));
	float w = ((p.y - a.y) * (b.x - a.x) - (p.x - a.x) * (b.y - a.y)) / ((c.y - a.y) * (b.x - a.x) - (c.x - a.x) * (b.y - a.y));
	float e = 1.0 - q - w;
	return vec3(e, q, w);
}
void vertex()
{
	v1 = NORMAL.xy; 
	v2 = COLOR.xy;
	v3 = COLOR.zw;
	
	uv1 = UV;
	uv2 = UV2;
	uv3 = TANGENT.xy;
}
void fragment() {
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 world_pos = world_pos_from_depth(depth, SCREEN_UV, INV_PROJECTION_MATRIX, (CAMERA_MATRIX));
	vec4 test_pos = (inverse(WORLD_MATRIX) * vec4(world_pos, 1.0));
	vec2 dir1 = normalize(v2 - v1);
	vec2 dir2 = normalize(v3 - v2);
	vec2 dir3 = normalize(v1 - v3);
	vec2 p1 = normalize(test_pos.xz - v1);
	vec2 p2 = normalize(test_pos.xz - v2);
	vec2 p3 = normalize(test_pos.xz - v3);
	if((dir1.x * dir2.y - dir1.y * dir2.x) >= 0.0)
	{
		dir1 = -dir1;
		dir2 = -dir2;
		dir3 = -dir3;
	}
	if(((dir1.x * p1.y - dir1.y * p1.x) >= 0.0 || (dir2.x * p2.y - dir2.y * p2.x) >= 0.0 || (dir3.x * p3.y - dir3.y * p3.x) >= 0.0))
	{
//		ALPHA = 0.2;
		discard;
//		ALBEDO = vec3(1.0, 0.0, 0.0);
	}
	else
	{
		float s = abs(v1.x * (v2.y - v3.y) + v2.x * (v3.y - v1.y) + v3.x * (v1.y - v2.y)) / 2.0;
		float s2 = abs(uv1.x * (uv2.y - uv3.y) + uv2.x * (uv3.y - uv1.y) + uv3.x * (uv1.y - uv2.y)) / 2.0;
		vec3 zx = getzhonxing(test_pos.xz, v1, v2, v3);
		vec2 uv = zx.x * uv1 + zx.y * uv2 + zx.z * uv3;
		ALBEDO = texture(texture_albedo, test_pos.xz * uv_scale).xyz * albedo.xyz;
	}
	if(userollerblind)
		{
			if(splitdirection==1)
			{
				if(SCREEN_UV.x > splitline.x )
				{
					discard;
				}
			}
			else if(splitdirection==2)
			{
				if(SCREEN_UV.x < splitline.x )
				{
					discard;
				}
			}
		}
	ALPHA = albedo.a;
//	if(abs(v2.y) == 0.0)
//	{
//		ALBEDO = vec3(0.0, 0.0, 1.0);
//	}
	
//	ALBEDO = albedo.xyz;
//	ALPHA = 0.5;

	
	
//	ALBEDO = color + albedo.xyz;
//	wn, en, es, ws
//	if(abs(es.y - 2.0) < 0.01)
//	{
//		ALBEDO = vec3(0, 1, 0);
//	}
//	else
//	{
//		ALBEDO = vec3(0, 0, 1);
//	}
//	if(int(UV2.x) == 0)
//	{
//		ALBEDO = vec3(1, 0, 0);
//	}
//	else if(int(UV2.x) == 1)
//	{
//		ALBEDO = vec3(0, 1, 0);
//	}
//	else if(int(UV2.x) == 2)
//	{
//		ALBEDO = vec3(0, 0, 1);
//	}
//	else if(int(UV2.x) == 3)
//	{
//		ALBEDO = vec3(1, 1, 1);
//	}
//	else if(int(UV2.x) == 4)
//	{
//		ALBEDO = vec3(0, 1, 1);
//	}
	
	
}
