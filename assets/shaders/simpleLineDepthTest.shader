shader_type spatial;
render_mode cull_disabled, skip_vertex_transform, shadows_disabled;

uniform float lineWidth;
uniform int lineStyle = 0;
uniform vec4 lineColor;
uniform float near;
uniform float realWidth;

uniform sampler2D lineTex;
uniform bool hasLineTex = false;
uniform bool isFlowing = false;
uniform float flowVelocity = 1.0;
uniform float repeatTimes = 10;
uniform float emissionpower = 0.0;
varying flat vec3 color;


void trimSegment(mat4 projectionMatrix, in vec4 start, inout vec4 end ) {
	// trim end segment so it terminates between the camera plane and the near plane
	// conservative estimate of the near plane
	float a = projectionMatrix[ 2 ][ 2 ]; // 3nd entry in 3th column
	float b = projectionMatrix[ 3 ][ 2 ]; // 3nd entry in 4th column
	float n = b / (a - 1.0);
	float nearEstimate = - 0.5 * b / a;
	float alpha = ( -n - start.z) / ( end.z - start.z );
	end.xyz = mix( start.xyz, end.xyz, alpha);
}

varying float pixelLength;
//varying float uv_x;
varying flat float width;
varying flat float disFromStart;
varying flat vec3 vertexTemp;
varying vec3 vertexInter;
varying flat vec2 dir2D;
varying flat vec3 dir3D;
varying flat vec2 pos2D;
varying flat float pixelsPerMeter;
void vertex(){
	float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	// camera space
//	vec4 start = MODELVIEW_MATRIX * vec4(COLOR.xyz, 1.0 );
//	vec4 end = MODELVIEW_MATRIX * vec4(COLOR.w, UV.x, UV.y, 1.0 );
	vec4 start = MODELVIEW_MATRIX * vec4(VERTEX, 1.0 );
//	vec4 end = MODELVIEW_MATRIX * vec4(0.1517137,11,1.023797, 1.0 );
	vec4 end = MODELVIEW_MATRIX * vec4(COLOR.xyz, 1.0 );
	if(UV2.y < 0.0)
	{
		vec4 temp = start;
		start = end;
		end = temp;
	}
	if ( start.z < 0.0 && end.z >= 0.0 ) {
		trimSegment(PROJECTION_MATRIX, start, end );
	} else if ( end.z < 0.0 && start.z >= 0.0 ) {
		trimSegment(PROJECTION_MATRIX, end, start );
	}
	dir3D = end.xyz - start.xyz;
	// clip space
	vec4 clipStart = PROJECTION_MATRIX * start;
	vec4 clipEnd = PROJECTION_MATRIX * end;
	// ndc space
	vec3 ndcStart = clipStart.xyz / clipStart.w;
	vec3 ndcEnd = clipEnd.xyz / clipEnd.w;

	// direction
	vec2 dir = ndcEnd.xy - ndcStart.xy;
	vec2 normalSpaceStart = (ndcStart.xy + 1.0) / 2.0;
	vec2 normalSpaceEnd = (ndcEnd.xy + 1.0) / 2.0;
	
	vec2 screenStart = normalSpaceStart * VIEWPORT_SIZE;
	vec2 screenEnd = normalSpaceEnd * VIEWPORT_SIZE;
	float alpha;
	color = vec3(1, 0, 0);
	if(screenStart.x < 0.0 || screenStart.y < 0.0)
	{
		float alpha1 = (0.0 - screenStart.x) / abs(screenEnd.x - screenStart.x);
		float alpha2 = (0.0 - screenStart.y) / abs(screenEnd.y - screenStart.y);
		alpha = max(alpha1, alpha2);
		screenStart = screenStart + alpha * (screenEnd - screenStart);
		color = vec3(0, 1, 1);
	}
	if(screenStart.x >= VIEWPORT_SIZE.x || screenStart.y >= VIEWPORT_SIZE.y)
	{
		float alpha1 = (screenStart.x - VIEWPORT_SIZE.x) / abs(screenEnd.x - screenStart.x);
		float alpha2 = (screenStart.y - VIEWPORT_SIZE.y) / abs(screenEnd.y - screenStart.y);
		alpha = max(alpha1, alpha2);
		screenStart = screenStart + alpha * (screenEnd - screenStart);
		color = vec3(0, 0, 1);
	}
	dir2D = screenEnd - screenStart;
	pos2D = screenStart;
//	screenStart = clamp(screenStart, vec2(0, 0), VIEWPORT_SIZE);
//	screenEnd = clamp(screenEnd, vec2(0, 0), VIEWPORT_SIZE);
	// account for clip-space aspect ratio
	vec2 dir2 = (dir + 1.0) / 2.0;
	dir2.x *= aspect;
	dir.x *= aspect;
	pixelLength = length(screenEnd - screenStart);
	dir = normalize( dir );
	vec2 offset = vec2( dir.y, - dir.x );
	// undo aspect ratio adjustment
	dir.x /= aspect;
	
	offset.x /= aspect;
	// sign flip
	if ( UV2.x < 0.0 )
		offset *= - 1.0;
	// endcaps
	if ( UV2.y < -1.0 ) {
		offset += - dir;
	} else if ( UV2.y > 1.0 ) {
		offset += dir;
	}
	// adjust for linewidth
	offset *= lineWidth;
	// adjust for clip-space to screen-space conversion // maybe resolution should be based on viewport ...
	offset /= VIEWPORT_SIZE.y;
	// select end
	vec4 clip = ( UV2.y < 0.0 ) ? clipStart : clipEnd;
	// back to clip space
	offset *= clip.w;
	clip.xy += offset;
	vec3 vv = ( UV2.y < 0.0 ) ? start.xyz : end.xyz;
	VERTEX = (inverse(MODELVIEW_MATRIX) * INV_PROJECTION_MATRIX * clip).xyz;
	vertexTemp = start.xyz;
	vertexInter = start.xyz;
	width = length(VERTEX - vv);
	pixelsPerMeter = pixelLength / width;
//	clip.xy = (clip.xy + 1.0) / 2.0;
	POSITION = clip;
		
	

	float a = PROJECTION_MATRIX[ 2 ][ 2 ]; // 3nd entry in 3th column
	float b = PROJECTION_MATRIX[ 3 ][ 2 ]; // 3nd entry in 4th column
	float c = PROJECTION_MATRIX[ 0 ][ 0 ]; // 0nd entry in 0th column
	float n = b / (a - 1.0);
	float nearPlaneX = 2.0 * n / c;
	pixelsPerMeter = nearPlaneX / VIEWPORT_SIZE.x;
	disFromStart = UV.x;
	
// uv_x = UV.x / 2.0;
}

