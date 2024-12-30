shader_type spatial;
render_mode cull_disabled,unshaded,depth_draw_always;

uniform sampler2D value_texture0 : hint_black; // 值图
uniform sampler2D value_texture1 : hint_black;
uniform sampler2D value_texture2 : hint_albedo; // 贴图
uniform sampler2D value_texture3 : hint_albedo;
uniform sampler2D color_segmentation;
uniform vec4 lines_color : hint_color;
uniform int display_type = 0; // 0 line模式，1 值图模式，2 值图推演模式， 3 贴图模式， 4 贴图推演模式
uniform float InterpolationValue : hint_range(0,1) = 0;
uniform bool UseUV1 = false;
uniform float alpha = 1.;
uniform bool srgb_to_linear = true;

varying flat vec4 color;

float TextureColor(sampler2D value_texture,vec2 uv){
	float SizeTextureX = float(textureSize(value_texture,0).x);
	float X = (uv.x + 0.5) / SizeTextureX;
	float Y = (uv.y + 0.5) / SizeTextureX;
	vec4 Location = texture(value_texture,vec2(X, Y));
	Location.rgb *= 255.;
	return (Location.r + Location.g * 100. + Location.b * 10000.) / 1000000.;
}

void vertex(){
	vec2 uv = UV2;
	if(UseUV1) uv = UV;
	if(display_type == 0){ // Lines
		color = lines_color;
	}
	else if(display_type == 1 || display_type == 2){ 
		// 值图   值图推演
		float colorUv = 0.;
		if(display_type == 1) {
			colorUv = TextureColor(value_texture0,uv);
		} 
		else if(display_type == 2){ // Triangles插值模式
			float Location0 = TextureColor(value_texture0,uv);
			float Location1 = TextureColor(value_texture1,uv);
			colorUv = (Location0 * (1. - InterpolationValue) + Location1 * InterpolationValue);
		}
		color = texture(color_segmentation,vec2(1.- colorUv,0.5));

	}
	else if(display_type == 3) {
		// 贴图
		color = texture(value_texture2,uv);
	}
	else if(display_type == 4) {
		// 贴图推演
		vec4 Location1 = texture(value_texture2,uv);
		vec4 Location2 = texture(value_texture3,uv);
		color = mix(Location1,Location2,InterpolationValue);
	}
}

void fragment(){
	
	ALBEDO = color.rgb;
	
	if(srgb_to_linear)
	{
		ALBEDO = mix(pow((ALBEDO + vec3(0.055)) * (1.0 / (1.0 + 0.055)),vec3(2.4)),ALBEDO * (1.0 / 12.92),lessThan(ALBEDO, vec3(0.04045)));
	}
	ALPHA = color.a * alpha;
}