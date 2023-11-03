shader_type spatial;
render_mode cull_disabled,depth_test_disable;


uniform vec4 fillColor;

uniform sampler2D roofTex;
uniform bool hasRoofTex = false;
varying vec3 color;

void vertex(){
}

void fragment(){
	ALBEDO = fillColor.rgb;
	ROUGHNESS = 1.0;

	if(hasRoofTex)
	{
		vec3 tex = texture(roofTex, mod(UV, 1.0)).xyz;
		ALBEDO = tex.xyz;
	}
	ALPHA = fillColor.a;

}