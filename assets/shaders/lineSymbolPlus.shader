shader_type spatial;
render_mode cull_disabled, skip_vertex_transform, depth_test_disable, shadows_disabled,ambient_light_disabled;

uniform int lineStyle = 0; //0,实线 1，虚线
uniform float segmentLength = 2;
uniform float gapSize = 0.5;
uniform float lineWidth = 2.0;
uniform int repeatTimes = 0; //当为虚线时，最好设置为0
uniform sampler2D lineTex:hint_white;
uniform bool hasLineTex = false;
uniform bool isFlowing = false;
uniform float flowVelocity = 1.0;
uniform float emissionpower = 0.0;
uniform vec4 lineColor = vec4(1.0, 1.0, 1.0, 1.0);
varying vec2  v_st;
varying float v_width;
varying float v_polylineAngle;
varying flat float pixelsPerMeter;
varying vec3 color;

const float epsilon7 = 0.0000001;
const float epsilon1 = 0.1;

bool equalsEpsilon3(vec3 left, vec3 right, float epsilon) 
{   
	return all(lessThanEqual(abs(left - right), vec3(epsilon)));
}
bool equalsEpsilon2(vec2 left, vec2 right, float epsilon) 
{   
	return all(lessThanEqual(abs(left - right), vec2(epsilon)));
}
void clipLineSegmentToNearPlane(
    vec4 p0,
    vec4 p1,
	mat4 projectionMatrix,
	vec2 windowSize,
    out vec4 positionWC,
    out bool clipped,
    out bool culledByNearPlane)
{
    culledByNearPlane = false;
    clipped = false;

	float a = projectionMatrix[ 2 ][ 2 ]; // 3nd entry in 3th column
	float b = projectionMatrix[ 3 ][ 2 ]; // 3nd entry in 4th column
	float near = b / (a - 1.0);
	float far = b / (a + 1.0);
    vec3 p1ToP0 = p1.xyz - p0.xyz;
    float magnitude = length(p1ToP0);
    vec3 direction = normalize(p1ToP0);
    float endPoint0Distance =  -(near + p0.z);
    float denominator = -direction.z;

    if (endPoint0Distance < 0.0 && abs(denominator) < epsilon7)
    {
        culledByNearPlane = true;
    }
    else if (endPoint0Distance < 0.0 && abs(denominator) > epsilon7)
    {
        // t = (-plane distance - dot(plane normal, ray origin)) / dot(plane normal, ray direction)
        float t = (near + p0.z) / denominator;
        if (t < 0.0 || t > magnitude)
        {
            culledByNearPlane = true;
        }
        else
        {
            p0.xyz = p0.xyz + t * direction;
            clipped = true;
        }
    }
	vec4 positionNDC = projectionMatrix * (vec4(p0));
	positionNDC.xyz /= positionNDC.w;
    positionWC.xy = windowSize * (positionNDC.xy + 1.0) / 2.0;
	positionWC.z = (positionNDC.z + 1.0) / 2.0;
	positionWC.w = positionNDC.w;
}

vec4 getPolylineWindowCoordinatesEC(mat4 projectionMatrix, vec2 windowSize, vec4 positionEC, vec4 prevEC, vec4 nextEC, float expandDirection, float width, bool usePrevious, out float angle, out vec3 ff)
{
    vec4 endPointWC, p0, p1;
    bool culledByNearPlane, clipped;
    clipLineSegmentToNearPlane(prevEC, positionEC, projectionMatrix, windowSize, p0, clipped, culledByNearPlane);
    clipLineSegmentToNearPlane(nextEC, positionEC, projectionMatrix, windowSize, p1, clipped, culledByNearPlane);
    clipLineSegmentToNearPlane(positionEC, usePrevious ? prevEC : nextEC, projectionMatrix, windowSize, endPointWC, clipped, culledByNearPlane);

    if (culledByNearPlane)
    {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }

    vec2 prevWC = normalize(p0.xy - endPointWC.xy);
    vec2 nextWC = normalize(p1.xy - endPointWC.xy);
//

    float expandWidth = width * 0.5;
    vec2 direction;

    if (equalsEpsilon3(prevEC.xyz - positionEC.xyz, vec3(0.0), epsilon1) || equalsEpsilon2(prevWC, -nextWC, epsilon1))
    {
		ff = vec3(1, 1, 0);
        direction = vec2(-nextWC.y, nextWC.x);
    }
    else if (equalsEpsilon3(nextEC.xyz - positionEC.xyz, vec3(0.0), epsilon1) || clipped)
    {
		ff = vec3(0, 1, 0);
        direction = vec2(prevWC.y, -prevWC.x);
    }
    else
    {
		ff = vec3(0, 0, 1);
        vec2 normal = vec2(-nextWC.y, nextWC.x);
        direction = normalize((nextWC + prevWC) * 0.5);
        if (dot(direction, normal) < 0.0)
        {
            direction = -direction;
        }

        // The sine of the angle between the two vectors is given by the formula
        //         |a x b| = |a||b|sin(theta)
        // which is
        //     float sinAngle = length(cross(vec3(direction, 0.0), vec3(nextWC, 0.0)));
        // Because the z components of both vectors are zero, the x and y coordinate will be zero.
        // Therefore, the sine of the angle is just the z component of the cross product.
        float sinAngle = abs(direction.x * nextWC.y - direction.y * nextWC.x);
        expandWidth = clamp(expandWidth / sinAngle, 0.0, width * 2.0);
    }
//	direction = vec2(-nextWC.y, nextWC.x);
    vec2 offset = direction * expandDirection * expandWidth * 1.0;
    return vec4(endPointWC.xy + offset, -endPointWC.z, endPointWC.w);
}

