shader_type spatial;
render_mode cull_disabled, unshaded;

uniform float radius;
uniform float radiusA;
uniform float radiusB;
uniform float radiusC;
uniform float distFactor = 1.0;
uniform mat4 cameraToOcean;
uniform vec3 oceanCameraPos;
uniform vec3 horizon1;
uniform vec3 horizon2;

uniform float heightOffset = 0.0; // so that surface height is centered around z = 0





uniform sampler2D testTex;
uniform sampler2D transmittanceSampler;
uniform sampler2D skyIrradianceSampler;


uniform vec3 sun_dir = vec3(0, 0, 1);
uniform float reflectivity = 1;
uniform float hdrExposure = 0.4;

uniform float PLANET_RADIUS =  6370000.0; /* radius of the planet */
uniform float ATMOS_RADIUS = 6478137.0; /* radius of the atmosphere */
uniform float SUN_INTENSITY = 100.0;
uniform float normalMax = 0.0;
uniform float distanceMax = 40000;
uniform float distanceOffset = 100;

//varying vec2 uv;
varying vec3 vertex_v;
varying float shadow_factor;

const float Z0 = 1.0;

const float PI = 3.141592657;
uniform float NYQUIST_MIN = 0.5;
uniform float NYQUIST_MAX = 1.25;

const float SCALE = 1000.0;

//const float Rg = 6360.0 * SCALE;
//const float Rt = 6420.0 * SCALE;
//const float RL = 6421.0 * SCALE;

const float Rg = 6378137.0;
const float Rt = 6420.0 * SCALE;
const float RL = 6421.0 * SCALE;


// Can you explain these epsilons to a wide graphics audience?  YOUR comment could go here.
const float EPSILON	= 1e-3;
//#define  EPSILON_NRM	(0.5 / iResolution.x)

// Constant indicaing the number of steps taken while marching the light ray.  
const int NUM_STEPS = 2;

//Constants relating to the iteration of the heightmap for the wave, another part of the rendering
//process.
const int ITER_GEOMETRY = 2;
const int ITER_FRAGMENT =5;

// Constants that represent physical characteristics of the sea, can and should be changed and 
//  played with
uniform float SEA_HEIGHT = 0.5;
uniform float SEA_CHOPPY = 3.0;
uniform float SEA_SPEED = 1.9;
uniform float SEA_FREQ = 0.24;
uniform vec4 SEA_BASE :hint_color = vec4(0.11,0.19,0.22,1.0);
uniform vec4 SEA_WATER_COLOR :hint_color = vec4(0.55,0.9,0.7, 1.0);
uniform float k1 = 2.951;
uniform float k2 = 2.16;
//#define SEA_TIME (iTime * SEA_SPEED)

//Matrix to permute the water surface into a complex, realistic form
const mat2 octave_m = mat2(vec2(1.7,1.2),vec2(-1.2,1.4));

//Space bar key constant
const float KEY_SP    = 32.5/256.0;

vec2 oceanPos(vec3 vertex, mat4 screenToCamera, out float t, out vec3 cameraDir, out vec3 oceanDir, out vec3 color_out) {
   
	vec3 v = vertex;
	float horizon = horizon1.x + horizon1.y * v.x - sqrt(horizon2.x + (horizon2.y + horizon2.z * v.x) * v.x);
	cameraDir = normalize((screenToCamera * vec4(v.x, min(v.y, horizon), -1.0, 1.0)).xyz); //视图空间近平面上的点
//	vec4 nearPos = screenToCamera * vec4(vertex.x * 2.0 - 1.0, vertex.y* 2.0 - 1.0, -1.0, 1.0);
//	cameraDir = normalize((nearPos / nearPos.w).xyz);
//	cameraDir = normalize((screenToCamera * vec4(vertex.x * 2.0 - 1.0, vertex.y* 2.0 - 1.0, -1.0, 1.0)).xyz); //视图空间近平面上的点
    oceanDir = (cameraToOcean * vec4(cameraDir, 0.0)).xyz; //转到海洋空间近平面上的点
    float cz = oceanCameraPos.y;  //海洋空间相机位置y分量
    float dz = oceanDir.y;  //海洋空间近平面上的点的y分量
    if (radius == 0.0) {
        t = (heightOffset + Z0 - cz) / dz;
    } else { //求与海面的交点
        float b = dz * (cz + radius);
        float c = cz * (cz + 2.0 * radius);
        float tSphere = - b - sqrt(max(b * b - c, 0.0));
//		if(b * b - c < 0.0)
//		{
//			t = 0.0;
//			return oceanCameraPos.zx + t * oceanDir.zx;
//		}
        float tApprox = - cz / dz * (1.0 + cz / (2.0 * radius) * (1.0 - dz * dz));
//		float tApprox = - cz / dz;
		if(((tApprox - tSphere) * dz) < 1.0)
		{
			color_out = vec3(1, 0, 0);
		}
		else
		{
			color_out = vec3(0, 1, 0);
		}
        t = abs((tApprox - tSphere) * dz) < 1.0 ? tApprox : tSphere;
//		t = tApprox;
    }
//	if(horizon > 1.0)
//		{
//			color_out = vec3(1, 0, 0);
//		}
//		else
//		{
//			color_out = vec3(0, 1, 0);
//		}
    return oceanCameraPos.zx + t * oceanDir.zx;
}
vec2 oceanPos2(vec3 vertex, mat4 screenToCamera, mat4 camToOcean, float cz, out float t, out vec3 cameraDir, out vec3 oceanDir, out vec3 color_out) {
    vec3 v = vertex;
	float horizon = horizon1.x + horizon1.y * v.x - sqrt(horizon2.x + (horizon2.y + horizon2.z * v.x) * v.x);
	cameraDir = normalize((screenToCamera * vec4(v.x, min(v.y, horizon), -1.0, 1.0)).xyz); //视图空间近平面上的点
//	vec4 nearPos = screenToCamera * vec4(vertex.x * 2.0 - 1.0, vertex.y* 2.0 - 1.0, -1.0, 1.0);
//	cameraDir = normalize((nearPos / nearPos.w).xyz);
//	cameraDir = normalize((screenToCamera * vec4(vertex.x * 2.0 - 1.0, vertex.y* 2.0 - 1.0, -1.0, 1.0)).xyz); //视图空间近平面上的点
    oceanDir = (camToOcean * vec4(cameraDir, 0.0)).xyz; //转到海洋空间近平面上的点
//    float cz = oceanCameraPos.y;  //海洋空间相机位置y分量
    float dz = oceanDir.y;  //海洋空间近平面上的点的y分量
    if (radius == 0.0) {
        t = (heightOffset + Z0 - cz) / dz;
    } else { //求与海面的交点
        float b = dz * (cz + radius);
        float c = cz * (cz + 2.0 * radius);
        float tSphere = - b - sqrt(max(b * b - c, 0.0));
//		if(b * b - c < 0.0)
//		{
//			t = 0.0;
//			return oceanCameraPos.zx + t * oceanDir.zx;
//		}
        float tApprox = - cz / dz * (1.0 + cz / (2.0 * radius) * (1.0 - dz * dz));
//		float tApprox = - cz / dz;
		if(((tApprox - tSphere) * dz) < 1.0)
		{
			color_out = vec3(1, 0, 0);
		}
		else
		{
			color_out = vec3(0, 1, 0);
		}
        t = abs((tApprox - tSphere) * dz) < 1.0 ? tApprox : tSphere;
//		t = tApprox;
    }
//	if(horizon > 1.0)
//		{
//			color_out = vec3(1, 0, 0);
//		}
//		else
//		{
//			color_out = vec3(0, 1, 0);
//		}
    return oceanCameraPos.zx + t * oceanDir.zx;
}
float meanFresnel(float cosThetaV, float sigmaV) {
    return pow(1.0 - cosThetaV, 5.0 * exp(-2.69 * sigmaV)) / (1.0 + 22.7 * pow(sigmaV, 1.5));
}

