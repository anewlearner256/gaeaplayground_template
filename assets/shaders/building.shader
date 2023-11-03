shader_type spatial;
render_mode cull_disabled;
uniform sampler2D lengthTex;
uniform sampler2D tex;

float rand(vec2 n) {
  return fract(sin((n.x * 1e2 + n.y * 1e4 + 1475.4526) * 1e-4) * 1e6);
}

float noise(vec2 p)
{
    p = floor(p*200.0);
	return rand(p);
}

vec3 textureWall(vec2 pos, vec2 maxPos, vec2 squarer,float s,float height,float dist,vec3 rayDir,vec3 norm){
    float randB = rand(squarer*2.0);
    vec3 windowColor =(-0.4+randB*0.8)*vec3(0.3,0.3,0.0)+(-0.4+fract(randB*10.0)*0.8)*vec3(0.0,0.0,0.3)+(-0.4+fract(randB*10000.0)*0.8)*vec3(0.3,0.0,0.0);
    float floorFactor = 1.0;
    vec2 windowSize = vec2(0.65,0.35);
    vec3 wallColor = s*(0.3+1.4*fract(randB*100.0))*vec3(0.1,0.1,0.1)+(-0.7+1.4*fract(randB*1000.0))*vec3(0.02,0.,0.);
	wallColor*=1.3;
    
    vec3 color = vec3(0.0);
    vec3 conturColor = wallColor/1.5;
    if (height<0.51){
    	windowColor += vec3(0.3,0.3,0.0);
        windowSize = vec2(0.4,0.4);
        floorFactor = 0.0;

    }
    if (height<0.6){floorFactor = 0.0;}
    if (height>0.75){
    	windowColor += vec3(0.0,0.0,0.3);
    }
    windowColor*=1.5;
    float wsize = 0.02;
    wsize+=-0.007+0.014*fract(randB*75389.9365);
    windowSize+= vec2(0.34*fract(randB*45696.9365),0.50*fract(randB*853993.5783));
    
    vec2 contur=vec2(0.0)+(fract(maxPos/2.0/wsize))*wsize;
    if (contur.x<wsize){contur.x+=wsize;}
    if (contur.y<wsize){contur.y+=wsize;}
    
	vec2 winPos = (pos-contur)/wsize/2.0-floor((pos-contur)/wsize/2.0);
    
    float numWin = floor((maxPos-contur)/wsize/2.0).x;
    
    if ( (maxPos.x>0.5&&maxPos.x<0.6) && ( ((pos-contur).x>wsize*2.0*floor(numWin/2.0)) && ((pos-contur).x<wsize*2.0+wsize*2.0*floor(numWin/2.0)) )){
     	   return (0.9+0.2*noise(pos))*conturColor;
    }
    
    if ( (maxPos.x>0.6&&maxPos.x<0.7) &&( ( ((pos-contur).x>wsize*2.0*floor(numWin/3.0)) && ((pos-contur).x<wsize*2.0+wsize*2.0*floor(numWin/3.0)) )||
                                          ( ((pos-contur).x>wsize*2.0*floor(numWin*2.0/3.0)) && ((pos-contur).x<wsize*2.0+wsize*2.0*floor(numWin*2.0/3.0)) )) ){
     	   return (0.9+0.2*noise(pos))*conturColor;
    }
    
    if ( (maxPos.x>0.7) &&( ( ((pos-contur).x>wsize*2.0*floor(numWin/4.0)) && ((pos-contur).x<wsize*2.0+wsize*2.0*floor(numWin/4.0)) )||
                                          ( ((pos-contur).x>wsize*2.0*floor(numWin*2.0/4.0)) && ((pos-contur).x<wsize*2.0+wsize*2.0*floor(numWin*2.0/4.0)) )||
                                          ( ((pos-contur).x>wsize*2.0*floor(numWin*3.0/4.0)) && ((pos-contur).x<wsize*2.0+wsize*2.0*floor(numWin*3.0/4.0)) )) ){
     	   return (0.9+0.2*noise(pos))*conturColor;
    }
    if ((maxPos.x-pos.x<contur.x)||(maxPos.y-pos.y<contur.y+2.0*wsize)||(pos.x<contur.x)||(pos.y<contur.y)){
            return (0.9+0.2*noise(pos))*conturColor;
        
    }
    if (maxPos.x<0.14) {
     	   return (0.9+0.2*noise(pos))*wallColor;
    }
    vec2 window = floor((pos-contur)/wsize/2.0);
    float random = rand(squarer*s*maxPos.y+window);
    float randomZ = rand(squarer*s*maxPos.y+floor(vec2((pos-contur).y,(pos-contur).y)/wsize/2.0));
    float windows = floorFactor*sin(randomZ*5342.475379+(fract(975.568*randomZ)*0.15+0.05)*window.x);
	vec2 iResolution = vec2(1.0 / 1024.0, 1.0 / 600.0);
	float blH = 0.06*dist*600.0/iResolution.x/abs(dot(normalize(rayDir.xy),normalize(norm.xy)));
    float blV = 0.06*dist*600.0/iResolution.x/sqrt(abs(1.0-pow(abs(rayDir.z),2.0)));
    
	windowColor +=vec3(1.0,1.0,1.0);
    windowColor *= smoothstep(0.5-windowSize.x/2.0-blH,0.5-windowSize.x/2.0+blH,winPos.x);
   	windowColor *= smoothstep(0.5+windowSize.x/2.0+blH,0.5+windowSize.x/2.0-blH,winPos.x);
   	windowColor *= smoothstep(0.5-windowSize.y/2.0-blV,0.5-windowSize.y/2.0+blV,winPos.y);
   	windowColor *= smoothstep(0.5+windowSize.y/2.0+blV,0.5+windowSize.y/2.0-blV,winPos.y);
    
    if ((random <0.05*(3.5-2.5*floorFactor))||(windows>0.65)){
        	if (winPos.y<0.5) {windowColor*=(1.0-0.4*fract(random*100.0));}
        	if ((winPos.y>0.5)&&(winPos.x<0.5)) {windowColor*=(1.0-0.4*fract(random*10.0));}
            return (0.9+0.2*noise(pos))*wallColor+(0.9+0.2*noise(pos))*windowColor;


    } 
    else{
        windowColor*=0.08*fract(10.0*random);
    }
    
    return (0.9+0.2*noise(pos))*wallColor+windowColor;

}
void vertex()
{

}
void fragment()
{

	//ALBEDO = texture(tex, UV).xyz;

    float len = UV2.x; 
	vec2 windowSize = vec2(1.5, 1.5);
	vec2 dist = vec2(0.5, 0.5);
	float width = UV2.x / UV.x;
	float height = UV2.y / UV.y;
//    if(int(UV2.x / 5.0) % 2 == 0)
//    {
//        ALBEDO = vec3(1, 0, 0);
//    }
//	else
//	{
//		ALBEDO = vec3(0, 1, 0);
//	}


	float randB = 1.2;
	vec3 windowColor = vec3(0.2, 0.2, 0.3);
	vec3 wallColor = (0.3+1.4*fract(randB*100.0))*vec3(0.1,0.1,0.1)+(-0.7+1.4*fract(randB*1000.0))*vec3(0.02,0.,0.);
	
	int cols = int((width - 3.0) / (windowSize.x + 0.5));
	int rows = int((height - 3.0) / (windowSize.y + 0.5));
	
	float marginx = (width - float(cols) * (windowSize.x + 0.5)) / 2.0 + 0.25;
	float marginy = (height - float(rows) * (windowSize.y + 0.5)) / 2.0 + 0.25;
	bool HasLight1[20];
	bool HasLight2[20];
	int state = 123;
	int a = 67225;  // "乘数"
  	int b = 73828;  //"增量"
  	int m = 92233;  // "模数"
	for(int i = 0; i < HasLight1.length(); i++)
	{
		state = (state * a + b) % m;
		HasLight1[i] = float(state) / float(m) > 0.5;
	}
	for(int i = 0; i < HasLight2.length(); i++)
	{
		state = (state * a + b) % m;
		state = (state * a + b) % m;
		HasLight2[i] = float(state) / float(m) > 0.5;
	}
	if(UV2.x >= marginx && UV2.x <= width - marginx && UV2.y < height - marginy && UV2.y > marginy)
	{
		vec2 posInWindow = mod(UV2 - vec2(marginx, marginy), vec2(dist.x + windowSize.x, dist.y + windowSize.y));
		float col = ((UV2.x - marginx) / (dist.x + windowSize.x));
		float row = ((UV2.y - marginy) / (dist.y + windowSize.y));
		if(posInWindow.x <= 1.5 && posInWindow.y <= 1.5)
		{
			if(HasLight1[int(mod(col, 20))] && HasLight2[int(mod(row, 20))])
				ALBEDO = (0.9 + 0.5 * noise(posInWindow / 50.0)) * windowColor * 4.0;
			else
			   	ALBEDO = (0.9 + 0.5 * noise(posInWindow / 50.0)) * windowColor * 0.08;
		}
		else
		{
			ALBEDO =(0.9 + 0.5 * noise(UV2 / 10.0)) *  wallColor;
		}
	}
	else
	{
		ALBEDO = (0.9 + 0.5 * noise(UV2 / 10.0)) *  wallColor;
	}
}