vec4 getPolylineWindowCoordinates(mat4 projectionMatrix, vec2 windowSize,vec4 positionEC, vec4 previousEC, vec4 nextEC, float expandDirection, float width, bool usePrevious, out float angle, out vec3 ff)
{
    return getPolylineWindowCoordinatesEC(projectionMatrix, windowSize, positionEC, previousEC, nextEC, expandDirection, width, usePrevious, angle, ff);
}

vec4 unproject(vec2 screen, vec2 screen_size, float z, float w) { //Convert back to spatial coordinates
    vec2 clip_pos = vec2(screen.x / screen_size.x, screen.y / screen_size.y);
	vec3 clip_pos_3d = vec3(clip_pos,z);
	vec3 device_normal = clip_pos_3d * 2.0 - 1.0;
    vec4 res = vec4(device_normal * w, w);
	return res;
}

void vertex()
{
	float texCoord = COLOR.x;
    float expandDir = COLOR.y;
    bool usePrev = COLOR.z < 0.0;
    float totalLength = COLOR.w;
	vec3 ff = vec3(1, 1, 1);
	float width = lineWidth + 0.5;
	
	vec4 p, prev, next;
	
	p = MODELVIEW_MATRIX * vec4(VERTEX, 1.0 );
    prev = MODELVIEW_MATRIX * vec4(VERTEX - NORMAL, 1.0 );
    next = MODELVIEW_MATRIX * vec4(VERTEX - TANGENT, 1.0 );
	float polylineAngle;
	vec4 positionWC = getPolylineWindowCoordinates(PROJECTION_MATRIX, VIEWPORT_SIZE, p, prev, next, expandDir, width, usePrev, polylineAngle, ff);
	v_polylineAngle = polylineAngle;
	color = ff;
	
	VERTEX =  (INV_PROJECTION_MATRIX * unproject(positionWC.xy, VIEWPORT_SIZE, positionWC.z, positionWC.w)).xyz;
//	POSITION = vec4((positionWC.xy / VIEWPORT_SIZE) * 2.0 - 1.0, positionWC.z, 1.0);
    v_width = width;
	
	if(repeatTimes != 0)
	{
		v_st = vec2(texCoord / totalLength * float(repeatTimes), clamp(expandDir, 0.0, 1.0));
	}
	else
	{
		float a = PROJECTION_MATRIX[ 2 ][ 2 ]; // 3nd entry in 3th column
		float b = PROJECTION_MATRIX[ 3 ][ 2 ]; // 3nd entry in 4th column
		float c = PROJECTION_MATRIX[ 0 ][ 0 ]; // 0nd entry in 0th column
		float n = b / (a - 1.0);
		float nearPlaneX = 2.0 * n / c;
		pixelsPerMeter = nearPlaneX / VIEWPORT_SIZE.x;
		float tempTexCoord = texCoord;
		float realwidth = pixelsPerMeter * 10.0 * v_width;
		float reallength = realwidth * float(textureSize(lineTex, 0).x) / float(textureSize(lineTex, 0).y);
		tempTexCoord = tempTexCoord / reallength;
		v_st = vec2(tempTexCoord, clamp(expandDir, 0.0, 1.0));
	}
	
	NORMAL = vec3(1);
	TANGENT = vec3(1);
}
void fragment()
{
	
	vec2 uv = v_st;
	if(isFlowing)
	{
		uv.x = uv.x - TIME * flowVelocity;
	}
	vec4 textureColor = texture(lineTex, vec2(uv.x, uv.y) );
	ALBEDO = textureColor.xyz * lineColor.xyz;
	ALBEDO = mix(pow((ALBEDO+ vec3(0.055)) * (1.0 / (1.0 + 0.055)),vec3(2.4)),ALBEDO * (1.0 / 12.92),lessThan(ALBEDO,vec3(0.04045)));
	EMISSION = ALBEDO  * emissionpower;
	ALPHA = textureColor.a * lineColor.a;
	if(lineStyle == 1)
	{
		if(mod(uv.x, segmentLength) <= gapSize )
		{
			discard;
		}
	}
	
}

void light()
{
	DIFFUSE_LIGHT = ALBEDO;
}