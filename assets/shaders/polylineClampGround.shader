shader_type spatial;
render_mode world_vertex_coords, unshaded, depth_test_disable, cull_disabled,depth_draw_never;

uniform vec4 albedo : hint_color = vec4(1.0, 0, 0, 1);
uniform sampler2D texture_albedo : hint_albedo;

uniform sampler2D vertexs_array : hint_albedo;

uniform float cube_half_size = 0.5;
uniform float width = 1;
uniform float min_height = -10000;//高度范围
uniform float max_height = 999999;
uniform vec3 invalid_color;

uniform bool userollerblind = false;
uniform vec2 splitline;
uniform int splitdirection;

const float BIAS = 38.0;

const float SHIFT_RIGHT_8 = 1.0f / 256.0;
const float SHIFT_RIGHT_16 = 1.0f / 65536.0;
const float SHIFT_RIGHT_24 = 1.0f / 16777216.0;
float RGBA2Float(vec4 rgba)
{   
	rgba = rgba * 255.0;
    float temp = rgba.a / 2.0f;
    float exponent = floor(temp);
    float sign = (temp - exponent) * 2.0f;
    exponent = exponent - BIAS;
    sign = sign * 2.0f - 1.0f;
    sign = -sign;
    if (exponent >= BIAS)
    {
        return sign < 0.0 ? -9999999.0: 9999999.0;
    }
    float unpacked = sign * rgba.r * SHIFT_RIGHT_8;
    unpacked += sign * rgba.g * SHIFT_RIGHT_16;
    unpacked += sign * rgba.b * SHIFT_RIGHT_24;
    return unpacked * pow(10.0f, exponent);
}
 
void getCorner(int batchId, out vec2 corner1, out vec2 corner2, out vec2 corner3, out vec2 corner4)
{
	corner1.x = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 8, 0), 0));
	corner1.y = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 8 + 1, 0), 0));
	
	corner2.x = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 8 + 2, 0), 0));
	corner2.y = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 8 + 3, 0), 0));
	
	corner3.x = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 8 + 4, 0), 0));
	corner3.y = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 8 + 5, 0), 0));
	
	corner4.x = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 8 + 6, 0), 0));
	corner4.y = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 8 + 7, 0), 0));
}

void getAttributes(int batchId, out vec3 start, out vec3 forward, out vec3 startNormal, out vec3 endNormal, out vec3 rightPlaneNormal)
{
	start.x = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 15, 0), 0));
	start.y = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 15 + 1, 0), 0));
	start.z = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 15 + 2, 0), 0));
	
	forward.x = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 15 + 3, 0), 0));
	forward.y = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 15 + 4, 0), 0));
	forward.z = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 15 + 5, 0), 0));
	
	startNormal.x = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 15 + 6, 0), 0));
	startNormal.y = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 15 + 7, 0), 0));
	startNormal.z = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 15 + 8, 0), 0));
	
	endNormal.x = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 15 + 9, 0), 0));
	endNormal.y = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 15 + 10, 0), 0));
	endNormal.z = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 15 + 11, 0), 0));
	
	rightPlaneNormal.x = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 15 + 12, 0), 0));
	rightPlaneNormal.y = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 15 + 13, 0), 0));
	rightPlaneNormal.z = RGBA2Float(texelFetch(vertexs_array, ivec2(batchId * 15 + 14, 0), 0));
	
}

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

varying flat vec4 v_startPlaneEC;
varying flat vec4 v_endPlaneEC;
varying flat vec4 ffff;
varying flat vec4 v_rightPlaneEC;
varying flat vec3 v_forwardDirectionEC;
varying flat vec3 v_start;
varying flat vec3 v_end;
varying flat vec3 v_offset;
varying flat float halfMaxWidth;
varying float metersPerPixel;

