shader_type spatial;
render_mode cull_disabled,unshaded,blend_mix,shadows_disabled;
uniform sampler2D tex;
uniform float speed:hint_range(0.0,1.0) = 0.0;
uniform float grow = 0.25;

uniform float hitid=0.0;

void vertex(){
	VERTEX += NORMAL * grow;
}
void fragment(){
	if(abs(UV2.x - hitid) < 0.1){
		ALBEDO = vec3(0,1,0);
		ALPHA = 0.6;
	}else{
		discard;
	}
}