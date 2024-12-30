shader_type spatial;
render_mode cull_disabled;
uniform float radius;
uniform vec4 color : hint_color = vec4(1, 0, 0, 1);
uniform vec4 icolor : hint_color = vec4(1, 0, 0, 1);
uniform bool isFlash = true;
uniform float flashSpeed = 1.0;
uniform float flashCycle = 1.0;
uniform bool isFadeEdges = false;
varying vec3 oVertex;
void vertex(){
	oVertex = VERTEX;
}

vec3 hsb2rgb(in vec3 c)
{
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix( vec3(1.0), rgb, c.y);
}


void fragment(){
	float dis = length(oVertex.xy);
	if(dis > radius)
	{
		discard;
	}
	ALBEDO = color.xyz;
	ALPHA = color.a;
	if(isFadeEdges)
	{
		ALPHA = max(smoothstep(radius, 0, dis), color.a);
	}
	if(isFlash)
	{
		float time = radius;
//		ALPHA = max(smoothstep(1, 0,  dis / radius + modf(TIME * flashSpeed, time)), color.a);
		ALPHA =  max((1.0 - dis / radius) * modf(TIME * flashSpeed, time), color.a);
//		ALPHA =  1.0 - dis / radius;
//		ALPHA =  min(1.0 - dis / radius, 1.0 - modf(TIME * flashSpeed, time));
	}
	


    
//    float r = length(oVertex.xy) * 0.2;
//	vec3 ocolor = icolor.xyz;
//
//    float a = pow(r, 2.0);
//    float b = sin(r * 0.8 - 1.6);
//    float c = sin(r - 0.010);
//    float s = sin(a - TIME * 3.0 + b) * c;
//
//    ocolor *= abs(1.0 / (s * 10.8)) - 0.01;
//	ALBEDO = mix(ocolor, color.xyz, 1.0 - ocolor.x);
//	ALPHA = color.a;


}