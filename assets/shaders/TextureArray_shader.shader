shader_type spatial;

render_mode unshaded,cull_front;
uniform highp sampler3D tex1:hint_albedo;//纹理1
uniform highp sampler3D tex2:hint_albedo;//纹理2
uniform highp sampler3D tex3:hint_albedo;
uniform float timer :hint_range(0.0,1.0) =0.0;//时间0-1;
uniform float steps = 50;//射线间隔
uniform float xcull = 1.0;
uniform float ycull = 0.0;
varying vec3 world_camera;
varying vec3 world_position;

varying mat3 normalMat;
varying vec3 ecPosition;
uniform vec3 lightDirection;
const float epsilon = 0.0001;

const vec3 box_min = vec3(-0.5);
const vec3 box_max = vec3(0.5);


vec4 Interpolation(vec3 p, float percentage)
{
   vec4 color1,color2;
   color1 = texture(tex1, p);
   color2 = texture(tex2, p);
   color1 = color1 * (1.0 - percentage) + color2 * percentage;
   return color1;
}

vec3 Gradient(vec3 texturecoord)
{
    vec3 gradient;
    //float dx=0.5f/(dimensions.x);
    //float dy=0.5f/(dimensions.y);
    //float dz=0.5f/(dimensions.z);
	
	if ( texturecoord.x < epsilon ) return vec3( 1.0, 0.0, 0.0 );
	if ( texturecoord.y < epsilon ) return vec3( 0.0, 1.0, 0.0 );
	if ( texturecoord.z < epsilon ) return vec3( 0.0, 0.0, 1.0 );
	if ( texturecoord.x > 1.0 - epsilon ) return vec3( - 1.0, 0.0, 0.0 );
	if ( texturecoord.y > 1.0 - epsilon ) return vec3( 0.0, - 1.0, 0.0 );
	if ( texturecoord.z > 1.0 - epsilon ) return vec3( 0.0, 0.0, - 1.0 );
   
	float step1 = 0.01;
    vec3 a0;
    vec3 a1;

	{
		a0.x=Interpolation(texturecoord.xyz+vec3(step1,0,0), timer).x;
		a1.x=Interpolation(texturecoord.xyz+vec3(-step1,0,0), timer).x;
	}
    
	{
		a0.y=Interpolation(texturecoord.xyz+vec3(0,step1,0), timer).x;
		a1.y=Interpolation(texturecoord.xyz+vec3(0,-step1,0), timer).x;
	}
	
	{
		a0.z=Interpolation(texturecoord.xyz+vec3(0,0,step1), timer).x;
		a1.z=Interpolation(texturecoord.xyz+vec3(0,0,-step1), timer).x;
	}
    
    gradient = normalize(a1-a0);
    return gradient;
}

vec4 PS_Lighting(vec4 color , vec3 p)
{  
    float ka = 0.5;
	float kd = 0.5;
    float ks = 0.5f;
    float expS = 100.0;
	
	mat3 normalMat33 = normalMat;
	vec4 lightColor = vec4(1.0,1.0,1.0,1.0);
	
    vec3 gradient = normalize((normalMat33 * Gradient(p)));
	
	vec3 lightVec = normalize(lightDirection);
    vec3 halfv= reflect(-lightVec,gradient);
    vec3 viewVec= normalize(-ecPosition).xyz;
	float diffuse  = abs(dot(lightVec, gradient));
	
	float specular = 0.0;
    if(diffuse>0.0)
    {
        specular = pow(abs(dot(halfv, viewVec)), expS);
    }
    diffuse=kd*diffuse;
    specular=ks*specular;
    color.rgb=color.rgb *(ka+diffuse)+specular*lightColor.rgb;
   return color;
}

vec2 hitBox( vec3 orig, vec3 dir ) {
	vec3 inv_dir = 1.0 / dir;
	vec3 tmin_tmp = ( box_min - orig ) * inv_dir;
	vec3 tmax_tmp = ( box_max - orig ) * inv_dir;
	vec3 tmin = min( tmin_tmp, tmax_tmp );
	vec3 tmax = max( tmin_tmp, tmax_tmp );
	float t0 = max( tmin.x, max( tmin.y, tmin.z ) );
	float t1 = min( tmax.x, min( tmax.y, tmax.z ) );
	return vec2( t0, t1 );
}		

vec4 blendColor( vec4 destColor ,vec4 srcColor)
{
	float cla = srcColor.a + destColor.a - srcColor.a * destColor.a;
	vec3 clo = (srcColor.xyz * srcColor.a * (1.0 - destColor.a) + destColor.xyz * destColor.a) / cla;
	return vec4(clo,cla);
}		
					
void vertex() {
	world_position = VERTEX;
	world_camera = (inverse(MODELVIEW_MATRIX) * vec4(0, 0, 0, 1)).xyz; 

	ecPosition= mat3(WORLD_MATRIX * MODELVIEW_MATRIX) * VERTEX;
	normalMat = transpose(mat3(inverse(WORLD_MATRIX * MODELVIEW_MATRIX)));
}

void fragment() {
	vec3 vOrigin = world_camera;
	vec3 rayDir = normalize( world_position - vOrigin);
	vec2 bounds = hitBox(vOrigin, rayDir);

	if( bounds.x > bounds.y)
	{
		discard;
	}
	else
	{
		bounds.x = max( bounds.x, 0.0 );
		vec3 p = vOrigin + bounds.x * rayDir;
		vec3 pFirst;
		float first = 0.0;

		vec3 inc = 1.0 / abs( rayDir );
		float delta = min( inc.x, min( inc.y, inc.z ) );
		delta /= float(steps);

		vec4 tmpColor;
		for (float t = bounds.x; t <= bounds.y; t += delta)
		{		
			vec4 tmp0 =  texture(tex1 , p + 0.5);
			vec4 tmp1 =  texture(tex2 , p + 0.5);
			vec4 tmp2 = tmp0 * (1.0 - timer) + tmp1 * timer;
			vec4 tmp;
			if(tmp2.r <= 0.01) 
				tmp = vec4(0.0,0.0,0.0,0.0);
			else
				tmp = texture(tex3, vec3(tmp2.r, 1, 1));
			if(p.y < ycull && p.x > xcull) 
			{
				tmp.a = 0.0;
			}
			if (tmp.a > 0.0) 
			{
				tmpColor = blendColor(tmpColor, tmp);
				//tmpColor.rgb += (1.0 - tmpColor.a) * tmp.a * tmp.rgb;
				//tmpColor.a += (1.0 - tmpColor.a) * tmp.a;
				if(first == 0.0)
				{
					pFirst = p;
					first = 1.0;
				}
				if(tmpColor.a >= 1.0)
				{
					break;
				}
		
			}
			p += rayDir * delta;
		}
		if(tmpColor.a == 0.0)
			discard;
		else
		{
			//tmpColor = PS_Lighting(tmpColor, pFirst + 0.5);
			ALPHA = tmpColor.a;
			ALBEDO = tmpColor.rgb;
		}
	}
}

