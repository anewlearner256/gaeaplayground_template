shader_type spatial;
render_mode depth_draw_alpha_prepass,unshaded,cull_back,depth_test_disable;
uniform sampler2D texture_albedo : hint_albedo;
uniform float distance_to_center;

uniform float text_size = 30;
uniform float alpha;
uniform float boxsize;
uniform float chartexturesize;
varying vec2 base;

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

void vertex() {
	vec3 world_position=(WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 p3=unproject(world_position,PROJECTION_MATRIX,CAMERA_MATRIX);
	float scale=get_scale(VERTEX,CAMERA_RELATIVE_POS.xyz);

	if(p3.x<-1.0||p3.x>1.0||p3.y<-1.0||p3.y>1.0||p3.z<-1.0||p3.z>1.0) {
		UV = vec2(-1.0,-1.0);
		return ;
	}

	vec2 res;

	res.x=(p3.x * 0.5 + 0.5) * VIEWPORT_SIZE.x;
	res.y=(-p3.y * 0.5 + 0.5) * VIEWPORT_SIZE.y;
	
	float ro = radians(45. - INSTANCE_CUSTOM.w); // UV2.x的范围 -45~45 之间
	
	float sideLength = text_size / 2.0 / cos(radians(45)); // 斜边长
	
	float col = INSTANCE_CUSTOM.x,row = INSTANCE_CUSTOM.y;
	
	int flag = int(INSTANCE_CUSTOM.z); // 字体方向
	
	if(VERTEX.x == -0.05 && VERTEX.y == 0.05) {
		if(flag == 1) {
			base.x = (col) * boxsize / chartexturesize;
			base.y = (row) * boxsize / chartexturesize;
		}
		else if(flag == 2) {
			base.x = (col) * boxsize / chartexturesize;
			base.y = (row + 1.0) * boxsize / chartexturesize;
		}
		else if(flag == 3) {
			base.x = (col - 1.0) * boxsize / chartexturesize;
			base.y = (row + 1.0) * boxsize / chartexturesize;
		}
		else {
			base.x = (col - 1.0) * boxsize / chartexturesize;
			base.y = (row) * boxsize / chartexturesize;	
		}
		
		res.x += (sideLength * cos(ro) * scale);
		res.y += (-sideLength * sin(ro) * scale);
	}
	else if(VERTEX.x == 0.05 && VERTEX.y == 0.05) {
		if(flag == 1) {
			base.x = (col) * boxsize / chartexturesize;
			base.y = (row + 1.0) * boxsize / chartexturesize;
		}
		else if(flag == 2) {
			base.x = (col - 1.0) * boxsize / chartexturesize;
			base.y = (row + 1.0) * boxsize / chartexturesize;
		}
		else if(flag == 3) {
			base.x = (col - 1.0) * boxsize / chartexturesize;
			base.y = (row) * boxsize / chartexturesize;
		}
		else {
			base.x = (col) * boxsize / chartexturesize;
			base.y = (row) * boxsize / chartexturesize;
		}
		
		res.x += (sideLength * sin(ro) * scale);
		res.y += (sideLength * cos(ro) * scale);
	}
	else if(VERTEX.x == 0.05 && VERTEX.y == -0.05) {
		if(flag == 1) {
			base.x = (col - 1.0) * boxsize / chartexturesize;
			base.y = (row + 1.0) * boxsize / chartexturesize;
		}
		else if(flag == 2) {
			base.x = (col - 1.0) * boxsize / chartexturesize;
			base.y = (row) * boxsize / chartexturesize;	
		}
		else if(flag == 3) {
			base.x = (col) * boxsize / chartexturesize;
			base.y = (row) * boxsize / chartexturesize;
		}
		else {
			base.x = (col) * boxsize / chartexturesize;
			base.y = (row + 1.0) * boxsize / chartexturesize;
		}

		res.x += (-sideLength * cos(ro) * scale);
		res.y += (sideLength * sin(ro) * scale);
	}
	else if(VERTEX.x == -0.05 && VERTEX.y == -0.05){
		if(flag == 1) {
			base.x = (col - 1.0) * boxsize / chartexturesize;
			base.y = (row) * boxsize / chartexturesize;	
		}
		else if(flag == 2) {
			base.x = (col) * boxsize / chartexturesize;
			base.y = (row) * boxsize / chartexturesize;
		}
		else if(flag == 3) {
			base.x = (col) * boxsize / chartexturesize;
			base.y = (row + 1.0) * boxsize / chartexturesize;
		}
		else {
			base.x = (col - 1.0) * boxsize / chartexturesize;
			base.y = (row + 1.0) * boxsize / chartexturesize;
		}
		
		res.x += (-sideLength * sin(ro) * scale);
		res.y += (-sideLength * cos(ro) * scale);
	}
	
	p3.x=res.x*2f/VIEWPORT_SIZE.x-1f;
	p3.y=1f-2f*res.y/VIEWPORT_SIZE.y;
	POSITION=vec4(p3,1.0);

}


uniform vec4 fontColor = vec4(1.0);
uniform vec4 outLineColor = vec4(0.0);
uniform vec3 BLACK = vec3(0.0);

bool eq(vec3 c1,vec3 c2){
	float the = 0.3;
	// 设定阈值，确保选出所有白色进行修改
	return abs(c1.r-c2.r)<the &&
		abs(c1.g-c2.g)<the &&
		abs(c1.b-c2.b)<the;
}

void fragment() {
	if(UV.x == -1.0 && UV.y == -1.0) 
	{
		discard;
	}
	vec4 albedo_tex = texture(texture_albedo,base);
	
	ALBEDO = albedo_tex.rgb;
	ALPHA=albedo_tex.a;

	ALBEDO *= fontColor.rgb;

	//黑色外包框效果不佳
	if(eq(ALBEDO,BLACK))
		ALBEDO += outLineColor.xyz;
	
}