float meanFresnel2(vec3 V, vec3 N, float sigmaSq) {
    return meanFresnel(dot(V, N), sqrt(sigmaSq));
}

float reflectedSunRadiance(vec3 V, vec3 N, vec3 L, float sigmaSq) {
    vec3 H = normalize(L + V);

    float hn = dot(H, N);
    float p = exp(-2.0 * ((1.0 - hn * hn) / sigmaSq) / (1.0 + hn)) / (4.0 * PI * sigmaSq);

    float c = 1.0 - dot(V, H);
    float c2 = c * c;
    float fresnel = 0.02 + 0.98 * c2 * c2 * c;

    float zL = dot(L, N);
    float zV = dot(V, N);
    zL = max(zL, 0.01);
    zV = max(zV, 0.01);

    // brdf times cos(thetaL)
    return zL <= 0.0 ? 0.0 : max(fresnel * p * sqrt(abs(zL / zV)), 0.0);
}

vec3 oceanRadiance1(vec3 V, vec3 N, vec3 L, float seaRoughness, vec3 sunL, vec3 skyE, vec3 seaColor) {
    float F = meanFresnel2(V, N, seaRoughness);
    vec3 Lsun = reflectedSunRadiance(V, N, L, seaRoughness) * sunL;
    vec3 Lsky = skyE * F / PI;
    vec3 Lsea = (1.0 - F) * seaColor * skyE / PI;
//	vec3 Lsea = (1.0 - F) * seaColor / PI;
    return Lsun + Lsky + Lsea;
//    return  Lsea;
}


vec3 hdr(vec3 L) {
    L = L * hdrExposure;
    L.r = L.r < 1.413 ? pow(L.r * 0.38317, 1.0 / 2.2) : 1.0 - exp(-L.r);
    L.g = L.g < 1.413 ? pow(L.g * 0.38317, 1.0 / 2.2) : 1.0 - exp(-L.g);
    L.b = L.b < 1.413 ? pow(L.b * 0.38317, 1.0 / 2.2) : 1.0 - exp(-L.b);
    return L;
}
float refractedSeaRadiance(vec3 V, vec3 N, float sigmaSq) {
    return 0.98 * (1.0 - meanFresnel2(V, N, sigmaSq));
}

// L, V, N in world space
float wardReflectedSunRadiance(vec3 L, vec3 V, vec3 N, float sigmaSq) {
    vec3 H = normalize(L + V);

    float hn = dot(H, N);
    float p = exp(-2.0 * ((1.0 - hn * hn) / sigmaSq) / (1.0 + hn)) / (4.0 * PI * sigmaSq);

    float c = 1.0 - dot(V, H);
    float c2 = c * c;
    float fresnel = 0.02 + 0.98 * c2 * c2 * c;

    float zL = dot(L, N);
    float zV = dot(V, N);
    zL = max(zL,0.01);
    zV = max(zV,0.01);

    // brdf times cos(thetaL)
    return zL <= 0.0 ? 0.0 : max(fresnel * p * sqrt(abs(zL / zV)), 0.0);
}

vec2 getTransmittanceUV(float r, float mu) {
    float uR, uMu;

    uR = sqrt((r - Rg) / (Rt - Rg));
    uMu = atan((mu + 0.15) / (1.0 + 0.15) * tan(1.5)) / 1.5;

//    uR = (r - Rg) / (Rt - Rg);
//    uMu = (mu + 0.15) / (1.0 + 0.15);

    return vec2(uMu, uR);
}
vec2 getIrradianceUV(float r, float muS) {
    float uR = (r - Rg) / (Rt - Rg);
    float uMuS = (muS + 0.2) / (1.0 + 0.2);
    return vec2(uMuS, uR);
}
vec3 transmittance(float r, float mu) {
    vec2 transmittanceUV = getTransmittanceUV(r, mu);
    return texture(transmittanceSampler, transmittanceUV).rgb;
}

vec3 transmittanceWithShadow(float r, float mu) {
    return mu < -sqrt(1.0 - (Rg / r) * (Rg / r)) ? vec3(0.0) : transmittance(r, mu);
}
vec3 irradiance(sampler2D sampler, float r, float muS) {
    vec2 irradianceUV = getIrradianceUV(r, muS);
    return texture(sampler, irradianceUV).rgb;
}
vec3 sunRadiance(float r, float muS) {
    return transmittanceWithShadow(r, muS) * SUN_INTENSITY;
}
// incident sky light at given position, integrated over the hemisphere (irradiance)
// r=length(x)
// muS=dot(x,s) / r
vec3 skyIrradiance(float r, float muS) {
    return irradiance(skyIrradianceSampler, r, muS) * SUN_INTENSITY;
}
void sunRadianceAndSkyIrradiance(vec3 worldP, vec3 worldN, vec3 worldS, out vec3 sunL, out vec3 skyE)
{
    float r = length(worldP);
    if (r < 0.9 * PLANET_RADIUS) {
        worldP.y += PLANET_RADIUS;
        r = length(worldP);
    }
    vec3 worldV = worldP / r; // vertical vector
    float muS = dot(worldV, worldS);
    sunL = sunRadiance(r, muS);
    skyE = skyIrradiance(r, muS) * (1.0 + dot(worldV, worldN));
//	skyE = vec3(1.0);
}




