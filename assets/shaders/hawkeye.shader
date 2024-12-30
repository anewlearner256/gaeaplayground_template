// NOTE: Shader automatically converted from Gaea Explorer 4.0.stable.mono's CanvasItemMaterial.

shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D mapTex;
uniform vec2 cameraPosition;

uniform vec2 mapTexMinValue;
uniform vec2 mapTexMaxValue;
uniform vec2 mapTexShowMinValue;
uniform vec2 mapTexShowMaxValue;
uniform vec2 rectRange = vec2(10.0, 2.5);
uniform bool drawRect = true;

void fragment()
{
	ivec2 imgSize_i = textureSize(mapTex, 0);
	vec2 imgSize = vec2(float(imgSize_i.x), float(imgSize_i.y));
	vec2 mapRange = vec2(mapTexMaxValue - mapTexMinValue);
	vec2 resolution = vec2((mapTexShowMaxValue.x - mapTexShowMinValue.x) / imgSize.x, (mapTexShowMaxValue.y - mapTexShowMinValue.y) / imgSize.y);
	vec2 resolution_1 = 1.0 / resolution;
	
	vec2 uv = vec2(UV.x, 1.0 - UV.y);
	uv.x = mapTexShowMinValue.x + (mapTexShowMaxValue.x - mapTexShowMinValue.x) * uv.x;
	uv.y = mapTexShowMinValue.y + (mapTexShowMaxValue.y - mapTexShowMinValue.y) * uv.y;
	vec2 lonlat = uv;
	uv = (uv - mapTexMinValue) / mapRange;
	COLOR = texture(mapTex, vec2(uv.x, 1.0 - uv.y));
	if(drawRect)
	{
		if(abs(lonlat.x - cameraPosition.x) < rectRange.x && abs(lonlat.y - cameraPosition.y ) < rectRange.y)
		{
			COLOR = mix(COLOR, vec4(1, 0, 0, 0.9), 0.4);
		}
	}
	else
	{
		vec2 camPosOnMap = (cameraPosition - mapTexShowMinValue) / (mapTexShowMaxValue.x - mapTexShowMinValue.x);
		if(abs(UV.x - camPosOnMap.x) < rectRange.x && abs(1.0 - UV.y - camPosOnMap.y ) < rectRange.y)
		{
			COLOR = vec4(1, 0, 0, 1.0);
		}
		if(abs(UV.x - camPosOnMap.x) < rectRange.y && abs(1.0 - UV.y - camPosOnMap.y ) < rectRange.x)
		{
			COLOR = vec4(1, 0, 0, 1.0);
		}
	}
	
//	if(UV.y < 0.5)
//	{
//		COLOR = vec4(1, 0, 0, 1);
//	}
//	else
//	{
//		COLOR = vec4(0, 1, 0, 1);
//	}
//	COLOR = vec4(1, 0, 0, 1);
}
