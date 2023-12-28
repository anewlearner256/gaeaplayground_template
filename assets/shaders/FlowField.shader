shader_type spatial;
uniform float colortransIndex = 0;
uniform float colortransLength = 59;
uniform float emissionPower = 2.0;
void fragment(){
	ALBEDO = vec3(COLOR.rgb);

	float per = float(1) / colortransLength;
	float tmp = UV2.x + colortransIndex;
	while(tmp > colortransLength)
		tmp -= colortransLength;
	float cc =  (UV.y - UV.x) / UV.y + tmp * per;
	if(cc > float(1))
	{
		cc -= float(1);
	}
	ALPHA = 1.0 - cc;
	EMISSION = ALBEDO * emissionPower;
}