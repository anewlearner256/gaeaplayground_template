shader_type spatial;
// render_mode cull_front;
render_mode blend_mix,depth_draw_always,cull_back;
uniform vec2 Origin;
uniform vec2 Span;

uniform bool useRollerBlind = false;
uniform vec2 splitline;
uniform int splitDirection1;
uniform int splitDirection2;
uniform int splitDirection3;
uniform int splitDirection4;
uniform int splitDirection5;
uniform int splitDirection6;
uniform int splitDirection7;

//全局透明
uniform float transparency;
//地形夸张
uniform float verticalExaggeration = 1.0;

uniform int pixelToHeightMode = 0;

uniform float tileTransparency = 1.0;
//服务图层
uniform int HasImg1;
uniform float transparency1=1.0;
uniform int HasImg2;
uniform float transparency2=1.0;
uniform int HasImg3;
uniform float transparency3=1.0;
uniform int HasImg4;
uniform float transparency4=1.0;
uniform int HasImg5;
uniform float transparency5=1.0;
uniform int HasImg6;
uniform float transparency6=1.0;
uniform int HasImg7;
uniform float transparency7=1.0;
uniform sampler2D Img1:hint_albedo;
uniform vec2 Img1Scale=vec2(1,1);
uniform vec2 Img1Offset=vec2(0,0);
uniform sampler2D Img2:hint_albedo;
uniform vec2 Img2Scale=vec2(1,1);
uniform vec2 Img2Offset=vec2(0,0);
uniform sampler2D Img3:hint_albedo;
uniform vec2 Img3Scale=vec2(1,1);
uniform vec2 Img3Offset=vec2(0,0);
uniform sampler2D Img4:hint_albedo;
uniform vec2 Img4Scale=vec2(1,1);
uniform vec2 Img4Offset=vec2(0,0);
uniform sampler2D Img5:hint_albedo;
uniform vec2 Img5Scale=vec2(1,1);
uniform vec2 Img5Offset=vec2(0,0);
uniform sampler2D Img6:hint_albedo;
uniform vec2 Img6Scale=vec2(1,1);
uniform vec2 Img6Offset=vec2(0,0);
uniform sampler2D Img7:hint_albedo;
uniform vec2 Img7Scale=vec2(1,1);
uniform vec2 Img7Offset=vec2(0,0);

varying vec2 BaseUV;
uniform vec2 BaseMapOrigin;
uniform vec2 BaseMapSpan;

//UV的缩放和偏移
uniform vec2 UVScale = vec2(1,1);
uniform vec2 UVScroll = vec2(0,0);

//基本图层
uniform int HasBaseMap1;
uniform vec3 BaseMap1InvalidColor;
uniform sampler2D BaseMap1;

uniform int HasBaseMap2;
uniform vec3 BaseMap2InvalidColor;
uniform sampler2D BaseMap2;

//地形图层
uniform int HasTerrainMap1;
uniform sampler2D TerrainMap1;
uniform vec2 TerrainMap1MaxMinValue;
uniform float TerrainMap1InvalidValue;

uniform int HasTerrainMap2;
uniform sampler2D TerrainMap2;
uniform vec2 TerrainMap2MaxMinValue;
uniform float TerrainMap2InvalidValue;

uniform bool IsOverlay = false;

//地形插值
uniform float TerrainMapInterpolationValue = -1.0;
//地形颜色
uniform bool openColor = false;
uniform vec2 colorRamp;

uniform int HasHole;  //有坑
//面一
uniform vec3 pointInface0;
uniform vec3 normal0;
//面二
uniform vec3 pointInface1;
uniform vec3 normal1;
//面三
uniform vec3 pointInface2;
uniform vec3 normal2;
//面四
uniform vec3 pointInface3;
uniform vec3 normal3;
//面五
uniform vec3 pointInface4;
uniform vec3 normal4;
//面六
uniform vec3 pointInface5;
uniform vec3 normal5;
//面七
uniform vec3 pointInface6;
uniform vec3 normal6;
//面八
uniform vec3 pointInface7;
uniform vec3 normal7;
//面九
uniform vec3 pointInface8;
uniform vec3 normal8;
//面十
uniform vec3 pointInface9;
uniform vec3 normal9;

varying mat4 modelViewMatrix_inv;

