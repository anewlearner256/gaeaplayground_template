shader_type spatial;
render_mode depth_test_disable,unshaded;

uniform sampler2D value_texture : hint_black; // hint_normal
uniform sampler2D color_segmentation;
uniform vec4 lines_color : hint_color;
uniform int display_type = 0;

varying smooth vec3 out_color;

void vertex() {
	// UV记录value_texture的取值
	if(display_type == 1){ // Triangles
		vec3 value_rgb = texture(value_texture,UV).rgb;
		
		if(value_rgb == vec3(0.0)) {
			out_color = vec3(0.0);
		}
		else if(value_rgb.b == 1.0 && value_rgb.g == 0.0) {
			out_color = vec3(0.0);
		}
		else if(value_rgb.g == 1.0 && value_rgb.b == 0.0) { 
			out_color = texture(color_segmentation,vec2(0.9999,0)).rgb; // 取值为1.0 网页端不显示
		}
		else 
			out_color = texture(color_segmentation,vec2(value_rgb.r,0)).rgb;
		
//		out_color = value_rgb;
	}
	else { // Lines
		out_color = lines_color.rgb;
	}
}

void fragment(){
	if(out_color == vec3(0.0)){
		discard;
	}
	else {
		ALBEDO = out_color;
//		ALBEDO = mix(pow((out_color+ vec3(0.055)) * (1.0 / (1.0 + 0.055)),vec3(2.4)),out_color * (1.0 / 12.92),lessThan(out_color,vec3(0.04045)));
	}
}