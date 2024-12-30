shader_type spatial;
render_mode depth_draw_alpha_prepass,unshaded,cull_back, ambient_light_disabled, depth_test_disable;
uniform sampler2D texture_albedo : hint_albedo;

uniform vec4 texture_color : hint_color = vec4(1.0); 
uniform float distance_to_center;
uniform int anchor;
uniform float text_size;
uniform float icon_size;
uniform int text_mode;
uniform vec2 screenOffset = vec2(0);


varying float isVisable;

uniform bool userollerblind = false;
uniform vec2 splitline;
uniform int splitdirection;

vec3 XformInv(vec3 p_pos,mat4 camera_matrix){	
	vec3 v=p_pos-vec3(camera_matrix[3][0],camera_matrix[3][1],camera_matrix[3][2]);

	return vec3(
		(camera_matrix[0][0] * v.x) + (camera_matrix[0][1] * v.y) + (camera_matrix[0][2] * v.z),
		(camera_matrix[1][0] * v.x) + (camera_matrix[1][1] * v.y) + (camera_matrix[1][2] * v.z),
		(camera_matrix[2][0] * v.x) + (camera_matrix[2][1] * v.y) + (camera_matrix[2][2] * v.z)
	);
}

vec4 xform4(vec3 p_vec,mat4 matrix){
	//mat4 matrix=mat4(row1,row2,row3,row4);
	//将相机坐标系转换为透视坐标系
	vec4 ret;
	ret.x = matrix[0][0] * p_vec.x + matrix[1][0] * p_vec.y + matrix[2][0] * p_vec.z + matrix[3][0];
    ret.y = matrix[0][1] * p_vec.x + matrix[1][1] * p_vec.y + matrix[2][1] * p_vec.z + matrix[3][1];
    ret.z = matrix[0][2] * p_vec.x + matrix[1][2] * p_vec.y + matrix[2][2] * p_vec.z + matrix[3][2];
    ret.w = matrix[0][3] * p_vec.x + matrix[1][3] * p_vec.y + matrix[2][3] * p_vec.z + matrix[3][3];

	return ret;
}

vec3 unproject(vec3 p_pos,mat4 proj_matrix,mat4 cam_matrix)
{
	vec3 tmpV3=XformInv(p_pos,cam_matrix);
	
	vec4 p=xform4(tmpV3, proj_matrix);
	
	p.x /= p.w;
	p.y /= p.w;
	p.z /= p.w;

	return p.xyz;
}

float get_scale(vec3 pos,vec3 camera_pos)
{
	float camera_distance_to_icon=distance(pos,camera_pos);
	
	if(distance_to_center == 0.0)
		return 1.0;
		
	float scale= distance_to_center / camera_distance_to_icon;
	if (scale < 1.0) 
		scale += (1.0 - scale) * 0.05f;
	
	return scale;
}

vec2 get_offset(vec2 uv2,float scale,vec4 color)
{
	//UV2在存储四位数以上的值时存在存储错误，因此必要时候，Y上的部分储值转移至X
	// 顶点编号
	int vertex_index=int(round(uv2.x * 10.)) % 10;

	float vertex_x_offset=0f;
	float vertex_y_offset=0f;
	
	if(text_mode == 0){
		vertex_x_offset+=((vertex_index==0||vertex_index==3)?-0.5:0.5)*icon_size*scale;
		vertex_y_offset+=((vertex_index==0||vertex_index==1)?-0.5:0.5)*icon_size*scale;
		return vec2(vertex_x_offset,vertex_y_offset);
	}else{
		float cnt = uv2.y;
		float all_row = round(color.x * 100f);
		float cur_row = round(color.y * 100f);
		float word_space = round(color.z * 100f) * 10f + round(color.w * 100f) / 10f;
		
		switch(anchor){
			//None
			case 0:
				vertex_y_offset += (cur_row - (all_row / 2.0)) * text_size * scale - text_size / 2.0 * scale;
				vertex_x_offset -= (cnt / 2.0 - word_space) * scale;
				break;
			//Up
			case 1:
				vertex_y_offset -= icon_size * scale ;
				vertex_y_offset -= (all_row - cur_row) * text_size * scale;
				vertex_x_offset -= (cnt / 2.0 - word_space) * scale;
				break;
			//Right
			case 2:
				vertex_x_offset += (icon_size - text_size * 0.4) * scale;
				vertex_x_offset += word_space * scale;
				vertex_y_offset += (cur_row - (all_row / 2.0)) * text_size * scale - text_size / 2.0 * scale;
				break;
			//Down
			case 3:
				vertex_y_offset += icon_size * scale;
				vertex_y_offset += (cur_row - 1.0) * text_size * scale;
				vertex_x_offset -= (cnt / 2.0 - word_space) * scale;
				break;
			//Left
			case 4:
				vertex_x_offset -= (icon_size - text_size * 0.4) * scale;
				vertex_x_offset -= (cnt - word_space) * scale;
				vertex_y_offset += (cur_row - (all_row / 2.0)) * text_size * scale - text_size / 2.0 * scale;
				break;
		}
		
		vertex_x_offset+=((vertex_index==0||vertex_index==3)?-0.5:0.5)*text_size*scale;
		vertex_y_offset+=((vertex_index==0||vertex_index==1)?-0.5:0.5)*text_size*scale;
		return vec2(vertex_x_offset,vertex_y_offset); 
	}
}

