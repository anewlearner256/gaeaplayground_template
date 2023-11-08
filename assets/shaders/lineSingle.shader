shader_type spatial;
render_mode cull_disabled, skip_vertex_transform, shadows_disabled,depth_test_disable,ambient_light_disabled,unshaded;

uniform float lineWidth;
uniform int lineStyle = 0;
uniform vec4 lineColor;

uniform sampler2D lineTex;
uniform bool hasLineTex = false;
uniform bool isFlowing = false;
uniform float flowVelocity = 1.0;
uniform float repeatTimes = 10;
uniform float emissionpower = 1.0;
varying vec3 color;


vec2 ComputeOffset(vec2 prevP, vec2 currentP, vec2 nextP, vec2 flag, vec4 color0, out bool f){ //Calculate offset direction based on two adjacent points
	f = false;
	vec2 dir1 = vec2(0, 0);
	vec2 dir2 = vec2(0, 0);
	vec2 dir = vec2(0, 0);
//	if(abs(color0.a - 0.0) <= 0.1)
//	{
//		dir = normalize(nextP - currentP);
//
////		dir = vec2(dir.y, -dir.x); //逆时针旋转90度
//		dir = vec2(cos(3.14 / 6.0) * dir.x - sin(3.14 / 6.0) * dir.y,  sin(3.14 / 6.0) * dir.x + cos(3.14 / 6.0) * dir.y); //逆时针旋转90度
//	}
//	else if(abs(color0.a - 1.0) <= 0.1)
//	{
//		dir = normalize(currentP - prevP);
//		dir = vec2(cos(-3.14 / 6.0) * dir.x - sin(-3.14 / 6.0) * dir.y,  sin(-3.14 / 6.0) * dir.x + cos(-3.14 / 6.0) * dir.y); //逆时针旋转90度
////		dir = vec2(dir.y, -dir.x); //逆时针旋转90度
//	}
//	else if(abs(color0.a - 2.0) <= 0.1)
//	{
//		dir = normalize(currentP - prevP);
//		dir = vec2(cos(-3.14 / 6.0) * dir.x - sin(-3.14 / 6.0) * dir.y,  sin(-3.14 / 6.0) * dir.x + cos(-3.14 / 6.0) * dir.y); //逆时针旋转90度
////		dir = vec2(dir.y, -dir.x); //逆时针旋转90度
//	}
//	else if(abs(color0.a - 3.0) <= 0.1)
//	{
//		dir = normalize(currentP - prevP);
//		dir = vec2(cos(3.14 / 6.0) * dir.x - sin(3.14 / 6.0) * dir.y,  sin(3.14 / 6.0) * dir.x + cos(3.14 / 6.0) * dir.y); //逆时针旋转90度
////		dir = vec2(dir.y, -dir.x); //逆时针旋转90度
//	}
//
	
	if(abs(nextP.x - currentP.x)<=0.1 && abs(nextP.y - currentP.y)<=0.1) //后置向量为零
	{
		dir = normalize(currentP - prevP);
		dir = vec2(dir.y, -dir.x); //逆时针旋转90度
	}
    else if( abs(prevP.x - currentP.x)<=0.1 && abs(prevP.y - currentP.y) <=0.1) //前置向量为零
	{
		dir = normalize(nextP - currentP);
		dir = vec2(dir.y, -dir.x); //逆时针旋转90度
	}
    else 
	{
        dir1 = normalize( currentP - prevP );
        dir2 = normalize( nextP - currentP );
        dir = dir1 + dir2;//转换到屏幕空间后，在某些视角下可能会使dir1和dir2的方向相反，使得dir为0，这时需要特殊处理
		if(abs(dir.x - 0.0) <= 0.001 && abs(dir.y - 0.0) <= 0.001) 
		{
			dir = vec2(0, 0);
		}
		else
		{
			dir = normalize(dir);
		}
		if(dir != vec2(0,0)) //dir不为0,根据拐角大小选择不同的拓宽方式
		{
			float alpha = acos(dot(-dir1, dir2));
			if(alpha < 3.14 / 2.0)
			{
				float cross12 = dir1.x * dir2.y - dir1.y * dir2.x;  
				if((cross12 < 0.0 && int(flag.x) % 4 == 0) 
					||(cross12 > 0.0 && int(flag.x) % 4 == 3) 
					||(cross12 > 0.0 && int(flag.x) % 4 == 1) 
					||(cross12 < 0.0 && int(flag.x) % 4 == 2)
				)
				{
					dir = -dir;
				}
			}
			else
			{
				dir = vec2(dir.y, -dir.x);
			}
		}
		else //dir 为0
		{
            f = true;			
			if(int(flag.x) % 4 == 0 || int(flag.x) % 4 == 1)
				dir = vec2(dir1.y, -dir1.x);
			else
				dir = vec2(-dir1.y, dir1.x);
		}
	}
	float angle = acos(dot(dir, dir1));
	float width = abs(1.0 / sin(angle));
	return dir * width;
}
vec4 unproject(vec2 screen, vec2 screen_size, float z, float w) { //Convert back to spatial coordinates
    vec2 clip_pos = vec2(screen.x / screen_size.x, screen.y / screen_size.y);
	vec3 clip_pos_3d = vec3(clip_pos,z);
	vec3 device_normal = clip_pos_3d * 2.0 - 1.0;
    vec4 res = vec4(device_normal * w, w);
	return res;
}
vec4 transform_screen_pos(mat4 project, mat4 MODELVIEW, vec3 coord, vec2 screen_size){ //Convert to screen coordinates
	vec4 device = project * MODELVIEW * vec4(coord.xyz, 1.0);
	vec3 device_normal = device.xyz / device.w;
    vec3 clip_pos_3d = (device_normal * 0.5 + 0.5);
	float z = clip_pos_3d.z;
	float w = device.w;
	vec2 clip_pos_2d = clip_pos_3d.xy;
	vec2 screen_pos = vec2(clip_pos_2d.x * screen_size.x, clip_pos_2d.y * screen_size.y); 
	vec4 res = vec4(screen_pos, z, w);
	return res;
}