varying vec3 pointInOcean;

uniform float DRAG_MULT = 0.28; // changes how much waves pull on the water
uniform float WATER_DEPTH = 0.5; // how deep is the water
uniform float CAMERA_HEIGHT = 1.5; // how high the camera should be
uniform int ITERATIONS_RAYMARCH = 12; // waves iterations of raymarching
uniform int ITERATIONS_NORMAL = 40; // waves iterations when calculating normals
// Some very barebones but fast atmosphere approximation
vec3 extra_cheap_atmosphere(vec3 raydir, vec3 sundir) {
  sundir.y = max(sundir.y, -0.07);
  float special_trick = 1.0 / (raydir.y * 1.0 + 0.1);
  float special_trick2 = 1.0 / (sundir.y * 11.0 + 1.0);
  float raysundt = pow(abs(dot(sundir, raydir)), 2.0);
  float sundt = pow(max(0.0, dot(sundir, raydir)), 8.0);
  float mymie = sundt * special_trick * 0.2;
  vec3 suncolor = mix(vec3(1.0), max(vec3(0.0), vec3(1.0) - vec3(5.5, 13.0, 22.4) / 22.4), special_trick2);
  vec3 bluesky= vec3(5.5, 13.0, 22.4) / 22.4 * suncolor;
  vec3 bluesky2 = max(vec3(0.0), bluesky - vec3(5.5, 13.0, 22.4) * 0.002 * (special_trick + -6.0 * sundir.y * sundir.y));
  bluesky2 *= special_trick * (0.24 + raysundt * 0.24);
  return bluesky2 * (1.0 + 1.0 * pow(1.0 - raydir.y, 3.0)) + mymie * suncolor;
}
// Calculate where the sun should be, it will be moving around the sky
vec3 getSunDirection() {
  return normalize(vec3(sin(TIME * 0.1), 1.0, cos(TIME * 0.1)));
}

// Get atmosphere color for given direction
vec3 getAtmosphere(vec3 dir, vec3 lightDir) {
   return extra_cheap_atmosphere(dir, lightDir) * 0.5;
}
// Great tonemapping function from my other shader: https://www.shadertoy.com/view/XsGfWV
vec3 aces_tonemap(vec3 incolor) {  
  mat3 m1 = mat3(
   vec3(0.59719, 0.07600, 0.02840),
   vec3(0.35458, 0.90834, 0.13383),
   vec3(0.04823, 0.01566, 0.83777)
  );
  mat3 m2 = mat3(
    vec3(1.60475, -0.10208, -0.00327),
    vec3(-0.53108,  1.10813, -0.07276),
    vec3(-0.07367, -0.00605,  1.07602)
  );
  vec3 v = m1 * incolor;  
  vec3 a = v * (v + 0.0245786) - 0.000090537;
  vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
  return pow(clamp(m2 * (a / b), 0.0, 1.0), vec3(1.0 / 2.2));  
}

// Get sun color for given direction
float getSun(vec3 dir, vec3 lightDir) { 
  return pow(max(0.0, dot(dir, lightDir)), 720.0) * 210.0;
}
// Calculates wave value and its derivative, 
// for the wave direction, position in space, wave frequency and time
vec2 wavedx(vec2 position, vec2 direction, float frequency, float timeshift) {
  float x = dot(direction, position) * frequency + timeshift;
  float wave = exp(sin(x) - 1.0);
  float dx = wave * cos(x);
  return vec2(wave, -dx);
}
// Calculates waves by summing octaves of various waves with various parameters
float getwaves(vec2 position, int iterations) {
  float iter = 0.0; // this will help generating well distributed wave directions
  float frequency = 1.0; // frequency of the wave, this will change every iteration
  float timeMultiplier = 2.0; // time multiplier for the wave, this will change every iteration
  float weight = 1.0;// weight in final sum for the wave, this will change every iteration
  float sumOfValues = 0.0; // will store final sum of values
  float sumOfWeights = 0.0; // will store final sum of weights
  for(int i=0; i < iterations; i++) {
    // generate some wave direction that looks kind of random
    vec2 p = vec2(sin(iter), cos(iter));
    // calculate wave data
    vec2 res = wavedx(position, p, frequency, TIME * timeMultiplier);

    // shift position around according to wave drag and derivative of the wave
    position += p * res.y * weight * DRAG_MULT;

    // add the results to sums
    sumOfValues += res.x * weight;
    sumOfWeights += weight;

    // modify next octave parameters
    weight *= 0.82;
    frequency *= 1.18;
    timeMultiplier *= 1.07;

    // add some kind of random value to make next wave look random too
    iter += 1232.399963;
  }
  // calculate and return
  return sumOfValues / sumOfWeights;
}
// Raymarches the ray from top water layer boundary to low water layer boundary
float raymarchwater(vec3 camera, vec3 start, vec3 end, float depth) {
  vec3 pos = start;
  vec3 dir = normalize(end - start);
  for(int i=0; i < 64; i++) {
    // the height is from 0 to -depth
    float height = getwaves(pos.xz, ITERATIONS_RAYMARCH) * depth - depth;
    // if the waves height almost nearly matches the ray height, assume its a hit and return the hit distance
    if(height + 0.01 > pos.y) {
      return distance(pos, camera);
    }
    // iterate forwards according to the height mismatch
    pos += dir * (pos.y - height);
  }
  // if hit was not registered, just assume hit the top layer, 
  // this makes the raymarching faster and looks better at higher distances
  return distance(start, camera);
}

vec3 FlowUVW(vec2 uv_in, vec2 flowVector, vec2 jump, vec3 tiling, float time, bool flowB) {
	float phaseOffset = flowB ? 0.5 : 0.0;
	float progress = fract(time + phaseOffset);
	vec3 uvw;

	uvw.xy = uv_in - flowVector * (progress - 0.5);
//	if(flowB)
//	{
//		uvw.xy = uv_in - flowVector * (progress - 0.5);
//	}
//	else
//	{
//		uvw.xy = uv_in + 2.0 *  flowVector * (progress - 0.5);
//	}
//
	
	uvw.xy *= tiling.xy;
	uvw.xy += phaseOffset;
	uvw.xy += (time - progress) * jump;
	uvw.z = 1.0 - abs(1.0 - 2.0 * progress);
	return uvw;
}

