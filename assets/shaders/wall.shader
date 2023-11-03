shader_type spatial;
render_mode cull_disabled;


uniform vec4 wallColor;

uniform sampler2D wallTex;
uniform bool hasWallTex = false;

void vertex(){
}

void fragment(){
	ALBEDO = wallColor.rgb;
    
	vec3 vertex = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	vec3 camera = (INV_CAMERA_MATRIX * vec4(CAMERA_RELATIVE_POS)).xyz;
	vec3 view = normalize(VERTEX - camera);
	float fresnel = sqrt(1.0 - dot(NORMAL, normalize(vertex)));
	
	//ALBEDO = mix(vec3(0,0,0), vec3(1,1,1), fract(UV2.x) );
	ROUGHNESS = 1.0;
//	ALBEDO =  mix( mix( vec3(.4,.2,.0), vec3(1,1,1), fract(UV2.x)),
//				mix( vec3(0.0,.2,.6), vec3(0,0,0), fract(UV2.x) ),
//				fract(UV2.x));
//	if(fract(UV.y * 10.0) > 0.4)
//	{
//
//		ALBEDO =  mix( mix( vec3(0.0823, 0.65, 0.96), vec3(1,1,1), fract(UV2.x)),
//					   mix( vec3(0.3, 0.2, 0.6), vec3(0,0,0), fract(UV2.x) ),
//					   fract(UV2.x));
//		ROUGHNESS = 0.01 * (1.0 - fresnel);
//		//ALBEDO = vec3(1, 0, 0);
//  		//METALLIC = 1.0;
//		SPECULAR = 1.0;
//	}

	
  	//ROUGHNESS = 0.01;
	
//	ALBEDO = mix( vec3(.85,1.0,1.2), ALBEDO, exp(-1.0*.02) );
	if(hasWallTex)
	{
		vec3 tex = texture(wallTex, mod(UV, 1.0)).xyz;
//		tex.x = 1.0 / (1.0 + exp(-0.5 * (tex.x * 20.0 - 10.0)));
//		tex.y = 1.0 / (1.0 + exp(-0.5 * (tex.y * 20.0 - 10.0)));
//		tex.z = 1.0 / (1.0 + exp(-0.5 * (tex.z * 20.0 - 10.0)));
		ALBEDO = tex.xyz;
	}
	ALPHA = wallColor.a;
//	else
//	{
//		ALBEDO = vec3(1, 1, 1);
//	}
}