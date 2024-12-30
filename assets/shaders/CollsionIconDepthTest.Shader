shader_type spatial;
render_mode depth_draw_alpha_prepass,unshaded,cull_back,depth_test_disable;
uniform sampler2D texture_albedo : hint_albedo;
uniform sampler2D icon_texture_albedo : hint_albedo;
uniform float distance_to_center;

uniform int text_mode; // 1表示文本，0表示图标
uniform bool use_merged_textures = false;
uniform float text_size;
uniform float icon_size;
uniform float alpha;
uniform vec4 hoverColor;
uniform vec4 hitColor;
uniform float boxsize;
uniform float chartexturesize;
uniform vec2 screenOffset = vec2(0);
uniform bool depthTestDisable = false;

varying float visible;
varying vec2 base;
varying vec4 screenposition;
varying float meshId;
varying flat vec2 Depth_UV;

const float PI = 3.14159265358979323846;

uniform bool userollerblind = false;
uniform vec2 splitline;
uniform int splitdirection;

uniform bool srgb_to_linear = true;

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
	
//	if(p3.x<-1.0||p3.x>1.0||p3.y<-1.0||p3.y>1.0||p3.z<-1.0||p3.z>1.0) {
//		UV = vec2(-1.0,-1.0);
//		return ;
//	}
	
	vec2 res;
	
	res.x=(p3.x * 0.5 + 0.5) * VIEWPORT_SIZE.x;
	res.y=(-p3.y * 0.5 + 0.5) * VIEWPORT_SIZE.y;
	
	Depth_UV.x = (p3.x * 0.5 + 0.5);
	Depth_UV.y = (p3.y * 0.5 + 0.5);
	
	// 小于等于4表示点碰撞，否则为沿线标注
	visible = float(int(round(INSTANCE_CUSTOM.z * 10.)) % 10); 
	if(visible <= 0.0) return;
	
	float textureSize1 = 0.015625f;

	if(visible <= 4.) {
		float cnt = float(int(INSTANCE_CUSTOM.x / 100.));

		float col = float(int(round(INSTANCE_CUSTOM.x * 10.)) % 100);
		float all_row = float(int(round(INSTANCE_CUSTOM.w * 10f)) % 100);
		
		float row = INSTANCE_CUSTOM.z;
		
		float cur_row = float(int(row) % 100) + 1.;
		row = float(int(row) / 100);
		float word_space = float(int(INSTANCE_CUSTOM.w / 10f)) / 10.0;
		meshId = INSTANCE_CUSTOM.y;
		
		if(text_mode == 1)
		{
			
			vec2 v; // 取文字
			if(UV.x == 0.0 && UV.y == 1.0) {
				v.x = (col - 1.0) * textureSize1;
				v.y = (row) * textureSize1;
			}
			else if(UV.x == 0.0 && UV.y == 0.0) {
				v.x = (col) * textureSize1;
				v.y = (row) * textureSize1;
			}
			else if(UV.x == 1.0 && UV.y == 0.0){
				v.x = (col) * textureSize1;
				v.y = (row + 1.0) * textureSize1;
			}
			else if(UV.x == 1.0 && UV.y == 1.0) {
				v.x = (col - 1.0) * textureSize1;
				v.y = (row + 1.0) * textureSize1;
			}
			base = v;
			
			
			if(visible == 1.0) {
				res.y -= icon_size * scale ;
				res.y -= (all_row - cur_row) * text_size * scale;
				res.x -= (cnt / 2.0 - word_space) * scale;
			}
			else if(visible == 2.0){
				res.x += (icon_size - text_size * 0.4) * scale;
				res.x += word_space * scale;
				res.y += (cur_row - (all_row / 2.0)) * text_size * scale - text_size / 2.0 * scale;
			} 
			else if(visible == 3.0) {
				res.y += icon_size * scale;
				res.y += (cur_row - 1.0) * text_size * scale;
				res.x -= (cnt / 2.0 - word_space) * scale;
			}
			else if(visible == 4.0){
				res.x -= (icon_size - text_size * 0.4) * scale;
				res.x -= (cnt - word_space) * scale;
				res.y += (cur_row - (all_row / 2.0)) * text_size * scale - text_size / 2.0 * scale;
			}
			
			
			if((UV.x == 0.0 && UV.y == 1.0) || (UV.x == 1.0 && UV.y == 1.0)) {
				res.x += (-0.5 * text_size * scale); // 设置X轴方向上的宽度
			}
			else {
				res.x += (0.5 * text_size * scale);
			}

			if((UV.x == 0.0 && UV.y == 1.0) || (UV.x == 0.0 && UV.y == 0.0)) {
				res.y += (-0.5 * text_size * scale);
			}
			else {
				res.y += 0.5 * text_size * scale;
			}
			
		}
		else if(text_mode == 0){
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
			if(!use_merged_textures)
			{
				vec2 tempUV = UV;
				UV.x =  -(tempUV.y - 0.5) * sin(PI / 2.0) + 0.5;
				UV.y = (tempUV.x - 0.5) * sin(PI / 2.0) + 0.5;
				base = UV;

			}
			else
			{
				float size = 0.01513671875; //62.0 / VIEWPORT_SIZE.x
				if(UV.x == 0.0 && UV.y == 0.0) {
					base = vec2(INSTANCE_CUSTOM.x + size, INSTANCE_CUSTOM.w);
				}
				else if(UV.x == 1.0 && UV.y == 0.0) {
					base = vec2(INSTANCE_CUSTOM.x + size, INSTANCE_CUSTOM.w + size);
				}
				else if(UV.x == 1.0 && UV.y == 1.0){
					base = vec2(INSTANCE_CUSTOM.x, INSTANCE_CUSTOM.w + size);
				}
				else if(UV.x == 0.0 && UV.y == 1.0) {
					base = vec2(INSTANCE_CUSTOM.x, INSTANCE_CUSTOM.w);
				}
				
			}
		}
		res += screenOffset;
	}
	else if(visible > 4.) {
		float ro = radians(45. - INSTANCE_CUSTOM.w); // UV2.x的范围 -45~45 之间
	
		float sideLength = text_size / 2.0 / cos(radians(45)); // 斜边长
		
		float col = INSTANCE_CUSTOM.x;
		float row = INSTANCE_CUSTOM.y;
		
		int flag = int(INSTANCE_CUSTOM.z); // 字体方向
		
		if(VERTEX.x == -0.05 && VERTEX.y == 0.05) {
			if(flag == 1) {
				base.x = (col) * textureSize1;
				base.y = (row) * textureSize1;
			}
			else if(flag == 2) {
				base.x = (col) * textureSize1;
				base.y = (row + 1.0) * textureSize1;
			}
			else if(flag == 3) {
				base.x = (col - 1.0) * textureSize1;
				base.y = (row + 1.0) * textureSize1;
			}
			else {
				base.x = (col - 1.0) * textureSize1;
				base.y = (row) * textureSize1;	
			}
			
			res.x += (sideLength * cos(ro) * scale);
			res.y += (-sideLength * sin(ro) * scale);
		}
		else if(VERTEX.x == 0.05 && VERTEX.y == 0.05) {
			if(flag == 1) {
				base.x = (col) * textureSize1;
				base.y = (row + 1.0) * textureSize1;
			}
			else if(flag == 2) {
				base.x = (col - 1.0) * textureSize1;
				base.y = (row + 1.0) * textureSize1;
			}
			else if(flag == 3) {
				base.x = (col - 1.0) * textureSize1;
				base.y = (row) * textureSize1;
			}
			else {
				base.x = (col) * textureSize1;
				base.y = (row) * textureSize1;
			}
			
			res.x += (sideLength * sin(ro) * scale);
			res.y += (sideLength * cos(ro) * scale);
		}
		else if(VERTEX.x == 0.05 && VERTEX.y == -0.05) {
			if(flag == 1) {
				base.x = (col - 1.0) * textureSize1;
				base.y = (row + 1.0) * textureSize1;
			}
			else if(flag == 2) {
				base.x = (col - 1.0) * textureSize1;
				base.y = (row) * textureSize1;	
			}
			else if(flag == 3) {
				base.x = (col) * textureSize1;
				base.y = (row) * textureSize1;
			}
			else {
				base.x = (col) * textureSize1;
				base.y = (row + 1.0) * textureSize1;
			}

			res.x += (-sideLength * cos(ro) * scale);
			res.y += (sideLength * sin(ro) * scale);
		}
		else if(VERTEX.x == -0.05 && VERTEX.y == -0.05){
			if(flag == 1) {
				base.x = (col - 1.0) * textureSize1;
				base.y = (row) * textureSize1;	
			}
			else if(flag == 2) {
				base.x = (col) * textureSize1;
				base.y = (row) * textureSize1;
			}
			else if(flag == 3) {
				base.x = (col) * textureSize1;
				base.y = (row + 1.0) * textureSize1;
			}
			else {
				base.x = (col - 1.0) * textureSize1;
				base.y = (row + 1.0) * textureSize1;
			}
			
			res.x += (-sideLength * sin(ro) * scale);
			res.y += (-sideLength * cos(ro) * scale);
		}
	}
	
	p3.x=res.x*2f/VIEWPORT_SIZE.x-1f;
	p3.y=1f-2f*res.y/VIEWPORT_SIZE.y;
	POSITION=vec4(p3,1.0);
}