// ease implementation copied from math_funcs.cpp in source
float ease(float p_x, float p_c) {
	if (p_x < 0.0) {
		p_x = 0.0;
		} else if (p_x > 1.0) {
		p_x = 1.0;
	}
	if (p_c > 0.0) {
		if (p_c < 1.0) {
			return 1.0 - pow(1.0 - p_x, 1.0 / p_c);
			} else {
			return pow(p_x, p_c);
		}
		} else if (p_c < 0.0) {
		//inout ease
		
		if (p_x < 0.5) {
			return pow(p_x * 2.0, -p_c) * 0.5;
			} else {
			return (1.0 - pow(1.0 - (p_x - 0.5) * 2.0, -p_c)) * 0.5 + 0.5;
		}
		} else {
		return 0.0; // no ease (raw)
	}
}
float lin2srgb(float lin) {
	return pow(lin, 2.2);
}
mat4 gradient_lin2srgb(vec4 lin_mat,vec4 lin_mat2) {
	mat4 srgb_mat = mat4(
		vec4(lin2srgb(lin_mat.x), lin2srgb(lin_mat.y), lin2srgb(lin_mat.z), lin2srgb(lin_mat.w)),
		vec4(lin2srgb(lin_mat2.x), lin2srgb(lin_mat2.y), lin2srgb(lin_mat2.z), lin2srgb(lin_mat2.w)),
		vec4(0.0),
		vec4(0.0)
	);
	return srgb_mat;
}

// Calculate normal at point by calculating the height at the pos and 2 additional points very close to pos
vec3 normal3(vec2 pos, float e, float depth) {
  vec2 ex = vec2(e, 0);
  float H = getwaves(pos.xy, ITERATIONS_NORMAL) * depth;
  vec3 a = vec3(pos.x, H, pos.y);
  return normalize(
    cross(
      a - vec3(pos.x - e, getwaves(pos.xy - ex.xy, ITERATIONS_NORMAL) * depth, pos.y), 
      a - vec3(pos.x, getwaves(pos.xy + ex.yx, ITERATIONS_NORMAL) * depth, pos.y + e)
    )
  );
}
//CaliCoastReplay :  These HSV/RGB translation functions are
//from http://gamedev.stackexchange.com/questions/59797/glsl-shader-change-hue-saturation-brightness
//This one converts red-green-blue color to hue-saturation-value color
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

//CaliCoastReplay :  These HSV/RGB translation functions are
//from http://gamedev.stackexchange.com/questions/59797/glsl-shader-change-hue-saturation-brightness
//This one converts hue-saturation-value color to red-green-blue color
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// math
// bteitler: Turn a vector of Euler angles into a rotation matrix
mat3 fromEuler(vec3 ang) {
	vec2 a1 = vec2(sin(ang.x),cos(ang.x));
    vec2 a2 = vec2(sin(ang.y),cos(ang.y));
    vec2 a3 = vec2(sin(ang.z),cos(ang.z));
    mat3 m;
    m[0] = vec3(a1.y*a3.y+a1.x*a2.x*a3.x,a1.y*a2.x*a3.x+a3.y*a1.x,-a2.y*a3.x);
	m[1] = vec3(-a2.y*a1.x,a1.y*a2.y,a2.x);
	m[2] = vec3(a3.y*a1.x*a2.x+a1.y*a3.x,a1.x*a3.x-a1.y*a3.y*a2.x,a2.y*a3.y);
	return m;
}

// bteitler: A 2D hash function for use in noise generation that returns range [0 .. 1].  You could
// use any hash function of choice, just needs to deterministic and return
// between 0 and 1, and also behave randomly.  Googling "GLSL hash function" returns almost exactly 
// this function: http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
// Performance is a real consideration of hash functions since ray-marching is already so heavy.
float hash( vec2 p ) {
    float h = dot(p,vec2(127.1,311.7));	
    return fract(sin(h)*83758.5453123);
}

// bteitler: A 2D psuedo-random wave / terrain function.  This is actually a poor name in my opinion,
// since its the "hash" function that is really the noise, and this function is smoothly interpolating
// between noisy points to create a continuous surface.
float noise( in vec2 p ) {
    vec2 i = floor( p );
    vec2 f = fract( p );	

    // bteitler: This is equivalent to the "smoothstep" interpolation function.
    // This is a smooth wave function with input between 0 and 1
    // (since it is taking the fractional part of <p>) and gives an output
    // between 0 and 1 that behaves and looks like a wave.  This is far from obvious, but we can graph it to see
    // Wolfram link: http://www.wolframalpha.com/input/?i=plot+x*x*%283.0-2.0*x%29+from+x%3D0+to+1
    // This is used to interpolate between random points.  Any smooth wave function that ramps up from 0 and
    // and hit 1.0 over the domain 0 to 1 would work.  For instance, sin(f * PI / 2.0) gives similar visuals.
    // This function is nice however because it does not require an expensive sine calculation.
    vec2 u = f*f*(3.0-2.0*f);

    // bteitler: This very confusing looking mish-mash is simply pulling deterministic random values (between 0 and 1)
    // for 4 corners of the grid square that <p> is inside, and doing 2D interpolation using the <u> function
    // (remember it looks like a nice wave!) 
    // The grid square has points defined at integer boundaries.  For example, if <p> is (4.3, 2.1), we will 
    // evaluate at points (4, 2), (5, 2), (4, 3), (5, 3), and then interpolate x using u(.3) and y using u(.1).
    return -1.0+2.0*mix( 
                mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), 
                        u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), 
                        u.x), 
                u.y);
}

// bteitler: diffuse lighting calculation - could be tweaked to taste
// lighting
float diffuse(vec3 n,vec3 l,float p) {
    return pow(dot(n,l) * 0.4 + 0.6,p);
}

// bteitler: specular lighting calculation - could be tweaked taste
float specular(vec3 n,vec3 l,vec3 e,float s) {    
    float nrm = (s + 8.0) / (3.1415 * 8.0);
    return pow(max(dot(reflect(e,n),l),0.0),s) * nrm;
}

