shader_type spatial;
render_mode depth_draw_alpha_prepass,unshaded,cull_back,depth_test_disable;
uniform sampler2D texture_albedo : hint_albedo;
uniform sampler2D icon_texture_albedo : hint_albedo;
uniform float distance_to_center;


uniform int check_test; // 1表示文本，0表示图标
uniform float test_size;
uniform float icon_size;
uniform float alpha;
uniform vec4 hoverColor;
uniform vec4 hitColor;
uniform float boxsize;
uniform float chartexturesize;

varying float visible;
varying float col;
varying float row;
varying vec2 base;
varying vec4 screenposition;
varying float cnt;
varying float Color;
varying float alpha_show; 

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
	
	cnt = INSTANCE_CUSTOM.x / 10.;
	
	if(INSTANCE_CUSTOM.x == 0.) {
		visible = 0.0;
		return;
	}
	
	col = INSTANCE_CUSTOM.y;
	alpha_show = float(int(col * 10.0) % 10); // 判断是否需要淡入淡出 1出现 2消失
	float all_row = float(int(col) % 100);
	col = float(int(col) / 100);
	
	row = INSTANCE_CUSTOM.z;
	visible = float(int(row * 10.) % 10);
	float cur_row = float(int(row) % 100) + 1.;
	row = float(int(row) / 100);
	
	float word_space = float(int(INSTANCE_CUSTOM.w)) / 100.0;
	Color = float(int(INSTANCE_CUSTOM.w * 10.) % 10);
		
	if(Color == 2.0) {
		scale += 0.2f;
	}
	
	if(check_test == 1)
	{
		vec2 v; // 取文字
		if(UV.x == 0.0 && UV.y == 1.0) {
			v.x = (col - 1.0) * boxsize / chartexturesize;
			v.y = (row) * boxsize / chartexturesize;
		}
		else if(UV.x == 0.0 && UV.y == 0.0) {
			v.x = (col) * boxsize / chartexturesize;
			v.y = (row) * boxsize / chartexturesize;
		}
		else if(UV.x == 1.0 && UV.y == 0.0){
			v.x = (col) * boxsize / chartexturesize;
			v.y = (row + 1.0) * boxsize / chartexturesize;
		}
		else if(UV.x == 1.0 && UV.y == 1.0) {
			v.x = (col - 1.0) * boxsize / chartexturesize;
			v.y = (row + 1.0) * boxsize / chartexturesize;
		}
		base = v;
		
		
		if(visible == 1.0) {
			res.y -= (icon_size + test_size * 0.3) * scale ;
			res.y -= (all_row - cur_row) * test_size * scale;
			res.x -= (cnt / 2.0 - word_space) * scale;
		}
		else if(visible == 2.0){
			res.x += icon_size * scale;
			res.x += word_space * scale;
			res.y += (cur_row - (all_row / 2.0)) * test_size * scale - test_size / 2.0 * scale;
		} 
		else if(visible == 3.0) {
			res.y += icon_size * scale;
			res.y += (cur_row - 1.0) * test_size * scale;
			res.x -= (cnt / 2.0 - word_space) * scale;
		}
		else if(visible == 4.0){
			res.x -= icon_size * scale;
			res.x -= (cnt - word_space) * scale;
			res.y += (cur_row - (all_row / 2.0)) * test_size * scale - test_size / 2.0 * scale;
		}
		
		if((UV.x == 0.0 && UV.y == 1.0) || (UV.x == 1.0 && UV.y == 1.0)) {
			res.x += (-0.5 * test_size * scale); // 设置X轴方向上的宽度
		}
		else {
			res.x += (0.5 * test_size * scale);
		}
		
		if((UV.x == 0.0 && UV.y == 1.0) || (UV.x == 0.0 && UV.y == 0.0)) {
			res.y += (-0.5 * test_size * scale);
		}
		else {
			res.y += 0.5 * test_size * scale;
		}
		
	}
	else if(check_test == 0){
		if((UV.x == 0.0 && UV.y == 1.0) || (UV.x == 1.0 && UV.y == 1.0)) {
			res.x += (-0.5 * icon_size * scale); // 设置X轴方向上的宽度
		}
		else {
			res.x += 0.5 * icon_size * scale;
		}
		
		if((UV.x == 0.0 && UV.y == 1.0) || (UV.x == 0.0 && UV.y == 0.0)) {
			res.y += (-0.5 * icon_size * scale);
		}
		else {
			res.y += 0.5 * icon_size * scale;
		}

		vec2 tempUV = UV;
		
		UV.x =  - (tempUV.y - 0.5) * sin(3.1415926 / 2.0) + 0.5;
		UV.y = (tempUV.x - 0.5) * sin(3.1415926 / 2.0) + 0.5;
		base = UV;
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
	if((visible == 0.0) || (UV.x == -1.0 && UV.y == -1.0)) 
	{
		discard;
	}
	vec4 albedo_tex = texture(texture_albedo,base);
	if(Color == 2.0 && check_test == 0) albedo_tex = texture(icon_texture_albedo,base);
	
	ALBEDO = albedo_tex.rgb;
	ALPHA=albedo_tex.a;
//	if(alpha_show == 1.0) {
//		ALPHA *= alpha;
//	}
//	else if(alpha_show == 2.0) {
//		ALPHA *= 1.0 - alpha;
//	}
	
	// 字体模式下
	if(check_test == 1){
		ALBEDO *= fontColor.rgb;

//		if(cnt*10.0 == 192.) ALBEDO = vec3(1.,0,0);
//		else ALBEDO = vec3(0,1.,0);
		//黑色外包框效果不佳
		if(eq(ALBEDO,BLACK))
			ALBEDO += outLineColor.xyz;
//		ALBEDO *= COLOR.xyz;
	}
	
	if(Color == 1.0) {
		ALBEDO *= hoverColor.rgb;
	}
	else if(Color == 2.0 && check_test == 1)
	{
		ALBEDO *= hitColor.rgb;
	}
//	float d = DEPTH;
	
//	DEPTH += 0.001;
//	ALPHA *= 0.1f;
}