void vertex()
{
	float a = PROJECTION_MATRIX[ 2 ][ 2 ]; // 3nd entry in 3th column
	float b = PROJECTION_MATRIX[ 3 ][ 2 ]; // 3nd entry in 4th column
	float n = b / (a - 1.0);
	float nearPlaneHeight = 2.0 * n / PROJECTION_MATRIX[ 1 ][ 1 ];
	float nearPlaneWidth = 2.0 * n / PROJECTION_MATRIX[ 0 ][ 0 ];
	float distanceToPixel = n * 10.0;
	float inverseNear = 1.0 / n;
    float tanTheta = nearPlaneHeight / 2.0 * inverseNear;
    float pixelHeight = 2.0 * distanceToPixel * tanTheta / VIEWPORT_SIZE.y;
    tanTheta = nearPlaneWidth / 2.0 * inverseNear;
    float pixelWidth = 2.0 * distanceToPixel * tanTheta / VIEWPORT_SIZE.x;
	metersPerPixel = max(max(pixelWidth, pixelHeight), 0.1);
//	metersPerPixel = n * 0.05;
	
//	vec3 vertexEC = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
//	vec3 normalEC = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
//	vertexEC += width / UV2.y / 2.0  * normalEC * metersPerPixel;
//	VERTEX = (inverse(MODELVIEW_MATRIX) * vec4(vertexEC, 1.0)).xyz;
	if(abs(UV.x - 0.0) < 0.1)
	{
		VERTEX += width / UV.y / 2.0  * NORMAL * metersPerPixel;
	}
	else if(abs(UV.x - 1.0) < 0.1)
	{
		VERTEX += width / UV.y / 2.0  * TANGENT * metersPerPixel;
	}
	else if(abs(UV.x - 2.0) < 0.1)
	{
		VERTEX += width / UV.y / 2.0  * TANGENT * metersPerPixel;
	}
	else if(abs(UV.x - 3.0) < 0.1)
	{
		VERTEX += width / UV.y / 2.0  * NORMAL * metersPerPixel;
	}
	else if(abs(UV.x - 4.0) < 0.1)
	{
		VERTEX += width / UV.y / 2.0  * NORMAL * metersPerPixel;
	}
	else if(abs(UV.x - 5.0) < 0.1)
	{
		VERTEX += width / UV.y / 2.0  * TANGENT * metersPerPixel;
	}
	else if(abs(UV.x - 6.0) < 0.1)
	{
		VERTEX += width / UV.y / 2.0  * TANGENT * metersPerPixel;
	}
	else if(abs(UV.x - 7.0) < 0.1)
	{
		VERTEX += width / UV.y / 2.0  * NORMAL * metersPerPixel;
	}
	
	halfMaxWidth = width / 2.0;
	vec3 start = COLOR.xyz;
	vec3 offset = vec3(COLOR.w, UV2.xy);
	vec3 startPlaneNormal = vec3(-NORMAL.z, 0, NORMAL.x); 
	vec3 endPlaneNormal = vec3(TANGENT.z, 0, -TANGENT.x);
	vec3 rightPlaneNormal = normalize(vec3(-offset.z, 0, offset.x));
	
//	getAttributes(int(floor(UV2.x)), start, offset, startPlaneNormal, endPlaneNormal, rightPlaneNormal);
	
	vec3 end = start + offset;
	
	v_offset = offset;
	vec3 forward = normalize(offset);

	v_start = start;

	v_end = end;

	v_endPlaneEC.xyz = endPlaneNormal;
    v_endPlaneEC.w = -dot(endPlaneNormal, end);
//	v_endPlaneEC.xyz = (MODELVIEW_MATRIX * vec4(v_endPlaneEC.xyz, 0.0)).xyz;
	
	v_startPlaneEC.xyz = startPlaneNormal;
    v_startPlaneEC.w = -dot(startPlaneNormal, start);
//	v_startPlaneEC.xyz = (MODELVIEW_MATRIX * vec4(v_startPlaneEC.xyz, 0.0)).xyz;
	ffff = vec4(NORMAL, 1.0);
	v_rightPlaneEC.xyz = rightPlaneNormal;
    v_rightPlaneEC.w = -dot(rightPlaneNormal, start);
//	v_rightPlaneEC.xyz = (MODELVIEW_MATRIX * vec4(v_rightPlaneEC.xyz, 0.0)).xyz;
	
}
float rayPlaneDistance(vec3 origin, vec3 direction, vec3 planeNormal, float planeDistance) {
    // We don't expect the ray to ever be parallel to the plane
    return (-planeDistance - dot(planeNormal, origin)) / dot(planeNormal, direction);
}
void fragment() {
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 world_pos = world_pos_from_depth(depth, SCREEN_UV, INV_PROJECTION_MATRIX, (CAMERA_MATRIX));
	vec4 test_pos = (inverse(WORLD_MATRIX) * vec4(world_pos, 1.0));
//	vec4 test_pos = (INV_CAMERA_MATRIX * vec4(world_pos, 1.0));
//	float distanceFromStart = rayPlaneDistance(test_pos.xyz, -v_forwardDirectionEC, v_startPlaneEC.xyz, v_startPlaneEC.w);
//    float distanceFromEnd = rayPlaneDistance(test_pos.xyz, v_forwardDirectionEC, v_endPlaneEC.xyz, v_endPlaneEC.w);
	float disToRightPlane =  dot(test_pos.xyz - v_start, v_rightPlaneEC.xyz);
	float distanceFromStart = dot(test_pos.xyz - v_start, v_startPlaneEC.xyz);
    float distanceFromEnd = dot(test_pos.xyz - v_end, v_endPlaneEC.xyz);
	
	 if (abs(disToRightPlane) > halfMaxWidth * metersPerPixel || distanceFromStart < 0.0 || distanceFromEnd < 0.0 ) {
//		ALPHA = 1.0;
//ALBEDO = albedo.xyz;
        discard;
    }
	else
	{
		ALBEDO = albedo.xyz;
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
//	if(abs(ffff.y - 0.1) < 0.1)
//	{
//		ALBEDO = vec3(0.0, 1.0, 1.0);
//	}
	
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