// bteitler: Generate a smooth sky gradient color based on ray direction's Y value
// sky
vec3 getSkyColor(vec3 e) {
    e.y = max(e.y,0.0);
    vec3 ret;
    ret.x = pow(1.0-e.y,2.0);
    ret.y = 1.0-e.y;
    ret.z = 0.6+(1.0-e.y)*0.4;
    return ret;
}

// sea
// bteitler: TLDR is that this passes a low frequency random terrain through a 2D symmetric wave function that looks like this:
// http://www.wolframalpha.com/input/?i=%7B1-%7B%7B%7BAbs%5BCos%5B0.16x%5D%5D+%2B+Abs%5BCos%5B0.16x%5D%5D+%28%281.+-+Abs%5BSin%5B0.16x%5D%5D%29+-+Abs%5BCos%5B0.16x%5D%5D%29%7D+*+%7BAbs%5BCos%5B0.16y%5D%5D+%2B+Abs%5BCos%5B0.16y%5D%5D+%28%281.+-+Abs%5BSin%5B0.16y%5D%5D%29+-+Abs%5BCos%5B0.16y%5D%5D%29%7D%7D%5E0.65%7D%7D%5E4+from+-20+to+20
// The <choppy> parameter affects the wave shape.
float sea_octave(vec2 uv, float choppy) {
    // bteitler: Add the smoothed 2D terrain / wave function to the input coordinates
    // which are going to be our X and Z world coordinates.  It may be unclear why we are doing this.
    // This value is about to be passed through a wave function.  So we have a smoothed psuedo random height
    // field being added to our (X, Z) coordinates, and then fed through yet another wav function below.
    uv += noise(uv);
    // Note that you could simply return noise(uv) here and it would take on the characteristics of our 
    // noise interpolation function u and would be a reasonable heightmap for terrain.  
    // However, that isn't the shape we want in the end for an ocean with waves, so it will be fed through
    // a more wave like function.  Note that although both x and y channels of <uv> have the same value added, there is a 
    // symmetry break because <uv>.x and <uv>.y will typically be different values.

    // bteitler: This is a wave function with pointy peaks and curved troughs:
    // http://www.wolframalpha.com/input/?i=1-abs%28cos%28x%29%29%3B
    vec2 wv = 1.0-abs(sin(uv)); 

    // bteitler: This is a wave function with curved peaks and pointy troughs:
    // http://www.wolframalpha.com/input/?i=abs%28cos%28x%29%29%3B
    vec2 swv = abs(cos(uv));  
  
    // bteitler: Blending both wave functions gets us a new, cooler wave function (output between 0 and 1):
    // http://www.wolframalpha.com/input/?i=abs%28cos%28x%29%29+%2B+abs%28cos%28x%29%29+*+%28%281.0-abs%28sin%28x%29%29%29+-+abs%28cos%28x%29%29%29
    wv = mix(wv,swv,wv);

    // bteitler: Finally, compose both of the wave functions for X and Y channels into a final 
    // 1D height value, shaping it a bit along the way.  First, there is the composition (multiplication) of
    // the wave functions: wv.x * wv.y.  Wolfram will give us a cute 2D height graph for this!:
    // http://www.wolframalpha.com/input/?i=%7BAbs%5BCos%5Bx%5D%5D+%2B+Abs%5BCos%5Bx%5D%5D+%28%281.+-+Abs%5BSin%5Bx%5D%5D%29+-+Abs%5BCos%5Bx%5D%5D%29%7D+*+%7BAbs%5BCos%5By%5D%5D+%2B+Abs%5BCos%5By%5D%5D+%28%281.+-+Abs%5BSin%5By%5D%5D%29+-+Abs%5BCos%5By%5D%5D%29%7D
    // Next, we reshape the 2D wave function by exponentiation: (wv.x * wv.y)^0.65.  This slightly rounds the base of the wave:
    // http://www.wolframalpha.com/input/?i=%7B%7BAbs%5BCos%5Bx%5D%5D+%2B+Abs%5BCos%5Bx%5D%5D+%28%281.+-+Abs%5BSin%5Bx%5D%5D%29+-+Abs%5BCos%5Bx%5D%5D%29%7D+*+%7BAbs%5BCos%5By%5D%5D+%2B+Abs%5BCos%5By%5D%5D+%28%281.+-+Abs%5BSin%5By%5D%5D%29+-+Abs%5BCos%5By%5D%5D%29%7D%7D%5E0.65
    // one last final transform (with choppy = 4) results in this which resembles a recognizable ocean wave shape in 2D:
    // http://www.wolframalpha.com/input/?i=%7B1-%7B%7B%7BAbs%5BCos%5Bx%5D%5D+%2B+Abs%5BCos%5Bx%5D%5D+%28%281.+-+Abs%5BSin%5Bx%5D%5D%29+-+Abs%5BCos%5Bx%5D%5D%29%7D+*+%7BAbs%5BCos%5By%5D%5D+%2B+Abs%5BCos%5By%5D%5D+%28%281.+-+Abs%5BSin%5By%5D%5D%29+-+Abs%5BCos%5By%5D%5D%29%7D%7D%5E0.65%7D%7D%5E4
    // Note that this function is called with a specific frequency multiplier which will stretch out the wave.  Here is the graph
    // with the base frequency used by map and map_detailed (0.16):
    // http://www.wolframalpha.com/input/?i=%7B1-%7B%7B%7BAbs%5BCos%5B0.16x%5D%5D+%2B+Abs%5BCos%5B0.16x%5D%5D+%28%281.+-+Abs%5BSin%5B0.16x%5D%5D%29+-+Abs%5BCos%5B0.16x%5D%5D%29%7D+*+%7BAbs%5BCos%5B0.16y%5D%5D+%2B+Abs%5BCos%5B0.16y%5D%5D+%28%281.+-+Abs%5BSin%5B0.16y%5D%5D%29+-+Abs%5BCos%5B0.16y%5D%5D%29%7D%7D%5E0.65%7D%7D%5E4+from+-20+to+20
    return pow(1.0-pow(wv.x * wv.y,0.65),choppy);
}

