shader_type canvas_item;
varying vec4 background;
uniform float x_normal_offset;
uniform float y_normal_offset;
uniform vec2 window_size;
uniform int anchor;
uniform float mark_size;
uniform vec4 row1;
uniform vec4 row2;
uniform vec4 row3;
uniform vec4 row4;
uniform mat4 camera_matrix;
uniform vec3 eyedir;
uniform vec3 global_origin;
uniform float camera_near;
uniform vec3 camera_pos;
uniform float distance_to_center;
//uniform vec4 XI;
//uniform vec2 V21;
//render_mode skip_vertex_transform;

bool is_pos_behind(vec3 p_pos)
{
	return dot(eyedir,p_pos-global_origin) < camera_near;
}

vec3 XformInv(vec3 p_pos){
	 //与C++里的顺序不同，C#里transform的basis是按行排序的，因此算法要将索引反转
	vec3 v=p_pos-vec3(camera_matrix[3][0],camera_matrix[3][1],camera_matrix[3][2]);

	return vec3(
		(camera_matrix[0][0] * v.x) + (camera_matrix[0][1] * v.y) + (camera_matrix[0][2] * v.z),
		(camera_matrix[1][0] * v.x) + (camera_matrix[1][1] * v.y) + (camera_matrix[1][2] * v.z),
		(camera_matrix[2][0] * v.x) + (camera_matrix[2][1] * v.y) + (camera_matrix[2][2] * v.z)
	);
}

vec4 xform4(vec4 p_vec4,mat4 matrix){
	//mat4 matrix=mat4(row1,row2,row3,row4);

	vec4 ret;
	ret.x = matrix[0][0] * p_vec4.x + matrix[1][0] * p_vec4.y + matrix[2][0] * p_vec4.z + matrix[3][0] * p_vec4.w;
    ret.y = matrix[0][1] * p_vec4.x + matrix[1][1] * p_vec4.y + matrix[2][1] * p_vec4.z + matrix[3][1] * p_vec4.w;
    ret.z = matrix[0][2] * p_vec4.x + matrix[1][2] * p_vec4.y + matrix[2][2] * p_vec4.z + matrix[3][2] * p_vec4.w;
    ret.w = matrix[0][3] * p_vec4.x + matrix[1][3] * p_vec4.y + matrix[2][3] * p_vec4.z + matrix[3][3] * p_vec4.w;

	return ret;
}

vec2 transform_screen_pos(mat4 project, mat4 WORLDMATRIX,mat4 EXTRA, vec3 coord, vec2 screen_size){ //Convert to screen coordinates
	vec4 device =  project * WORLDMATRIX * vec4(coord.xyz, 1.0);
	vec3 device_normal = device.xyz / device.w;
    vec3 clip_pos_3d = (device_normal * 0.5 + 0.5);
	float z = clip_pos_3d.z;
	float w = device.w;
	vec2 clip_pos_2d = clip_pos_3d.xy;
	vec2 screen_pos = vec2(clip_pos_2d.x * screen_size.x, clip_pos_2d.y * screen_size.y); 
	//vec4 res = vec4(screen_pos, z, w);
	return vec2(screen_pos);
}

vec2 unproject(vec3 p_pos,vec2 viewport_size,mat4 matrix)
{
	vec3 tmpV3=XformInv(p_pos);
	
	vec4 p=vec4(tmpV3.x,tmpV3.y,tmpV3.z,1.0);
	p=xform4(p, matrix);
	p.x /= p.w;
	p.y /= p.w;
	p.z /= p.w;

	vec2 res;
	res.x=(p.x * 0.5 + 0.5) * viewport_size.x;
	res.y=(-p.y * 0.5 + 0.5) * viewport_size.y;

	return res;
}

float get_scale(vec3 pos)
{
	float camera_distance_to_icon=distance(pos,camera_pos);
	float scale=distance_to_center/camera_distance_to_icon;
	if (scale < 1.0) 
		scale += (1.0 - scale) * 0.05f;
	
	return scale;
}

