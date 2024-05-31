shader_type spatial;
uniform float maxScale = 1.0;
uniform float minScale = 0.1;
uniform float unitScale;
uniform vec3 symbolColor = vec3(0.0,1.0,0.0);
uniform bool isLevelColor = true;
uniform float emissionPower = 2.0;//亮度
uniform highp sampler3D texture_albedo : hint_albedo;//色带
uniform float timer;//混合度0-1
uniform float maximum;//最大值
uniform float minimum;//最小值
varying vec3 pos;//旋转之后的点
varying vec3 color1;
const float PI = 3.141592657;

vec3 Xform(vec3 v, vec3 axis, float phi)
{
	vec3 axisSq = vec3(axis.x * axis.x, axis.y * axis.y, axis.z * axis.z);
    float cosine = cos(phi);
	vec3 Row0;
	vec3 Row1;
	vec3 Row2;
    Row0.x = axisSq.x + cosine * (1.0f - axisSq.x);
    Row1.y = axisSq.y + cosine * (1.0f - axisSq.y);
    Row2.z = axisSq.z + cosine * (1.0f - axisSq.z);
	float sine = sin(phi);
    float t = 1.0f - cosine;
    float xyzt = axis.x * axis.y * t;
    float zyxs = axis.z * sine;
    Row0.y = xyzt - zyxs;
    Row1.x = xyzt + zyxs;

    xyzt = axis.x * axis.z * t;
    zyxs = axis.y * sine;
    Row0.z = xyzt + zyxs;
    Row2.x = xyzt - zyxs;

    xyzt = axis.y * axis.z * t;
    zyxs = axis.x * sine;
    Row1.z = xyzt - zyxs;
    Row2.y = xyzt + zyxs;
	
	//return mat3(vec3(Row0.x ,Row1.x, Row2.x),vec3(Row0.y ,Row1.y, Row2.y),vec3(Row0.z ,Row1.z, Row2.z));
	
	return vec3(dot(Row0,v),dot(Row1,v),dot(Row2,v));
}

void vertex()
{
	vec3 v1 = vec3(INSTANCE_CUSTOM.r, 0.0, INSTANCE_CUSTOM.g);
	vec3 v2 = vec3(INSTANCE_CUSTOM.b, 0.0, INSTANCE_CUSTOM.a);
	float VlenA = length(v1);
	float VlenB = length(v2);
	float Vlen = VlenB - VlenA;
    Vlen = VlenA + Vlen * timer;
	float value1 = (Vlen - minimum) / (maximum - minimum);

	if(isLevelColor)
	{   
		color1 = texture(texture_albedo, vec3(value1, 1.0, 1.0)).xyz;
	}
	else
		color1 = symbolColor;

	float phi = atan(v1.x / v1.z);
    if (v1.x > 0.0 && v1.z < 0.0)
    {
        phi += PI;
    }
	else if(v1.x < 0.0 && v1.z < 0.0)
		phi += PI;
    else if (v1.x < 0.0 && v1.z > 0.0)
    {
        phi += PI * 2.0;
    }
	float phi2 = atan(v2.x / v2.z);
    if (v2.x > 0.0 && v2.z < 0.0)
    {
        phi2 += PI;
    }
	else if(v2.x < 0.0 && v2.z < 0.0)
		phi2 += PI;
    else if (v2.x < 0.0 && v2.z > 0.0)
    {
        phi2 += PI * 2.0;
    }
	phi -= PI;
	phi2 -= PI;
    float phi0 = phi2 - phi;
	if(phi0 < PI && phi2 > phi)
		 pos = Xform(VERTEX , vec3(0.0, -1.0, 0.0), phi + phi0 * timer);
	else if(phi0 > PI && phi2 > phi)
		 pos = Xform(VERTEX , vec3(0.0, -1.0, 0.0), phi - (2.0 * PI - phi0) * timer);
    else if(phi0 < -PI && phi2 < phi)
	    pos = Xform(VERTEX , vec3(0.0, -1.0, 0.0), phi + (phi0 + 2.0 * PI) * timer);//(phi2 - phi)
    else if(phi0 > -PI && phi2 < phi)
	    pos = Xform(VERTEX , vec3(0.0, -1.0, 0.0), phi + phi0 * timer);//(phi2 - phi)
	VERTEX = (vec4(pos, 1.0) * (minScale + value1 * (maxScale - minScale)) * unitScale).xyz;
}

void fragment(){
	ALPHA = 1.0;
	ALBEDO = color1;
	EMISSION = ALBEDO * (emissionPower * ALPHA);
}