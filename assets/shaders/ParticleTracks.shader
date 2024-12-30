shader_type spatial;
uniform float height_Scale = 1000;
uniform float width_Scale = 500;
uniform vec3 symbolColor = vec3(1.0,1.0,1.0);
uniform bool isLevelColor = false;
uniform float emissionPower = 1.0;//亮度
uniform highp sampler3D texture_albedo : hint_albedo;//色带
uniform highp sampler3D texture_albedo2 : hint_albedo;//渐变
uniform float maximum = 1.0;//长度最大值
uniform float minimum = 0.5;//长度最小值
uniform float maxScale = 1.0;//比例最大值
uniform float minScale = 0.5;//比例最小值
uniform float factor = 6.0;//透明因子
varying vec3 pos;//旋转之后的点
varying vec3 color1;
varying float al;
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
	vec3 v1 = vec3(INSTANCE_CUSTOM.x, 0.0, INSTANCE_CUSTOM.y);
	float Vlen = length(v1);
	float value1 = (Vlen - minimum) / (maximum - minimum);

	if(isLevelColor)
	{   
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

    VERTEX.z = VERTEX.z * height_Scale * (minScale + value1 * (maxScale - minScale));
    VERTEX.x = VERTEX.x * width_Scale;
	pos = Xform(VERTEX , vec3(0.0, -1.0, 0.0), phi);
    VERTEX.xyz = pos.xyz;
	al = texture(texture_albedo2, vec3(UV.y, 1.0, 1.0)).a;
    if(INSTANCE_CUSTOM.z < 1.0 && INSTANCE_CUSTOM.z > 0.0)
    {
        al *= INSTANCE_CUSTOM.z;
    }
}

void fragment(){
	ALPHA = al * al;
	ALBEDO = color1;
	EMISSION = color1 * (emissionPower * ALPHA);
}