void fragment(){
//	float len = UV2.y / COLOR.x / UV.x;
//	float cameraHeight = length(CAMERA_RELATIVE_POS) - 6378137.0;
//	float num = len / cameraHeight / 0.1;
//	float uv_x = UV.y * repeatTimes;
	float uv_x = UV.x * repeatTimes;
	float uv2_y = UV2.y * repeatTimes;
	if(isFlowing)
	{
		uv_x = uv_x - TIME * flowVelocity;
		uv2_y = uv2_y + TIME * flowVelocity;
	}
	if(hasLineTex)
	{
		vec4 c = texture(lineTex, vec2(mod(uv_x, 1.0), UV.y));
		// vec4 c = texture(lineTex, vec2(uv_x , UV_y));
//		ALBEDO = vec3(1, 1, 1);
		ALBEDO = texture(lineTex, vec2(mod(uv_x, 1.0), UV.y)).xyz * lineColor.rgb;
		// EMISSION = texture(lineTex, vec2(mod(uv_x, 1.0), UV.y)).xyz * vec3(0, 10, 0);
//		ALPHA =  1.0 / (1.0 + exp(-0.5 * (texture(lineTex, vec2(mod(uv_x, 1.0), UV.y)).a * 20.0 - 10.0)));
		ALPHA =  c.a;
		EMISSION = ALBEDO * lineColor.rgb * emissionpower;

	}
	else
	{
		ALBEDO = lineColor.rgb;
		ALPHA = lineColor.a;
		EMISSION = ALBEDO * emissionpower;
	}
	//EMISSION = vec3(0, 1, 0);
//	if(lineStyle == 1)
//	{
//		if(mod(uv2_y, 100.0) <= 50.0)
//		{
//			discard;
//		}
//	}

	if(lineStyle == 1)
	{
		float d = 1.0;
		if(mod(uv_x, d) <= 0.5)
		{
			discard;
		}
	}
	ALBEDO = mix(pow((ALBEDO+ vec3(0.055)) * (1.0 / (1.0 + 0.055)),vec3(2.4)),ALBEDO * (1.0 / 12.92),lessThan(ALBEDO,vec3(0.04045)));
 	if (abs( UV2.y ) > 1.0) 
 	{
 		float a = UV2.x;
 	 	float b = ( UV2.y > 0.0 ) ? UV2.y - 1.0 : UV2.y + 1.0;
 	 	float len2 = a * a + b * b;
 	 	if (len2 > 1.0) 
 	 	{
 	 		discard;
 	 	}
 	}



}


void light()
{
	DIFFUSE_LIGHT = ALBEDO;
}