// bteitler: Compute the distance along Y axis of a point to the surface of the ocean
// using a low(er) resolution ocean height composition function (less iterations).
float map(vec3 p) {
    float freq = SEA_FREQ;
    float amp = SEA_HEIGHT;
    float choppy = SEA_CHOPPY;
    vec2 uv = p.xz; 
	uv.x *= 0.75;
    
    // bteitler: Compose our wave noise generation ("sea_octave") with different frequencies
    // and offsets to achieve a final height map that looks like an ocean.  Likely lots
    // of black magic / trial and error here to get it to look right.  Each sea_octave has this shape:
    // http://www.wolframalpha.com/input/?i=%7B1-%7B%7B%7BAbs%5BCos%5B0.16x%5D%5D+%2B+Abs%5BCos%5B0.16x%5D%5D+%28%281.+-+Abs%5BSin%5B0.16x%5D%5D%29+-+Abs%5BCos%5B0.16x%5D%5D%29%7D+*+%7BAbs%5BCos%5B0.16y%5D%5D+%2B+Abs%5BCos%5B0.16y%5D%5D+%28%281.+-+Abs%5BSin%5B0.16y%5D%5D%29+-+Abs%5BCos%5B0.16y%5D%5D%29%7D%7D%5E0.65%7D%7D%5E4+from+-20+to+20
    // which should give you an idea of what is going.  You don't need to graph this function because it
    // appears to your left :)
    float d, h = 0.0;    
    for(int i = 0; i < ITER_GEOMETRY; i++) {
        // bteitler: start out with our 2D symmetric wave at the current frequency
    	d = sea_octave((uv+ TIME * SEA_SPEED)*freq,choppy);
        // bteitler: stack wave ontop of itself at an offset that varies over time for more height and wave pattern variance
    	//d += sea_octave((uv-SEA_TIME)*freq,choppy);

        h += d * amp; // bteitler: Bump our height by the current wave function
        
        // bteitler: "Twist" our domain input into a different space based on a permutation matrix
        // The scales of the matrix values affect the frequency of the wave at this iteration, but more importantly
        // it is responsible for the realistic assymetry since the domain is shiftly differently.
        // This is likely the most important parameter for wave topology.
    	uv *=  octave_m;
        
        freq *= 1.9; // bteitler: Exponentially increase frequency every iteration (on top of our permutation)
        amp *= 0.22; // bteitler: Lower the amplitude every frequency, since we are adding finer and finer detail
        // bteitler: finally, adjust the choppy parameter which will effect our base 2D sea_octave shape a bit.  This makes
        // the "waves within waves" have different looking shapes, not just frequency and offset
        choppy = mix(choppy,1.0,0.2);
    }
    return p.y - h;
}

// bteitler: Compute the distance along Y axis of a point to the surface of the ocean
// using a high(er) resolution ocean height composition function (more iterations).
float map_detailed(vec3 p) {
    float freq = SEA_FREQ;
    float amp = SEA_HEIGHT;
    float choppy = SEA_CHOPPY;
    vec2 uv = p.xz; uv.x *= 0.75;
    
    // bteitler: Compose our wave noise generation ("sea_octave") with different frequencies
    // and offsets to achieve a final height map that looks like an ocean.  Likely lots
    // of black magic / trial and error here to get it to look right.  Each sea_octave has this shape:
    // http://www.wolframalpha.com/input/?i=%7B1-%7B%7B%7BAbs%5BCos%5B0.16x%5D%5D+%2B+Abs%5BCos%5B0.16x%5D%5D+%28%281.+-+Abs%5BSin%5B0.16x%5D%5D%29+-+Abs%5BCos%5B0.16x%5D%5D%29%7D+*+%7BAbs%5BCos%5B0.16y%5D%5D+%2B+Abs%5BCos%5B0.16y%5D%5D+%28%281.+-+Abs%5BSin%5B0.16y%5D%5D%29+-+Abs%5BCos%5B0.16y%5D%5D%29%7D%7D%5E0.65%7D%7D%5E4+from+-20+to+20
    // which should give you an idea of what is going.  You don't need to graph this function because it
    // appears to your left :)
    float d, h = 0.0;    
    for(int i = 0; i < ITER_FRAGMENT; i++) {
        // bteitler: start out with our 2D symmetric wave at the current frequency
    	d = sea_octave((uv + TIME * SEA_SPEED)*freq,choppy);
        // bteitler: stack wave ontop of itself at an offset that varies over time for more height and wave pattern variance
    	d += sea_octave((uv - TIME * SEA_SPEED)*freq,choppy);
        
        h += d * amp; // bteitler: Bump our height by the current wave function
        
        // bteitler: "Twist" our domain input into a different space based on a permutation matrix
        // The scales of the matrix values affect the frequency of the wave at this iteration, but more importantly
        // it is responsible for the realistic assymetry since the domain is shiftly differently.
        // This is likely the most important parameter for wave topology.
    	uv *= octave_m/1.2;
        
        freq *= 1.9; // bteitler: Exponentially increase frequency every iteration (on top of our permutation)
        amp *= 0.22; // bteitler: Lower the amplitude every frequency, since we are adding finer and finer detail
        // bteitler: finally, adjust the choppy parameter which will effect our base 2D sea_octave shape a bit.  This makes
        // the "waves within waves" have different looking shapes, not just frequency and offset
        choppy = mix(choppy,1.0,0.2);
    }
    return p.y - h;
}

// bteitler:
// p: point on ocean surface to get color for
// n: normal on ocean surface at <p>
// l: light (sun) direction
// eye: ray direction from camera position for this pixel
// dist: distance from camera to point <p> on ocean surface
vec3 getSeaColor(vec3 p, vec3 n, vec3 l, vec3 eye, vec3 dist) {  
    // bteitler: Fresnel is an exponential that gets bigger when the angle between ocean
    // surface normal and eye ray is smaller
    float fresnel = 1.0 - max(dot(n,-eye),0.0);
    fresnel = pow(fresnel,3.0) * 0.45;
        
    // bteitler: Bounce eye ray off ocean towards sky, and get the color of the sky
    vec3 reflected = getSkyColor(reflect(eye,n))*0.99;    
    
    // bteitler: refraction effect based on angle between light surface normal
    vec3 refracted = SEA_BASE.xyz + diffuse(n,l,80.0) * SEA_WATER_COLOR.xyz * 0.27; 
    
    // bteitler: blend the refracted color with the reflected color based on our fresnel term
    vec3 color = mix(refracted,reflected,fresnel);

    // bteitler: Apply a distance based attenuation factor which is stronger
    // at peaks
    float atten = max(1.0 - dot(dist,dist) * 0.001, 0.0);
    color += SEA_WATER_COLOR.xyz * (p.y - SEA_HEIGHT) * 0.15 * atten;
    
    // bteitler: Apply specular highlight
    color += vec3(specular(n,l,eye,90.0))*distFactor;
    return color;
    
}

