shader_type spatial;

render_mode unshaded;

uniform vec4 skyline_color:hint_color;
uniform float line_width;
uniform bool visible;

void vertex() {
	POSITION = vec4(VERTEX.xy,-1.0, 1.0);
}

void fragment() {
	if(!visible) discard;
	vec3 color = texture(SCREEN_TEXTURE,SCREEN_UV).xyz;
	float col0 = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	float col1 = texture(DEPTH_TEXTURE, SCREEN_UV + vec2(0.0, 1.0/VIEWPORT_SIZE.y*line_width)).x;
	float col2 = texture(DEPTH_TEXTURE, SCREEN_UV + vec2(0.0, -1.0/VIEWPORT_SIZE.y*line_width)).x;
	float col3 = texture(DEPTH_TEXTURE, SCREEN_UV + vec2(1.0/VIEWPORT_SIZE.x*line_width, 0.0)).x;
	float col4 = texture(DEPTH_TEXTURE, SCREEN_UV + vec2(-1.0/VIEWPORT_SIZE.x*line_width, 0.0)).x;
	float col5 = texture(DEPTH_TEXTURE, SCREEN_UV + vec2(1.0/VIEWPORT_SIZE.x*line_width,1.0/VIEWPORT_SIZE.y*line_width)).x;
	float col6 = texture(DEPTH_TEXTURE, SCREEN_UV + vec2(-1.0/VIEWPORT_SIZE.x*line_width,-1.0/VIEWPORT_SIZE.y*line_width)).x;
	float col7 = texture(DEPTH_TEXTURE, SCREEN_UV + vec2(-1.0/VIEWPORT_SIZE.x*line_width,1.0/VIEWPORT_SIZE.y*line_width)).x;
	float col8 = texture(DEPTH_TEXTURE, SCREEN_UV + vec2(1.0/VIEWPORT_SIZE.x*line_width,-1.0/VIEWPORT_SIZE.y*line_width)).x;

	if(col0==1.0){
		if(col1<1.0||col2<1.0||col3<1.0||col4<1.0||col5<1.0||col6<1.0||col7<1.0||col8<1.0){
			ALBEDO.rgb=skyline_color.rgb;
		}
		else{
			discard;
		}
	}
	else {
		discard;
	}
}