vec4 blendColor(vec4 srcColor, vec4 destColor)
{
	if(srcColor.a==1.0) {
		return srcColor;
	}
	return srcColor * srcColor.a + destColor * (1.0 - srcColor.a);
}


bool IsInPolygon(vec3 point)
{
	if(pointInface0 != vec3(0) && dot(point - pointInface0, normal0) > 0.0) 
	{
		return false;
	}
	if(pointInface1 != vec3(0) && dot(point - pointInface1, normal1) > 0.0) 
	{
		return false;
	}
	if(pointInface2 != vec3(0) && dot(point - pointInface2, normal2) > 0.0) 
	{
		return false;
	}
	if(pointInface3 != vec3(0) && dot(point - pointInface3, normal3) > 0.0) 
	{
		return false;
	}
	if(pointInface4 != vec3(0) && dot(point - pointInface4, normal4) > 0.0) 
	{
		return false;
	}
	if(pointInface5 != vec3(0) && dot(point - pointInface5, normal5) > 0.0) 
	{
		return false;
	}
	if(pointInface6 != vec3(0) && dot(point - pointInface6, normal6) > 0.0) 
	{
		return false;
	}
	if(pointInface7 != vec3(0) && dot(point - pointInface7, normal7) > 0.0) 
	{
		return false;
	}
	if(pointInface8 != vec3(0) && dot(point - pointInface8, normal8) > 0.0) 
	{
		return false;
	}
	if(pointInface9 != vec3(0) && dot(point - pointInface9, normal9) > 0.0) 
	{
		return false;
	}
	return true;
}

float pixelToHeight(float pixel, vec2 valueMaxMin)
{
	if(pixelToHeightMode == 0)
	{
		return (valueMaxMin.x + (pixel) * (valueMaxMin.y - valueMaxMin.x));
	}
	else if(pixelToHeightMode == 1)
	{
		return pixel * 255.0;
	}
}
void vertex()
{	
	modelViewMatrix_inv = inverse(MODELVIEW_MATRIX);
	float absoluteLon = (Origin.x + UV.x * Span.x); // 绝对经度
	float absoluteLat = (Origin.y - UV.y * Span.y); // 绝对纬度
	BaseUV.x = (absoluteLon - BaseMapOrigin.x) / BaseMapSpan.x; // 相对于BaseMap1的UV
	BaseUV.y = (-absoluteLat +  BaseMapOrigin.y) / BaseMapSpan.y;

	vec3 pos = VERTEX.xyz;
	vec3 pos1 = VERTEX.xyz;
	vec3 pos2 = VERTEX.xyz;
	
	if(HasTerrainMap1 == 1 && HasTerrainMap2 == 1 && TerrainMapInterpolationValue != -1.0)
	{
		float height = 0.0;
		float height2 = 0.0;
		if(BaseUV.x <= 1.0 && BaseUV.x >= 0.0 && BaseUV.y <= 1.0 && BaseUV.y >= 0.0)
		{
			vec4 pixel1 = texture(TerrainMap1, BaseUV);
			vec4 pixel2 = texture(TerrainMap2, BaseUV);
			pixel1 = clamp(pixel1, vec4(0), vec4(1));
			pixel2 = clamp(pixel2, vec4(0), vec4(1));
			height = pixelToHeight(pixel1.x, TerrainMap1MaxMinValue);
			if(abs(pixel1.a - 0.0) > 0.1 && height != TerrainMap1InvalidValue)
			{
				pos1 = VERTEX.xyz +  height * NORMAL * verticalExaggeration;
				
			}
			
			height2 = pixelToHeight(pixel2.x, TerrainMap2MaxMinValue);
			if(abs(pixel2.a - 0.0) > 0.1&& height2 != TerrainMap2InvalidValue)
			{
				pos2 = VERTEX.xyz +  height2 * NORMAL * verticalExaggeration;
			}
		}
		VERTEX.xyz = pos1 * TerrainMapInterpolationValue + pos2 * (1.0 - TerrainMapInterpolationValue);
	}
	else
	{
		if(HasTerrainMap1 == 1) 
		{
			if(BaseUV.x <= 1.0 && BaseUV.x >= 0.0 && BaseUV.y <= 1.0 && BaseUV.y >= 0.0)
			{
				vec4 pixel = texture(TerrainMap1, BaseUV);
				pixel = clamp(pixel, vec4(0), vec4(1));
				float height = pixelToHeight(pixel.x, TerrainMap1MaxMinValue);
				if(abs(pixel.a - 0.0) > 0.1 && height != TerrainMap1InvalidValue)
				{ 
					pos = VERTEX.xyz + height * NORMAL * verticalExaggeration;
					VERTEX.xyz = pos;
				}
				//				if(height != TerrainMap1InvalidValue)
				//				{
					//					pos = VERTEX.xyz - (TerrainMap1MaxMinValue.y - height) * NORMAL * verticalExaggeration;
					//					VERTEX.xyz = pos;
				//				}
			}
		}
		
		if(HasTerrainMap2 == 1) 
		{
			vec4 pixel = texture(TerrainMap2, BaseUV);
			pixel = clamp(pixel, vec4(0), vec4(1));
			float height = pixelToHeight(pixel.x, TerrainMap2MaxMinValue);
			if(abs(pixel.a - 0.0) > 0.1 && height != TerrainMap2InvalidValue)
			{ 
				pos = VERTEX.xyz + height * NORMAL * verticalExaggeration;
				VERTEX.xyz = pos;
			}
		}
	}
	UV = UVScroll + UV  * UVScale;
}

