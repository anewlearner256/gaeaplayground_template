shader_type spatial;
uniform float colortransIndex = 0;//移动步长
uniform float colortransLength = 100;//总步长
uniform float visiblePer = 0.0;//显示百分比
uniform float emissionPower = 2.0;
void fragment(){
	ALBEDO = vec3(COLOR.rgb);

	float per = float(1) / colortransLength;
	float tmp = UV2.x + colortransIndex;
	while(tmp > colortransLength)
		tmp -= colortransLength;
	float cc =  (UV.y - UV.x) / UV.y + tmp * per;
	while(cc > 1.0)
		cc -= 1.0;

	float visible = visiblePer;
	if(UV2.y >= 0.0)
		visible = UV2.y;

		if(cc < visible)
			ALPHA = 0.0;
		else
			ALPHA = 1.0 - (cc  - visible) /  (1.0  - visible );
		
	EMISSION = ALBEDO * (emissionPower * ALPHA);
}