shader_type canvas_item;

uniform vec2 size = vec2(256, 256);
//uniform vec2 grid_size = vec2(64, 64);
uniform float speed = 0.044;
uniform bool _IsTilable = true;
uniform vec3 _Evolution;
uniform int _FBMIteration = 1;
uniform float _Frequency = 4;
uniform float _RandomSeed = 4.0;
uniform float uv_scale = 1.0;
uniform float v1;
uniform float v2;
uniform float v3;

const vec3 MOD3 = vec3(0.1031,0.11369,0.13787);

const float F3 =  0.3333333;
const float G3 =  0.1666667;


vec3 hash33(vec3 p3, float gridCount)
{
	ivec3 ip3 = ivec3(p3);
	int count = int(gridCount);
	if(_IsTilable)
	{
		if(ip3.x == count)
    	{
        	p3.x = 0.0;
    	}
    	if(ip3.y == count)
    	{
        	p3.y = 0.0;
    	}
    	if(ip3.z == count)
    	{
        	p3.z = 0.0;
    	}
//		if(abs(p3.x - 8.0) < 0.1)
//		{
//			p3.x = 0.0;
//		}
//		if(abs(p3.y - 8.0) < 0.1)
//		{
//			p3.y = 0.0;
//		}
//		if(abs(p3.z - 8.0) < 0.1)
//		{
//			p3.z = 0.0;
//		}
	}
	
    
	p3 = fract(p3 * MOD3);
//	return vec3(p3);
    p3 += dot(p3, p3.yxz+19.19);
    return -1.0 + 2.0 * fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}
float perlin_noise(vec3 p, float gridCount)
{
    vec3 pi = floor(p);
    vec3 pf = p - pi;
    
    vec3 w = pf * pf * (3.0 - 2.0 * pf);
    
    return 	mix(
        		mix(
                	mix(dot(pf - vec3(0, 0, 0), hash33(pi + vec3(0, 0, 0), gridCount)), 
                        dot(pf - vec3(1, 0, 0), hash33(pi + vec3(1, 0, 0), gridCount)),
                       	w.x),
                	mix(dot(pf - vec3(0, 0, 1), hash33(pi + vec3(0, 0, 1), gridCount)), 
                        dot(pf - vec3(1, 0, 1), hash33(pi + vec3(1, 0, 1), gridCount)),
                       	w.x),
                	w.z),
        		mix(
                    mix(dot(pf - vec3(0, 1, 0), hash33(pi + vec3(0, 1, 0), gridCount)), 
                        dot(pf - vec3(1, 1, 0), hash33(pi + vec3(1, 1, 0), gridCount)),
                       	w.x),
                   	mix(dot(pf - vec3(0, 1, 1), hash33(pi + vec3(0, 1, 1), gridCount)), 
                        dot(pf - vec3(1, 1, 1), hash33(pi + vec3(1, 1, 1), gridCount)),
                       	w.x),
                	w.z),
    			w.y);
}


float noise(vec3 p, float gridCount) {
    return perlin_noise(p * 2.0, gridCount);
}

float noise_sum(vec3 p, float freq)
{
    float f = 0.0;
    p = p * freq;
    f += 1.0000 * (noise(p, freq * 2.0) + 1.0) / 2.0; p = 2.0 * p;
    f += 0.5000 * (noise(p, freq * 4.0) + 1.0) / 2.0; p = 2.0 * p;
	f += 0.2500 * (noise(p, freq * 8.0) + 1.0) / 2.0; p = 2.0 * p;
	f += 0.1250 * (noise(p, freq * 16.0) + 1.0) / 2.0; p = 2.0 * p;
	f += 0.0625 * (noise(p, freq * 32.0) + 1.0) / 2.0; p = 2.0 * p;
    
    return f;
}

float noise_sum_abs(vec3 p, float freq)
{
    float f = 0.0;
    p = p * freq;
    f += 1.0000 * abs(noise(p, freq * 2.0)); p = 2.0 * p;
    f += 0.5000 * abs(noise(p, freq * 2.0)); p = 2.0 * p;
	f += 0.2500 * abs(noise(p, freq * 2.0)); p = 2.0 * p;
	f += 0.1250 * abs(noise(p, freq * 2.0)); p = 2.0 * p;
	f += 0.0625 * abs(noise(p, freq * 2.0)); p = 2.0 * p;
    
    return f;
}