void vertex(){
	vec3 dir1_3d;
	vec3 dir2_3d;
	if(abs(COLOR.y - 0.0) < 0.1)  //根据UV2.y判断NORMAL和TANGENT是否为零
	{
		color = vec3(0, 1, 0);
		dir1_3d = vec3(0, 0, 0);
		dir2_3d = TANGENT * 100.0;
	}
	else if(abs(COLOR.z - 0.0) < 0.1)
	{
		color = vec3(1, 0, 0);
		dir1_3d = NORMAL * 100.0;
		dir2_3d = vec3(0, 0, 0);
	}
	else
	{
		color = vec3(0, 0, 1);
		dir1_3d = NORMAL * 100.0;
		dir2_3d = TANGENT * 100.0;
	}
	vec3 prevP_3d = VERTEX - dir1_3d;
	vec3 nextP_3d = VERTEX + dir2_3d; 
	vec4 prevP = transform_screen_pos(PROJECTION_MATRIX, MODELVIEW_MATRIX, prevP_3d, VIEWPORT_SIZE);
	vec4 nextP = transform_screen_pos(PROJECTION_MATRIX, MODELVIEW_MATRIX, nextP_3d, VIEWPORT_SIZE);
	vec4 currentP = transform_screen_pos(PROJECTION_MATRIX, MODELVIEW_MATRIX, VERTEX, VIEWPORT_SIZE);
	
//	if( abs(prevP.x - currentP.x)<=0.0001 && abs(prevP.y - currentP.y) <=0.0001) //前置向量为零
//	{
////		color = vec4(0, 0, 1, 1);
//		color = vec3(0, 1, 0);
//	}
//    else 
//	{
////        COLOR = vec4(0, 0, 1, 1);
//		color = vec3(1, 0, 0);
//	} 
	
	bool f;
	vec2 offset = ComputeOffset(prevP.xy, currentP.xy, nextP.xy, UV2, COLOR,f);
    currentP = currentP + lineWidth * vec4(offset,0,0);
	VERTEX = (INV_PROJECTION_MATRIX * unproject(currentP.xy, VIEWPORT_SIZE, currentP.z, currentP.w)).xyz;
}

void fragment(){
//	float len = UV2.y / COLOR.x / UV.x;
//	float cameraHeight = length(CAMERA_RELATIVE_POS) - 6378137.0;
//	float num = len / cameraHeight / 0.1;
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
		ALBEDO = c.xyz + lineColor.rgb;
//		ALBEDO = texture(lineTex, vec2(mod(uv_x, 1.0), UV.y)).xyz + lineColor.rgb;
		//EMISSION = texture(lineTex, vec2(mod(uv_x, 1.0), UV.y)).xyz * vec3(0, 10, 0);
//		ALPHA =  1.0 / (1.0 + exp(-0.5 * (texture(lineTex, vec2(mod(uv_x, 1.0), UV.y)).a * 20.0 - 10.0)));
		ALPHA =  c.a;
		EMISSION = ALBEDO * lineColor.rgb * emissionpower;
		//EMISSION = (emission.rgb+emission_tex)*emission_energy;
//		ALPHA =  0.5;
	}
	else
	{
		ALBEDO = lineColor.rgb;
		ALPHA = lineColor.a;
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
//	if(abs(COLOR.x - 0.01) < 0.001)
//	{
//		ALBEDO = vec3(0,1, 0);
//	}
//	if(len < 1000.0)
//	{
//		ALBEDO = vec3(0, 0, 1);
//	}

	
//
//	if(UV.y >= 0.8 || UV.y <= 0.2)
//	{
//		ALBEDO = lineColor + vec3(1, 1, 1);	
//	}
	
//	if(abs(UV2.y - 62375.0) < 1000.0)
//	{
//		ALBEDO = vec3(0, 0, 1);
//	}
}