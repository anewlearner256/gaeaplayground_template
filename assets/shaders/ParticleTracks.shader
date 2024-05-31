shader_type spatial;
uniform float height_Scale = 1000;
uniform float width_Scale = 500;
uniform vec3 symbolColor = vec3(0.0,1.0,0.0);
uniform bool isLevelColor = false;
uniform float emissionPower = 10.0;//亮度
uniform highp sampler3D texture_albedo : hint_albedo;//色带
uniform highp sampler3D texture_albedo2 : hint_albedo;//渐变
uniform float maximum;//最大值
uniform float minimum;//最小值
uniform float factor = 6.0;//透明因子
varying vec3 pos;//旋转之后的点
varying vec3 color1;
varying float al;
varying float phiOld;
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
	return vec3(dot(Row0,v),dot(Row1,v),dot(Row2,v));
	
	//return mat3(vec3(Row0.x ,Row1.x, Row2.x),vec3(Row0.y ,Row1.y, Row2.y),vec3(Row0.z ,Row1.z, Row2.z));
}

void vertex()
{
	vec3 v1 = vec3(INSTANCE_CUSTOM.r, 0.0, INSTANCE_CUSTOM.g);
	float Vlen = length(v1);

if(isLevelColor)
{   
	 float value1 = (Vlen - minimum) / (maximum - minimum);
	color1 = texture(texture_albedo, vec3(value1, 1.0, 1.0)).xyz;
}
else
color1 = symbolColor;

    float phi = atan(v1.x / v1.z);
    if (v1.x > 0.0 && v1.z > 0.0)
    {
        phi -= PI;
    }
    else if (v1.x < 0.0 && v1.z > 0.0)
    {
        phi += PI;
    }

    VERTEX.z = VERTEX.z * height_Scale * Vlen;
    VERTEX.x = VERTEX.x * width_Scale;
	pos = Xform(VERTEX , vec3(0.0, -1.0, 0.0), phi);
    VERTEX.xyz = pos.xyz;
	al = texture(texture_albedo2, vec3(UV.y, 1.0, 1.0)).a;
}

void fragment(){
	ALPHA = al * al * al * al;
	ALBEDO = color1;
	//EMISSION = vec3(1.0,1.0,1.0) * (emissionPower * ALPHA);
}