float lerp(float a, float b, float w)
{
  return a + w*(b-a);
}
float PerlinNoiseLerp(float l, float r, float t) {
    t = ((6.0 * t - 15.0) * t + 10.0) * t * t * t;
    return lerp(l, r, t);
}
vec3 GetRandom3To3_Raw(vec3 param, float randomSeed) {
    vec3 value;
    value.x = length(param) + 58.12 + 79.52 * randomSeed;
    value.y = length(param) + 96.53 + 36.95 * randomSeed;
    value.z = length(param) + 71.65 + 24.58 * randomSeed;
    value.x = (sin(value.x)) - floor(sin(value.x));
    value.y = (sin(value.y)) - floor(sin(value.y));
    value.z = (sin(value.z)) - floor(sin(value.z));
    return normalize(value);
}

vec3 grad(float x, float y) {
   vec3 vec;
   vec[0] = x * 127.1 + y * 311.7;
   vec[1] = x * 269.5 + y * 183.3;

   float sin0 = sin(vec[0]) * 43758.5453123;
   float sin1 = sin(vec[1]) * 43758.5453123;
   vec[0] = (sin0 - floor(sin0)) * 2.0 - 1.0;
   vec[1] = (sin1 - floor(sin1)) * 2.0 - 1.0;

    // 归一化，尽量消除正方形的方向性偏差
   float len = sqrt(vec[0] * vec[0] + vec[1] * vec[1]);
   vec[0] /= len;
   vec[1] /= len;

   return vec;
}

vec3 GetConstantVector(int blockNumber, ivec3 blockCoord, float randomSeed) {
    if (_IsTilable) {
        if (blockCoord.x == blockNumber) {
            blockCoord.x = 0;
        }

        if (blockCoord.y == blockNumber) {
            blockCoord.y = 0;
        }

        if (blockCoord.z == blockNumber) {
            blockCoord.z = 0;
        }
    }
	
//    vec3 vec = GetRandom3To3_Raw(vec3(blockCoord) + _Evolution, length(vec3(blockCoord)) * randomSeed);
	vec3 vec = grad(float(blockCoord.x) + _Evolution.x , float(blockCoord.y) + _Evolution.y);
    vec = normalize(vec);
    return vec;
}

float GetNoise(vec2 uv, float freq, float randomSeed, out vec3 dir)
{
	int grid_count = int(ceil(freq));
	vec2 grid_size = size / float(grid_count);
	vec2 position = uv * uv_scale * size;
	vec2 uv_global = position / grid_size;
	vec2 uv_f = fract(uv_global);
	vec2 uv_i = floor(uv_global);
	
	vec2 ld = uv_i * grid_size;
	vec2 lu = (uv_i + vec2(0, 1)) * grid_size;
	vec2 ru = (uv_i + vec2(1, 1)) * grid_size;
	vec2 rd = (uv_i + vec2(1, 0)) * grid_size;
//	uv_f.x = (position.x - ld.x) / grid_size.x;
//	uv_f.y = (position.y - ld.y) / grid_size.y;
	
	vec2 AP = position - ld;
	vec2 BP = position - lu;
	vec2 CP = position - ru;
	vec2 DP = position - rd;
	
	AP /= grid_size;
	BP /= grid_size;
	CP /= grid_size;
	DP /= grid_size;
	vec3 a = GetConstantVector(grid_count, ivec3(vec3(uv_i, 0.0)), _RandomSeed);
	vec3 b = GetConstantVector(grid_count, ivec3(vec3(uv_i + vec2(0, 1), 0.0)), _RandomSeed);
	vec3 c = GetConstantVector(grid_count, ivec3(vec3(uv_i + vec2(1, 1), 0.0)), _RandomSeed);
	vec3 d = GetConstantVector(grid_count, ivec3(vec3(uv_i + vec2(1, 0), 0.0)), _RandomSeed);
	float dotA = dot(AP , a.xy);
	float dotB = dot(BP , b.xy);
	float dotC = dot(CP , c.xy);
	float dotD = dot(DP , d.xy);
	dir = a;
	float temp0 = PerlinNoiseLerp(dotA, dotD, uv_f.x);
	float temp1 = PerlinNoiseLerp(dotB, dotC, uv_f.x);
	float noiseValue = PerlinNoiseLerp(temp0, temp1, uv_f.y);
	noiseValue = (noiseValue + 1.0) / 2.0;
	return noiseValue;
}

/* discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
vec3 random3(vec3 c) {
	float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
	vec3 r;
	r.z = fract(512.0*j);
	j *= .125;
	r.x = fract(512.0*j);
	j *= .125;
	r.y = fract(512.0*j);
	return r-0.5;
}


/* 3d simplex noise */
float simplex3d(vec3 p) {
	 /* 1. find current tetrahedron T and it's four vertices */
	 /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
	 /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/
	 
	 /* calculate s and x */
	 vec3 s = floor(p + dot(p, vec3(F3)));
	 vec3 x = p - s + dot(s, vec3(G3));
	 
	 /* calculate i1 and i2 */
	 vec3 e = step(vec3(0.0), x - x.yzx);
	 vec3 i1 = e*(1.0 - e.zxy);
	 vec3 i2 = 1.0 - e.zxy*(1.0 - e);
	 	
	 /* x1, x2, x3 */
	 vec3 x1 = x - i1 + G3;
	 vec3 x2 = x - i2 + 2.0*G3;
	 vec3 x3 = x - 1.0 + 3.0*G3;
	 
	 /* 2. find four surflets and store them in d */
	 vec4 w, d;
	 
	 /* calculate surflet weights */
	 w.x = dot(x, x);
	 w.y = dot(x1, x1);
	 w.z = dot(x2, x2);
	 w.w = dot(x3, x3);
	 
	 /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
	 w = max(0.6 - w, 0.0);
	 
	 /* calculate surflet components */
	 d.x = dot(random3(s), x);
	 d.y = dot(random3(s + i1), x1);
	 d.z = dot(random3(s + i2), x2);
	 d.w = dot(random3(s + 1.0), x3);
	 
	 /* multiply d by w^4 */
	 w *= w;
	 w *= w;
	 d *= w;
	 
	 /* 3. return the sum of the four surflets */
	 return dot(d, vec4(52.0));
}

/* const matrices for 3d rotation */
const mat3 rot1 = mat3(vec3(-0.37, 0.36, 0.85),vec3(-0.14,-0.93, 0.34), vec3(0.92, 0.01,0.4));
const mat3 rot2 = mat3(vec3(-0.55,-0.39, 0.74), vec3(0.33,-0.91,-0.24), vec3(0.77, 0.12,0.63));
const mat3 rot3 = mat3(vec3(-0.71, 0.52,-0.47),vec3(-0.08,-0.72,-0.68), vec3(-0.7,-0.45,0.56));
/* directional artifacts can be reduced by rotating each octave */
float simplex3d_fractal(vec3 m) {
    return   0.5333333*simplex3d(m*rot1)
			+0.2666667*simplex3d(2.0*m*rot2)
			+0.1333333*simplex3d(4.0*m*rot3)
			+0.0666667*simplex3d(8.0*m);
}

void fragment()
{
	vec3 dir;
	float noise = GetNoise(UV, _Frequency, _RandomSeed, dir);
//	float noise = 0.0;
	float currentTile = _Frequency;
    float currentStrength = 1.0;
//    for(int iii = 0; iii < _FBMIteration; iii++) {
//        currentTile *= 2.0;
//        currentStrength /= 2.0;
//        if(currentTile >= size.x) {
//            currentTile /= 2.0;
//        }
//        noise += GetNoise(UV, currentTile, _RandomSeed + currentTile, dir) * currentStrength;
//    }
	COLOR.xyz = vec3(noise, noise, noise);
//	COLOR.xyz = dir;

	vec3 p3 = vec3(UV, TIME*0.025);
	
	float val = simplex3d_fractal(p3 * 8.0 + 8.0);
	val = 0.5 + 0.5*val;
	val *= smoothstep(0.0, 0.005, abs(0.6 - UV.x)); // hello, iq :)
	
	COLOR.xyz = vec3(val, val, val);
	
	
//	vec2 uv1 = UV * 2.0;
//	vec2 uvi = floor(uv1);
//	vec2 uvf = uv1 - uvi;
//	if(mod  (uvi.x,  2.0) < 0.01)
//	{
//		uv1.x = uvf.x;
//	}
//	else
//	{
//		uv1.x = 1.0 - uvf.x;
//	}
//
//	if(mod (uvi.y , 2.0) < 0.01)
//	{
//		uv1.y = uvf.y;
//	}
//	else
//	{
//		uv1.y = 1.0 - uvf.y;
//	}
	
	vec3 pos = vec3(UV, TIME * speed);
//	float f = noise_sum_abs(pos, currentTile);
	float f = noise_sum(pos, currentTile);
	
	COLOR.xyz = vec3(f, f, f);
//	vec3  cc = hash33(pos * 8.0);
//	COLOR.xyz = cc;
	


	
}