// bteitler: Estimate the normal at a point <p> on the ocean surface using a slight more detailed
// ocean mapping function (using more noise octaves).
// Takes an argument <eps> (stands for epsilon) which is the resolution to use
// for the gradient.  See here for more info on gradients: https://en.wikipedia.org/wiki/Gradient
// tracing
vec3 getNormal(vec3 p, float eps) {
    // bteitler: Approximate gradient.  An exact gradient would need the "map" / "map_detailed" functions
    // to return x, y, and z, but it only computes height relative to surface along Y axis.  I'm assuming
    // for simplicity and / or optimization reasons we approximate the gradient by the change in ocean
    // height for all axis.
    vec3 n;
    n.y = map_detailed(p); // bteitler: Detailed height relative to surface, temporarily here to save a variable?
    n.x = map_detailed(vec3(p.x+eps,p.y,p.z)) - n.y; // bteitler approximate X gradient as change in height along X axis delta
    n.z = map_detailed(vec3(p.x,p.y,p.z+eps)) - n.y; // bteitler approximate Z gradient as change in height along Z axis delta
    // bteitler: Taking advantage of the fact that we know we won't have really steep waves, we expect
    // the Y normal component to be fairly large always.  Sacrifices yet more accurately to avoid some calculation.
    n.y = eps; 
    return normalize(n);

    // bteitler: A more naive and easy to understand version could look like this and
    // produces almost the same visuals and is a little more expensive.
    // vec3 n;
    // float h = map_detailed(p);
    // n.y = map_detailed(vec3(p.x,p.y+eps,p.z)) - h;
    // n.x = map_detailed(vec3(p.x+eps,p.y,p.z)) - h;
    // n.z = map_detailed(vec3(p.x,p.y,p.z+eps)) - h;
    // return normalize(n);
}


// bteitler: Find out where a ray intersects the current ocean
float heightMapTracing(vec3 ori, vec3 dir, float disToHorizon, out vec3 p) {  
    float tm = 0.0;
    float tx = disToHorizon; // bteitler: a really far distance, this could likely be tweaked a bit as desired

    // bteitler: At a really far away distance along the ray, what is it's height relative
    // to the ocean in ONLY the Y direction?
    float hx = map(ori + dir * tx);
    
    // bteitler: A positive height relative to the ocean surface (in Y direction) at a really far distance means
    // this pixel is pure sky.  Quit early and return the far distance constant.
    if(hx > 0.0) return tx;   

    // bteitler: hm starts out as the height of the camera position relative to ocean.
    float hm = map(ori + dir * tm); 
   
    // bteitler: This is the main ray marching logic.  This is probably the single most confusing part of the shader
    // since height mapping is not an exact distance field (tells you distance to surface if you drop a line down to ocean
    // surface in the Y direction, but there could have been a peak at a very close point along the x and z 
    // directions that is closer).  Therefore, it would be possible/easy to overshoot the surface using the raw height field
    // as the march distance.  The author uses a trick to compensate for this.
    float tmid = 0.0;
    for(int i = 0; i < NUM_STEPS; i++) { // bteitler: Constant number of ray marches per ray that hits the water
        // bteitler: Move forward along ray in such a way that has the following properties:
        // 1. If our current height relative to ocean is higher, move forward more
        // 2. If the height relative to ocean floor very far along the ray is much lower
        //    below the ocean surface, move forward less
        // Idea behind 1. is that if we are far above the ocean floor we can risk jumping
        // forward more without shooting under ocean, because the ocean is mostly level.
        // The idea behind 2. is that if extruding the ray goes farther under the ocean, then 
        // you are looking more orthgonal to ocean surface (as opposed to looking towards horizon), and therefore
        // movement along the ray gets closer to ocean faster, so we need to move forward less to reduce risk
        // of overshooting.
        tmid = mix(tm,tx, hm/(hm-hx));
        p = ori + dir * tmid; 
                  
    	float hmid = map(p); // bteitler: Re-evaluate height relative to ocean surface in Y axis

        if(hmid < 0.0) { // bteitler: We went through the ocean surface if we are negative relative to surface now
            // bteitler: So instead of actually marching forward to cross the surface, we instead
            // assign our really far distance and height to be where we just evaluated that crossed the surface.
            // Next iteration will attempt to go forward more and is less likely to cross the boundary.
            // A naive implementation might have returned <tmid> immediately here, which
            // results in a much poorer / somewhat indeterministic quality rendering.
            tx = tmid;
            hx = hmid;
        } else {
            // Haven't hit surface yet, easy case, just march forward
            tm = tmid;
            hm = hmid;
        }
    }

    // bteitler: Return the distance, which should be really close to the height map without going under the ocean
    return tmid;
}

