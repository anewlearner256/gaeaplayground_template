shader_type spatial;

uniform vec2 uv_zero;
uniform vec2 uv_length;
uniform sampler3D tex1;//纹理1
uniform sampler3D tex2;//纹理2
uniform float timer;//时间0-1;
uniform float steps = 200;//射线间隔
uniform vec3 camera_pos;//相机在模型为中心的位置
uniform vec3 box_min;//模型最小BOX
uniform vec3 box_max;//模型最大BOX
uniform vec3 box_center;//模型中心点
uniform vec2 box_rotation1;//模型旋转inverse
uniform vec2 box_rotation2;//模型旋转inverse
varying vec3 vDirection;
varying vec3 vOrigin;

vec3 Xform(vec4 ro, vec3 v)
{
    vec3 vector2 = cross(ro.xyz ,v);
    return v + (vector2 * ro.w + cross(ro.xyz,vector2)) * 2.0;
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
	vOrigin = Xform(vec4(box_rotation1, box_rotation2), camera_pos) - Xform(vec4(box_rotation1, box_rotation2), box_center);
	vDirection =  VERTEX.xyz - vOrigin;
}

void fragment() {
	vec3 rayDir = normalize( vDirection );
	vec2 bounds = hitBox(vOrigin, rayDir);

	if( bounds.x >= bounds.y)
	{
		discard;
	}
	else
	{
		vec3 p = vOrigin + bounds.x * rayDir;
		float delta = (bounds.y - bounds.x) / steps;
		delta = ceil(delta);
		vec4 tmpColor;
		{
			int k = 0;
			int l = 0;
			for (float t = bounds.x; t < bounds.y; t += delta)
			{
				float u = (p.x  - box_min.x) /(box_max.x  - box_min.x);
				float v = (p.y  - box_min.y) /(box_max.y  - box_min.y);
				float w = (p.z  - box_min.z) /(box_max.z  - box_min.z);
				vec4 tmp0 =  texture(tex1 , vec3(uv_zero.x + u * uv_length.x,uv_zero.y + v * uv_length.y, w));
				vec4 tmp1 =  texture(tex2 , vec3(uv_zero.x + u * uv_length.x,uv_zero.y + v * uv_length.y, w));
				//vec4 tmp0 =  texture(tex1 , vec3( u, v , w));
				//vec4 tmp1 =  texture(tex2 , vec3( u, v , w));
				vec4 tmp = tmp0  + (tmp1 - tmp0) * timer;
				if (tmp.a > 0.0) 
				{
					l = 1;
					if(k == 0)
					{
						tmpColor.rgb = tmp.rgb;
						tmpColor.a = tmp.a;
						k = 1;
					}
					else
					{
						vec4 cc = blendColor(tmpColor, tmp);
						tmpColor.rgb = cc.xyz;
						tmpColor.a = cc.w;
					}
					if(tmpColor.a >= 1.0 || tmp.a >= 1.0)
						break;
				}
				p += rayDir * delta ;
			}
			ALPHA = tmpColor.a;
			ALBEDO = tmpColor.rgb;
			if ( ALPHA == 0.0 ) 
				discard;
			if(l == 0)
		  		ALPHA = 0.0;
		}
	}
}