void fragment()
{
	ALBEDO = vec3(1,0,0);
	float t1 = transparency1;
	float t2 = transparency2;
	float t3 = transparency3;
	float t4 = transparency4;
	float t5 = transparency5;
	float t6 = transparency6;
	float t7 = transparency7;

	if(HasHole == 1)
	{		
		vec3 LocalPos = (modelViewMatrix_inv*vec4(VERTEX,1)).xyz;
		if(IsInPolygon(LocalPos))
		{		
			discard;
		}
	}
	
	vec4 diffuse;
	if(HasImg1 == 1){
		vec2 uv = UV * Img1Scale + Img1Offset;
		if(useRollerBlind)
		{
			if(splitDirection1==1)
			{
				if(SCREEN_UV.x > splitline.x)
				{
					t1 = 0.0;
				}
			}
			else if(splitDirection1==2)
			{
				if(SCREEN_UV.x < splitline.x)
				{
					t1 = 0.0;
				}
			}
			diffuse = blendColor(texture(Img1, uv) * t1, diffuse);
		}
		else
		{
			diffuse = blendColor(texture(Img1, uv) * transparency1, diffuse);
		}
		}else{
		diffuse = vec4(1, 1, 1, 0);
	}
	if(HasImg2 == 1) {
		vec2 uv = UV * Img2Scale + Img2Offset;
		if(useRollerBlind)
		{
			if(splitDirection2==1)
			{
				if(SCREEN_UV.x > splitline.x)
				{
					t2 = 0.0;
				}
			}
			else if(splitDirection2==2)
			{
				if(SCREEN_UV.x < splitline.x )
				{
					t2 = 0.0;
				}
			}
			diffuse = blendColor(texture(Img2, uv) * t2, diffuse);
		}
		else
		{
			diffuse = blendColor(texture(Img2, uv) * transparency2, diffuse);
		}
	}
	if(HasImg3 == 1) {
		vec2 uv = UV * Img3Scale + Img3Offset;
		if(useRollerBlind)
		{
			if(splitDirection3==1)
			{
				if(SCREEN_UV.x > splitline.x )
				{
					t3 = 0.0;
				}
			}
			else if(splitDirection3==2)
			{
				if(SCREEN_UV.x < splitline.x )
				{
					t3 = 0.0;
				}
			}
			diffuse = blendColor(texture(Img3, uv) * t3, diffuse);
		}
		else
		{
			diffuse = blendColor(texture(Img3, uv) * transparency3, diffuse);
		}
	}
	if(HasImg4 == 1) {
		vec2 uv = UV * Img4Scale + Img4Offset;
		if(useRollerBlind)
		{
			if(splitDirection4==1)
			{
				if(SCREEN_UV.x > splitline.x)
				{
					t4 = 0.0;
				}
			}
			else if(splitDirection4==2)
			{
				if(SCREEN_UV.x < splitline.x )
				{
					t4 = 0.0;
				}
			}
			diffuse = blendColor(texture(Img4, uv) * t4, diffuse);
		}
		else
		{
			diffuse = blendColor(texture(Img4, uv) * transparency4, diffuse);
		}
	}
	if(HasImg5 == 1) {
		vec2 uv = UV * Img5Scale + Img5Offset;
		if(useRollerBlind)
		{
			if(splitDirection5==1)
			{
				if(SCREEN_UV.x > splitline.x)
				{
					t5 = 0.0;
				}
			}
			else if(splitDirection5==2)
			{
				if(SCREEN_UV.x < splitline.x )
				{
					t5 = 0.0;
				}
			}
			diffuse = blendColor(texture(Img5, uv) * t5, diffuse);
		}
		else
		{
			diffuse = blendColor(texture(Img5, uv) * transparency5, diffuse);
		}
	}
	if(HasImg6 == 1) {
		vec2 uv = UV * Img6Scale + Img6Offset;
		if(useRollerBlind)
		{
			if(splitDirection6==1)
			{
				if(SCREEN_UV.x > splitline.x)
				{
					t6 = 0.0;
				}
			}
			else if(splitDirection6==2)
			{
				if(SCREEN_UV.x < splitline.x )
				{
					t6 = 0.0;
				}
			}
			diffuse = blendColor(texture(Img6, uv) * t6, diffuse);
		}
		else
		{
			diffuse = blendColor(texture(Img6, uv) * transparency6, diffuse);
		}
	}
	if(HasImg7== 1) {
		vec2 uv = UV * Img7Scale + Img7Offset;
		if(useRollerBlind)
		{
			if(splitDirection7==1)
			{
				if(SCREEN_UV.x > splitline.x )
				{
					t7 = 0.0;
				}
			}
			else if(splitDirection7==2)
			{
				if(SCREEN_UV.x < splitline.x )
				{
					t7 = 0.0;
				}
			}
			diffuse = blendColor(texture(Img7, uv) * t7, diffuse);
		}
		else
		{
			diffuse = blendColor(texture(Img7, uv) * transparency7, diffuse);
		}
	}

	if(openColor && HasTerrainMap1 == 1 && HasTerrainMap2 == 1 && TerrainMapInterpolationValue != -1f)
	{
		if(BaseUV.x <= 1.0 && BaseUV.x >= 0.0 && BaseUV.y <= 1.0 && BaseUV.y >= 0.0)
		{
			float height1 = texture(TerrainMap1, BaseUV).x;
			float height2 = texture(TerrainMap2, BaseUV).x;
			float a = 1f;
			if(height2 == height1)
			a = 0f;
			float terrainMapMinValue = TerrainMap1MaxMinValue.x;
			if(terrainMapMinValue > TerrainMap2MaxMinValue.x)
			terrainMapMinValue = TerrainMap2MaxMinValue.x;
			float terrainMapMaxValue = TerrainMap1MaxMinValue.y;
			if(terrainMapMaxValue < TerrainMap2MaxMinValue.y)
			terrainMapMinValue = TerrainMap2MaxMinValue.y;
			float height = height1 * TerrainMapInterpolationValue + height2 * (1f - TerrainMapInterpolationValue);
			int gbr =  int((height - TerrainMap1MaxMinValue.x) / (TerrainMap2MaxMinValue.y - TerrainMap1MaxMinValue.x) * (colorRamp.y - colorRamp.x) + colorRamp.x);
			int b = gbr / 256 / 256;
			int g = (gbr -  b * 256 * 256) / 256;
			int r = gbr -  b * 256 * 256 - g * 256;
			vec4 color = vec4(float(r)  / 255f, float(g) / 255f, float(b) / 255f, a);
			diffuse = blendColor(color, diffuse);
		}
	}
	else
	{
		if(HasBaseMap1 == 1) 
		{
			if(BaseUV.x <= 1.0 && BaseUV.x >= 0.0 && BaseUV.y <= 1.0 && BaseUV.y >= 0.0)
			{
				vec4 color = texture(BaseMap1, BaseUV);
				if(color.xyz == BaseMap1InvalidColor)
				{
					color.a = 0.0;
				}
				diffuse = blendColor(color, diffuse);
			}
		}
		else if(HasBaseMap1 == 2)
		{
			if(HasTerrainMap1 == 1 && HasTerrainMap2 == 1)
			{
				if(IsOverlay)
				{
					if(BaseUV.x <= 1.0 && BaseUV.x >= 0.0 && BaseUV.y <= 1.0 && BaseUV.y >= 0.0)
					{
						vec4 pixel1 = texture(TerrainMap1, BaseUV);
						vec4 pixel2 = texture(TerrainMap2, BaseUV);
						//						float height1 = pixelToHeight(pixel1.x, TerrainMap1MaxMinValue);
						//						float height2 = pixelToHeight(pixel2.x, TerrainMap2MaxMinValue);
						
						vec2 uv1 = vec2(0.5, pixel1.x);
						vec2 uv2 = vec2(0.5, pixel2.x);
						uv1 = clamp(uv1, vec2(0.5, 0.01), vec2(0.5, 0.99));
						uv2 = clamp(uv2, vec2(0.5, 0.01), vec2(0.5, 0.99));
						vec4 color1 = texture(BaseMap1, uv1);
						vec4 color2 = texture(BaseMap2, uv2);
						if(abs(pixel1.a - 0.0) < 0.01)
						{
							color1.a = 0.0;
						}
						if(abs(pixel2.a - 0.0) < 0.01)
						{
							color2.a = 0.0;
						}
						if(abs(color2.a - 0.0) < 0.01)
						{
							diffuse = blendColor(color1, diffuse);
						}
						else
						{
							diffuse = blendColor(color2, diffuse);
						}
					}
				}
				else
				{
					if(BaseUV.x <= 1.0 && BaseUV.x >= 0.0 && BaseUV.y <= 1.0 && BaseUV.y >= 0.0)
					{
						vec4 pixel1 = texture(TerrainMap1, BaseUV);
						vec4 pixel2 = texture(TerrainMap2, BaseUV);
						float height1 = pixelToHeight(pixel1.x, TerrainMap1MaxMinValue);
						float height2 = pixelToHeight(pixel2.x, TerrainMap1MaxMinValue);
						
						float height = height1 * TerrainMapInterpolationValue + height2 * (1f - TerrainMapInterpolationValue);
						vec2 uv = vec2(0.5, 1.0 - (height - TerrainMap1MaxMinValue.x)/ (TerrainMap1MaxMinValue.y - TerrainMap1MaxMinValue.x));
						uv = clamp(uv, vec2(0.5, 0.01), vec2(0.5, 0.99));
						vec4 color = texture(BaseMap1, uv);
						if(height == TerrainMap1InvalidValue)
						{
							color.a = 0.0;
						}
						if(pixel1.a == 0.0 && pixel2.a == 0.0)
						{
							color.a = pixel1.a;
						}
						
						diffuse = blendColor(color, diffuse);
					}
				}
				
				
				
				
			}
			else
			{
				if(BaseUV.x <= 1.0 && BaseUV.x >= 0.0 && BaseUV.y <= 1.0 && BaseUV.y >= 0.0)
				{
					vec4 pixel = texture(TerrainMap1, BaseUV);
					float height = pixelToHeight(pixel.x, TerrainMap1MaxMinValue);

					vec2 uv = vec2(0.5, pixel.x);
					uv = clamp(uv, vec2(0.5, 0.01), vec2(0.5, 0.99));
					
					vec4 color = texture(BaseMap1, uv);
					if(abs(pixel.a - 0.0) < 0.01)
					{
						color.a = pixel.a;
					}
					
					if(height == TerrainMap1InvalidValue)
					{
						color.a = 0.0
					}
					
					

					diffuse = blendColor(color, diffuse);
				}
			}
			
			
		}
		if(HasBaseMap2 == 1) 
		{
			if(BaseUV.x <= 1.0 && BaseUV.x >= 0.0 && BaseUV.y <= 1.0 && BaseUV.y >= 0.0)
			{
				vec4 color = texture(BaseMap2, BaseUV);
				if(color.xyz == BaseMap2InvalidColor)
				{
					color.a = 0.0
				}
				diffuse = blendColor(color, diffuse);
			}
		}
	}

	ALBEDO = diffuse.rgb;
//	ALPHA = tileTransparency;
	ROUGHNESS = 0.7;
	METALLIC = 0.5;
	SPECULAR = 0.1;
	
	if( HasImg7 != 1 && 
	HasImg6 != 1 && 
	HasImg5 != 1 && 
	HasImg4 != 1 && 
	HasImg3 != 1 && 
	HasImg2 != 1 && 
	HasImg1 != 1){
		discard;
	}
}