uniform vec4 fontColor = vec4(1.0);
uniform vec4 outLineColor = vec4(0.0);
uniform vec3 BLACK = vec3(0.0);
uniform int Id = -1;

bool eq(vec3 c1,vec3 c2){
	float the = 0.3;
	// 设定阈值，确保选出所有白色进行修改
	return abs(c1.r-c2.r)<the &&
		abs(c1.g-c2.g)<the &&
		abs(c1.b-c2.b)<the;
}

void fragment() {
	// 通过取得深度图进行隐藏显示表示
	float depth = textureLod(DEPTH_TEXTURE, Depth_UV, 0.0).r; //Depth_UV SCREEN_UV
	vec3 ndc = vec3(Depth_UV, depth) * 2.0 - 1.0;
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    view.xyz /= view.w; // 世界坐标
	// 目前可能会被地形挡住，原因有
	// 1. 深度图距离越远越不准，
	// 2. 深度图采样不准，中心点计算问题
	
	float depthAlpha = 1.;
	
	if(depthTestDisable && VERTEX.z < view.z) {
		depthAlpha = (view.z - VERTEX.z) / 10. > 1. ? 0. : (view.z - VERTEX.z) / 10.;
	}
	
	if(visible <= 0.0 || (UV.x == -1.0 && UV.y == -1.0))
	{
		discard;
	}
	vec4 albedo_tex = texture(texture_albedo,base);

	ALBEDO = albedo_tex.rgb;
	ALPHA=albedo_tex.a * depthAlpha;

	// 字体模式下
	if(text_mode == 1){
		if(int(meshId) == Id && visible <= 4.) ALBEDO *= hoverColor.rgb;
//		else if(Color == 2.0) ALBEDO *= hitColor.rgb;
		else ALBEDO *= fontColor.rgb;

		//黑色外包框效果不佳
		if(eq(ALBEDO,BLACK))
			ALBEDO += outLineColor.xyz;

	}
	else {
		if(srgb_to_linear)
		{
			ALBEDO = mix(pow((ALBEDO + vec3(0.055)) * (1.0 / (1.0 + 0.055)),vec3(2.4)),ALBEDO * (1.0 / 12.92),lessThan(ALBEDO, vec3(0.04045)));
		}
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