shader_type spatial;
uniform float sScale = 2000;
uniform vec3 symbolColor = vec3(0.0,1.0,0.0);
uniform bool isLevelColor = true;
uniform float emissionPower = 2.0;//亮度
uniform highp sampler3D texture_albedo : hint_albedo;//色带
uniform float timer;//混合度0-1
uniform float maximum;//最大值
uniform float minimum;//最小值
varying vec3 pos;//旋转之后的点
varying vec3 color1;

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
	return vec3(dot(Row0,v),dot(Row1,v),dot(Row2,v));
}

void vertex()
{
	vec3 v1 = vec3(INSTANCE_CUSTOM.x, 0.0, INSTANCE_CUSTOM.y);
	vec3 v2 = vec3(INSTANCE_CUSTOM.z, 0.0, INSTANCE_CUSTOM.w);
	float VlenA = length(v1);
	float VlenB = length(v2);
	float Vlen = VlenB - VlenA;
    Vlen = VlenA + Vlen * timer;

if(isLevelColor)
{   
	 float value1 = (Vlen - minimum) / (maximum - minimum);
	color1 = texture(texture_albedo, vec3(value1, 1.0, 1.0)).xyz;
}
else
color1 = symbolColor;


	float phi = atan(length(cross(vec3(0.0,0.0,1.0),v1)), dot(vec3(0.0,0.0,1.0),v1));
	float phi2 = atan(length(cross(vec3(0.0,0.0,1.0),v2)), dot(vec3(0.0,0.0,1.0),v2));
	pos = Xform(VERTEX , vec3(0.0,0.0,1.0), phi + (phi2 - phi) * timer);//vec3(0.0,0.0,1.0)
	VERTEX = (vec4(pos, 1.0) * sScale * Vlen).xyz;
}

void fragment(){
	ALPHA = 1.0;
	ALBEDO = color1;
	EMISSION = ALBEDO * (emissionPower * ALPHA);
}