void vertex()
{
	if(length(CAMERA_RELATIVE_POS) < radius + 100000000.0)
	{	
	float t;
    vec3 cameraDir;
    vec3 oceanDir;
	vec3 color_out;
	vec2 uv = oceanPos(VERTEX, INV_PROJECTION_MATRIX, t, cameraDir, oceanDir, color_out); //vertex屏幕坐标

	pointInOcean = t * cameraDir;
//	if(t > 100000.0)
//	{
//		pointInOcean.y = pointInOcean.y + 1000.0;
//	}


	float freq = SEA_FREQ;
    float amp = SEA_HEIGHT;
    float choppy = SEA_CHOPPY;
    uv.x *= 0.75;
    
    
	vertex_v = VERTEX;

	POSITION = (PROJECTION_MATRIX  * vec4(pointInOcean, 1.0));
	POSITION = POSITION / POSITION.w;
	
	}
}
void fragment(){
	
	float t;
    vec3 cameraDir;
    vec3 oceanDir;
	vec3 color_out;
	vec2 uv1 = oceanPos2(vertex_v, INV_PROJECTION_MATRIX, cameraToOcean, oceanCameraPos.y, t, cameraDir, oceanDir, color_out); //vertex屏幕坐标
	vec3 highHitPos = t * oceanDir + vec3(0.0, oceanCameraPos.y, 0.0);
    vec3 dir = normalize(oceanDir);
	vec3 ori = vec3(oceanCameraPos.x, oceanCameraPos.y, oceanCameraPos.z);
    
    // tracing

    // bteitler: ray-march to the ocean surface (which can be thought of as a randomly generated height map)
    // and store in p
    vec3 p = highHitPos;
    heightMapTracing(ori,dir,t, p);

    vec3 dist = p - ori; // bteitler: distance vector to ocean surface for this pixel's ray

    // bteitler: Calculate the normal on the ocean surface where we intersected (p), using
    // different "resolution" (in a sense) based on how far away the ray traveled.  Normals close to
    // the camera should be calculated with high resolution, and normals far from the camera should be calculated with low resolution
    // The reason to do this is that specular effects (or non linear normal based lighting effects) become fairly random at
    // far distances and low resolutions and can cause unpleasant shimmering during motion.
    vec3 n = getNormal(p, 
             dot(dist,dist)   // bteitler: Think of this as inverse resolution, so far distances get bigger at an expnential rate
                * 0.5 / VIEWPORT_SIZE.x // bteitler: Just a resolution constant.. could easily be tweaked to artistic content
           );

    // bteitler: direction of the infinitely far away directional light.  Changing this will change
    // the sunlight direction.
	vec3 lightDir = (cameraToOcean * vec4(sun_dir, 0.0)).xyz;
    vec3 light = normalize(lightDir); 
             
    // CaliCoastReplay:  Get the sky and sea colors
	vec3 skyColor = getSkyColor(dir);
    vec3 seaColor = getSeaColor(p,n,light,dir,dist);
    ALBEDO= seaColor;
    //Sea/sky preprocessing
    
    //CaliCoastReplay:  A distance falloff for the sea color.   Drastically darkens the sea, 
    //this will be reversed later based on day/night.
    seaColor /= sqrt(sqrt(length(dist))) ;
//	seaColor /= length(dist) * distFactor;
    
    
    //CaliCoastReplay:  Day/night mode
    bool night = true; 	 
	seaColor *= seaColor * 8.5;
        
        //Turn down the sky 
    	skyColor /= 1.69;
//    if( isKeyPressed(KEY_SP) > 0.0 )    //night mode!
//    {
//        //Brighten the sea up again, but not too bright at night
//    	seaColor *= seaColor * 8.5;
//
//        //Turn down the sky 
//    	skyColor /= 1.69;
//
//        //Store that it's night mode for later HSV calcc
//        night = true;
//    }
//    else  //day mode!
//    {
//        //Brighten the sea up again - bright and beautiful blue at day
//    	seaColor *= sqrt(sqrt(seaColor)) * 4.0;
//        skyColor *= 1.05;
//        skyColor -= 0.03;
//        night = false;
//    }

    
    //CaliCoastReplay:  A slight "constrasting" for the sky to match the more contrasted ocean
    skyColor *= skyColor;
    
    
    //CaliCoastReplay:  A rather hacky manipulation of the high-value regions in the image that seems
    //to add a subtle charm and "sheen" and foamy effect to high value regions through subtle darkening,
    //but it is hacky, and not physically modeled at all.  
    vec3 seaHsv = rgb2hsv(seaColor);
    if (seaHsv.z > .75 && length(dist) < 50.0)
       seaHsv.z -= (0.9 - seaHsv.z) * 1.3;
    seaColor = hsv2rgb(seaHsv);
    
    // bteitler: Mix (linear interpolate) a color calculated for the sky (based solely on ray direction) and a sea color 
    // which contains a realistic lighting model.  This is basically doing a fog calculation: weighing more the sky color
    // in the distance in an exponential manner.
    
    vec3 color = mix(
        skyColor,
        seaColor,
    	pow(smoothstep(0.0,-0.05,dir.y), 0.3) // bteitler: Can be thought of as "fog" that gets thicker in the distance
    );
    color = seaColor;
   
    // Postprocessing
    
    // bteitler: Apply an overall image brightness factor as the final color for this pixel.  Can be
    // tweaked artistically.
//    ALBEDO = vec4(pow(color,vec3(0.75)), 1.0).xyz;
	
    
    // CaliCoastReplay:  Adjust hue, saturation, and value adjustment for an even more processed look
    // hsv.x is hue, hsv.y is saturation, and hsv.z is value
//    vec3 hsv = rgb2hsv(ALBEDO.xyz);    
	
    //CaliCoastReplay: Increase saturation slightly
//    hsv.y += 0.131;
    //CaliCoastReplay:
    //A pseudo-multiplicative adjustment of value, increasing intensity near 1 and decreasing it near
    //0 to achieve a more contrasted, real-world look
//    hsv.z *= sqrt(hsv.z) * 1.1; 
    vec3 hsv = ALBEDO.xyz;
    if (night)    
    {
    ///CaliCoastReplay:
    //Slight value adjustment at night to turn down global intensity
        hsv.z -= 0.045;
        hsv*=0.8;
        hsv.x += 0.12 + hsv.z/100.0;
        //Highly increased saturation at night op, oddly.  Nights appear to be very colorful
        //within their ranges.
        hsv.y *= 2.87;
    }
    else
    {
      //CaliCoastReplay:
        //Add green tinge to the high range
      //Turn down intensity in day in a different way     
        
        hsv.z *= 0.9;
        
        //CaliCoastReplay:  Hue alteration 
        hsv.x -= hsv.z/10.0;
        hsv.x += 0.02 + hsv.z/50.0;
        //Final brightening
        hsv.z *= 1.01;
        //This really "cinemafies" it for the day -
        //puts the saturation on a squared, highly magnified footing.
        //Worth looking into more as to exactly why.
       // hsv.y *= 5.10 * hsv.y * sqrt(hsv.y);
        hsv.y += 0.07;
    }
    
    //CaliCoastReplay:    
    //Replace the final color with the adjusted, translated HSV values
//    ALBEDO.xyz = hsv2rgb(hsv);
	vec3 oceanCamera = vec3(0.0, oceanCameraPos.y, 0.0);
			float d = sqrt(oceanCamera.y * (2.0 * radius + oceanCamera.y));
		float ratio = t / d;
		float x = 2.0 / (1.0 + exp(-k1 * -k2 * ratio));
//		ALPHA = 1.0 - tanh((disToOrigin ) / (d ) * disfactor);
		ALPHA = 1.0 - 1.0 / (1.0 + exp(12.0 * x - 6.0));
//	ALBEDO = vec3(1, 0, 0);
//	ALPHA = 0.7;
}