void vertex() {
	vec3 world_position=(WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec4 p = (WORLD_MATRIX * vec4(VERTEX, 1.0));
	vec3 v1 = normalize( - world_position);
	vec3 v2 = -normalize(world_position + CAMERA_RELATIVE_POS.xyz);
	float cos0 = dot(v1, v2) / (length(v1) * length(v2));

	if(dot(v1, v2) < -0.1)
	{
		isVisable = 1.0;
	}
	else
	{
		isVisable = -1.0;
	}	
	
	vec3 p3=unproject(world_position,PROJECTION_MATRIX,CAMERA_MATRIX);
	
	float scale=get_scale(VERTEX,CAMERA_RELATIVE_POS.xyz);
		
	if(p3.x<-1.0||p3.x>1.0||p3.y<-1.0||p3.y>1.0||p3.z<-1.0||p3.z>1.0)
	{
		UV=vec2(-1,-1);
		return;
	}
	else
	{
		vec2 res;
		res.x=(p3.x * 0.5 + 0.5) * VIEWPORT_SIZE.x;
		res.y=(-p3.y * 0.5 + 0.5) * VIEWPORT_SIZE.y;
		
		vec2 offset=get_offset(UV2,scale,COLOR);
		res.x+=offset.x;
		res.y+=offset.y;
		
		res += screenOffset;
		
		p3.x=res.x*2f/VIEWPORT_SIZE.x-1f;
		p3.y=1f-2f*res.y/VIEWPORT_SIZE.y;
		POSITION=vec4(p3,1.0);
		
	}
}

uniform vec4 fontColor = vec4(1.0);
uniform vec4 outLineColor = vec4(0.0);
uniform vec3 BLACK = vec3(0.0);
uniform vec4 hoverColor = vec4(1.0);
uniform int Id = -2;

bool eq(vec3 c1,vec3 c2){
	float the = 0.3;
	// 设定阈值，确保选出所有白色进行修改
	return abs(c1.r-c2.r)<the &&
		abs(c1.g-c2.g)<the &&
		abs(c1.b-c2.b)<the;
}

void fragment() {
	if(isVisable < 0.0) 
	{
		discard;
	}
	else
	{
		DEPTH = DEPTH - 0.1;
	}
	if(UV==vec2(-1,-1))
		discard;
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo_tex.rgb;
	ALPHA=albedo_tex.a;
	
	// 字体模式下
	if(text_mode == 1){
		
//		if(Id != int(round(NORMAL.x * 100.)*100. + round(NORMAL.y * 100.))) ALBEDO *= fontColor.rgb;
//		else ALBEDO *= hoverColor.rgb;

		if(int(UV2.x) == Id) ALBEDO *= hoverColor.rgb;
		else ALBEDO *= fontColor.rgb;

		//黑色外包框效果不佳
		if(eq(ALBEDO,BLACK))
			ALBEDO += outLineColor.xyz;
			
//		ALBEDO *= COLOR.xyz;
	}
	else { 
		// 图片模式
		ALBEDO *= texture_color.rgb;
		ALPHA *= texture_color.a;
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
}