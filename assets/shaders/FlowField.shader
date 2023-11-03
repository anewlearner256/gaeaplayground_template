shader_type spatial;
void vertex(){
	UV = vec2(UV.x,UV.y + TIME);
}
void fragment(){
	ALBEDO = vec3(COLOR.yzw);
	
	ALPHA = COLOR.x;
}