vec2 get_offset(int nCOLORa,float scale)
{	
	float vertex_x_offset_total=float(nCOLORa/100);
	float vertex_y_offset_total=float(nCOLORa%100);
	float vertex_x_offset=0f;
	float vertex_y_offset=0f;
	switch(anchor){
		//None
		case 0:
			break;
		//Up
		case 1:
			vertex_y_offset=-(vertex_y_offset_total/2.0)*y_normal_offset*scale;
			vertex_y_offset-=mark_size/2f*scale;
			break;
		//Down
		case 2:
			vertex_y_offset=(vertex_y_offset_total/2.0)*y_normal_offset*scale;
			vertex_y_offset+=mark_size/2f*scale;
			break;
		//Left
		case 3:
			vertex_x_offset=-(vertex_x_offset_total/2.0)*x_normal_offset*scale;
			vertex_x_offset-=mark_size/2f*scale;
			break;
		//Right
		case 4:
			vertex_x_offset=(vertex_x_offset_total/2.0)*x_normal_offset*scale;
			vertex_x_offset+=mark_size/2f*scale;
			break;
	}
	return vec2(vertex_x_offset,vertex_y_offset);
}

void vertex() {
	//UV单位为1/图片长度或宽度
	//COLOR单位为1/255
	//p=length()
	vec3 p_pos=vec3(vec3(COLOR.r*1000000.0*10.0,COLOR.g*1000000.0*10.0,COLOR.b*1000000.0*10.0));
	if(is_pos_behind(p_pos))
	{
		background=vec4(0,0,0,0);
		return;
	}
	vec2 screenSize=vec2(1024.0,600.0);
	
	//VERTEX+=vec2(COLOR.r*255.0,COLOR.r*255.0);
	
	
	
	mat4 matrix=mat4(row1,row2,row3,row4);
	//VERTEX+=transform_screen_pos(PROJECTION_MATRIX,WORLD_MATRIX,EXTRA_MATRIX, vec3(COLOR.r*10000000.0,COLOR.g*10000000.0,COLOR.b*10000000.0),screenSize);
	
	//VERTEX = ( WORLD_MATRIX * vec4(VERTEX,0.0, 1.0)).xy;
	
	//VERTEX+=unproject(p_pos,screenSize,matrix);
	vec2 p2=unproject(p_pos,window_size,matrix);
	float scale=get_scale(p_pos);
	
	if(p2.x<0.0||p2.x>window_size.x||p2.y<0.0||p2.y>window_size.y)
	{
		background=vec4(0,0,0,0);
		return;
	}
	//if(int(V21.x)==int(p2.x))
	//VERTEX+=vec2(100,100);
	else
	{
		VERTEX=vec2(VERTEX.x*(x_normal_offset*scale),VERTEX.y*(y_normal_offset*scale));
		VERTEX+=p2;
	}
	//在强转前，为避免精度丢失，先用round进行四舍五入
	int nCOLORa=int(round(COLOR.a*10000.0));
	VERTEX+=get_offset(nCOLORa,scale);
	//在强转前，为避免精度丢失，先用round进行四舍五入
	int nCOLORrg=int(round(UV.x*1000000.0));
	int nCOLORba=int(round(UV.y*1000000.0));
	int color_r=nCOLORrg/1000;
	int color_g=nCOLORrg%1000;
	int color_b=nCOLORba/1000;
	int color_a=nCOLORba%1000;
	
	background=vec4(float(color_r)/255.0,float(color_g)/255.0,float(color_b)/255.0,float(color_a)/255.0);
}

void fragment(){
	//ALBEDO=texture(texure_position);
	if(background.a==0.0)
		discard;
	COLOR = background; //read from texture
  //COLOR=texture(TEXTURE,vec2(UV.x*0.015625+texture_x_offset,UV.y*0.015625+texture_y_offset));
}