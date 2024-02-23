shader_type spatial;
render_mode cull_disabled, unshaded;

uniform float radius;
uniform mat4 cameraToOcean;
//uniform mat4 screenToCamera;
//uniform mat4 cameraToScreen;
uniform mat4 oceanToCamera;
uniform mat4 oceanToWorld;
uniform mat4 worldToOcean;
uniform vec3 oceanCameraPos;
uniform vec3 oceanSunDir;
uniform vec3 horizon1;
uniform vec3 horizon2;
uniform vec2 gridSize;
uniform vec4 GRID_SIZES;
uniform float maxError = 600.0;
uniform float disfactor = 1.0;
uniform float maxDis = 60000.0;

uniform float nbWaves = 60.0; // number of waves
uniform highp sampler2D wavesSampler; // waves parameters (h, omega, kx, ky) in wind space
uniform float heightOffset = 0.0; // so that surface height is centered around z = 0
//uniform float time; // current time
uniform float sea_roughness; // total variance
uniform float oceanHeight = 10;
uniform float lods_x;
uniform float lods_y;
uniform float lods_z;
uniform float lods_w;

uniform float Rg = 6378137.0;
uniform float Rt = 6420000.0;
uniform float RL = 6421000.0;
const int RES_R = 32;
const int RES_MU = 128;
const int RES_MU_S = 32;
const int RES_NU = 8;
const float M_PI = 3.141592657;

const float AVERAGE_GROUND_REFLECTANCE = 0.1;
const float SCALE = 1000.0;
// Rayleigh
const float HR = 8.0 * SCALE;
const vec3 betaR = vec3(5.8e-3, 1.35e-2, 3.31e-2) / SCALE;
// Mie
// DEFAULT
const float HM = 1.2 * SCALE;
const vec3 betaMSca = vec3(4e-3) / SCALE;
const vec3 betaMEx = (vec3(4e-3) / SCALE) / 0.9;
const float mieG = 0.8;

uniform float projecter_fov;
uniform float projecter_aspect;
uniform float projecter_near;
uniform float projecter_far;

uniform mat4 projector_to_world;
uniform mat4 projector_to_screen;
uniform mat4 range_matrix;
uniform mat4 projecter_matrix;

uniform sampler2D noise;
uniform sampler2D testTex;
uniform sampler2D transmittanceSampler;
uniform sampler2D skyIrradianceSampler;
uniform highp sampler3D inscatterSampler;
uniform float coefficient_a;
uniform float coefficient_b;
uniform float coefficient_c;
uniform float coefficient_d;
uniform float mat11;
uniform float mat22;
uniform float mat33;
uniform float mat34;
uniform vec4 wave_param_a = vec4(1, 1, 1, 1);
uniform vec4 wave_param_b = vec4(1, 1, 1, 1);
uniform vec4 wave_param_c = vec4(1, 1, 1, 1);
uniform float speed_param = 1.0;
uniform vec4 albeo_color:hint_color = vec4(0.00392, 0.0157, 0.0471, 1.0) ;
uniform vec4 deep_color:hint_color = vec4(0.1, 0.3, 0.5, 1.0);
uniform vec4 shallow_color:hint_color = vec4(0.1, 0.3, 0.5, 1.0);
uniform float deep_scale_param = 1.0;
uniform float deep_curve_param = 1.0;
uniform float ambiColor = 0.2;
uniform	float diffColor = 0.5;
uniform	float specColor = 0.3;
uniform vec3 sun_dir = vec3(0, 0, 1);
uniform float reflectivity = 1;
uniform float hdrExposure = 0.4;
uniform float sea_roughness_param = 1.0;
uniform float sky_roughness_param = 1.0;
uniform float sun_roughness_param = 1.0;
uniform float lod_param = 1.0;
uniform bool need_sky_light = true;
uniform bool need_sun_light = true;
uniform bool need_sea_light = true;
uniform vec4 sky_color:hint_color = vec4(1, 1, 1, 1);
uniform float sky_param = 1.0;
uniform bool render_type = true;
uniform bool render_view = true;
uniform float PLANET_RADIUS =  6370000.0; /* radius of the planet */
uniform float ATMOS_RADIUS = 6478137.0; /* radius of the atmosphere */
uniform float SUN_INTENSITY = 100.0;
uniform float normalMax = 0.0;
uniform float distanceMax = 40000;
uniform float distanceOffset = 100;

varying vec2 uv;
varying float shadow_factor;

varying float oceanLod;
varying vec2 oceanUv;
varying vec3 oceanP;
varying vec3 oceanDPdu;
varying vec3 oceanDPdv;
varying float oceanRoughness;
varying float oceanSigmaSq; // variance of unresolved waves in wind space
varying vec3 normal;
varying float disToOrigin;

const float Z0 = 1.0;
const float g = 9.81;
const float PI = 3.141592657;
uniform float NYQUIST_MIN = 0.5;
uniform float NYQUIST_MAX = 1.25;
uniform float k1 = 2.951;
uniform float k2 = 2.16;
uniform float k3 = 1.0;
uniform bool fadeWay = true;



//const float Rg = 6360.0 * SCALE;
//const float Rt = 6420.0 * SCALE;
//const float RL = 6421.0 * SCALE;





mat4 get_projection_matrix()
{

	mat4 projection_matrix = mat4(
		vec4(mat11, 0, 0, 0),
		vec4(0, mat22, 0, 0),
		vec4(0, 0, mat33, -1),
		vec4(0, 0, mat34, 0)
	);
	return projection_matrix;
}
mat4 get_inv_camera_matrix(vec3 up, vec3 direction, vec3 camera_position) //世界空间到视图空间矩阵
{
	vec3 N = normalize(-direction);
	vec3 U = normalize(cross(up, N));
	vec3 V = normalize(cross(N, U));
	mat4 inv_camera_matrix = mat4(
		vec4(U.x, V.x, N.x, 0),
		vec4(U.y, V.y, N.y, 0),
		vec4(U.z, V.z, N.z, 0),
		vec4(-dot(U, camera_position), -dot(V, camera_position), -dot(N, camera_position), 1)
	);
	return inv_camera_matrix;
}

void get_horizon(mat4 stoc, out vec3 horizon1U, out vec3 horizon2U)
{
	float h = oceanCameraPos.y; // 相机相对海洋的高度
	vec4 A0_vec4 = stoc * vec4(-1.0, -1.0, -1.0, 1.0);
    vec3 A0 = (cameraToOcean * vec4(A0_vec4.xyz / A0_vec4.w, 0.0)).xyz;
	vec4 dA_vec4 = stoc * vec4(1.0, -1.0, -1.0, 0.0);
    vec3 dA = (cameraToOcean * vec4(dA_vec4.xyz / dA_vec4.w, 0.0)).xyz;
	vec4 B_vec4 = stoc * vec4(-1.0, 1.0, -1.0, 0.0);
    vec3 B = (cameraToOcean * vec4(B_vec4.xyz / B_vec4.w, 0.0)).xyz;
    if (radius == 0.0)
    {
		horizon1U = vec3(-(h * 1e-6 + A0.z) / B.z, -dA.z / B.z, 0.0);
		horizon2U = vec3(0);
    }
    else
    {
        float h1 = h * (h + 2.0 * radius);
        float h2 = (h + radius) * (h + radius);
        float alpha = dot(B, B) * h1 - B.z * B.z * h2;
        float beta0 = (dot(A0, B) * h1 - B.z * A0.z * h2) / alpha;
        float beta1 = (dot(dA, B) * h1 - B.z * dA.z * h2) / alpha;
        float gamma0 = (dot(A0, A0) * h1 - A0.z * A0.z * h2) / alpha;
        float gamma1 = (dot(A0, dA) * h1 - A0.z * dA.z * h2) / alpha;
        float gamma2 = (dot(dA, dA) * h1 - dA.z * dA.z * h2) / alpha;
		horizon1U = vec3(-beta0, -beta1, 0.0);
		horizon2U = vec3(beta0 * beta0 - gamma0, 2.0 * (beta0 * beta1 - gamma1), beta1 * beta1 - gamma2);
    }
}

vec2 ray_sphere_intersect(
    vec3 start, // starting position of the ray
    vec3 dir, // the direction of the ray
	vec3 origin,
    float oceanRadius // and the sphere radius
) {
    // ray-sphere intersection that assumes
    // the sphere is centered at the origin.
    // No intersection when result.x > result.y
    float a = dot(dir, dir);
    float b = 2.0 * (dot(dir, start) - dot(origin, dir));
    float c = -2.0 * dot(origin, start) + dot(start, start) + dot(origin, origin) - (oceanRadius * oceanRadius);
    float d = (b*b) - 4.0*a*c;
    if (d < 0.0) return vec2(1e5,-1e5);
    return vec2(
        (-b - sqrt(d))/(2.0*a),
        (-b + sqrt(d))/(2.0*a)
    );
}
varying vec3 color;
varying flat float IsDiscard;

float wave(vec2 position){
  position += texture(noise, position / 10.0).x * 2.0 - 1.0;
  vec2 wv = 1.0 - abs(sin(position));
  return pow(1.0 - pow(wv.x * wv.y, 0.65), 4.0);
}
float height(vec2 position, float time) {
  float d = wave((position + time) * 0.4) * 0.3;
  d += wave((position - time) * 0.3) * 0.3;
  d += wave((position + time) * 0.5) * 0.2;
  d += wave((position - time) * 0.6) * 0.2;
  return d;
}

float SineWave(vec4 waveParam,  float speed, float x, float z, float lod, out vec3 tangent, out vec3 bitangent)
        {
            float amplitude = abs(waveParam.x);
			float waveLength = waveParam.y;
			float k = 2.0 * PI / waveLength;
			float fx = k * (x - speed);
			float fz = k * (z - speed + 0.5);
//            float waveOffset = amplitude * sin(k * (x - speed));
			float waveOffset = amplitude * sin(fx) + amplitude * sin(fz);
			tangent = normalize(vec3(1, amplitude * k * cos(fx), 0));
            bitangent = normalize(vec3(0, amplitude * k * cos(fz), 1));
            return waveOffset;
        }
vec3 GerstnerWave(vec4 waveParam, float time, vec3 positionOS, out vec3 tangent, out vec3 bitangent)
 {
    vec3 position = vec3(0);

    vec2 direction = normalize(waveParam.xy);
            
    float waveLength = waveParam.w;
            
    float k = 2.0 * PI / waveLength;

    // 这里限制一下z让z永远不超过1
    waveParam.z = abs(waveParam.z) / (abs(waveParam.z) + 1.0);
    float amplitude = waveParam.z / k;

    float speed = sqrt(9.8 / k);
            
    float f = k * (dot(direction, positionOS.xy) - speed * time);
            
    position.y = amplitude * sin(f);
    position.z = amplitude * cos(f) * direction.x;
    position.x = amplitude * cos(f) * direction.y;

    float yy = amplitude * k * cos(f);
    tangent =  normalize(vec3(1.0 - amplitude * k * sin(f) * direction.x * direction.x, yy, 0));
    bitangent =  normalize(vec3(0, yy, 1.0 - amplitude * k * sin(f) * direction.y * direction.y));
	tangent += vec3(-amplitude * k * sin(f) * direction.x * direction.x, yy * direction.x, -amplitude * sin(f) * direction.y * k * direction.x);
    
    bitangent += vec3(-amplitude * k * sin(f) * direction.x * direction.y, yy * direction.y, -amplitude * k * sin(f) * direction.y * direction.y);
    return position;
}
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
float SQRT(float f, float err) {
//#ifdef OPTIMIZE
//    return sqrt(f);
//#else
    return f >= 0.0 ? sqrt(f) : err;
//#endif
}
// optical depth for ray (r,mu) of length d, using analytic formula
// (mu=cos(view zenith angle)), intersections with ground ignored
// H=height scale of exponential density function
float opticalDepth(float H, float r, float mu, float d) {
    float a = sqrt((0.5/H)*r);
    vec2 a01 = a*vec2(mu, mu + d / r);
    vec2 a01s = sign(a01);
    vec2 a01sq = a01*a01;
    float x = a01s.y > a01s.x ? exp(a01sq.x) : 0.0;
    vec2 y = a01s / (2.3193*abs(a01) + sqrt(1.52*a01sq + 4.0)) * vec2(1.0, exp(-d/H*(d/(2.0*r)+mu)));
    return sqrt((6.2831*H)*r) * exp((Rg-r)/H) * (x + dot(y, vec2(1.0, -1.0)));
}
// transmittance(=transparency) of atmosphere for ray (r,mu) of length d
// (mu=cos(view zenith angle)), intersections with ground ignored
// uses analytic formula instead of transmittance texture
vec3 analyticTransmittance(float r, float mu, float d) {
    return exp(- betaR * opticalDepth(HR, r, mu, d) - betaMEx * opticalDepth(HM, r, mu, d));
}

vec4 texture4D(highp sampler3D table, float r, float mu, float muS, float nu)
{
    float H = sqrt(Rt * Rt - Rg * Rg);
    float rho = sqrt(r * r - Rg * Rg);
//#ifdef INSCATTER_NON_LINEAR
    float rmu = r * mu;
    float delta = rmu * rmu - r * r + Rg * Rg;
    vec4 cst = rmu < 0.0 && delta > 0.0 ? vec4(1.0, 0.0, 0.0, 0.5 - 0.5 / float(RES_MU)) : vec4(-1.0, H * H, H, 0.5 + 0.5 / float(RES_MU));
    float uR = 0.5 / float(RES_R) + rho / H * (1.0 - 1.0 / float(RES_R));
    float uMu = cst.w + (rmu * cst.x + sqrt(delta + cst.y)) / (rho + cst.z) * (0.5 - 1.0 / float(RES_MU));
    // paper formula
    //float uMuS = 0.5 / float(RES_MU_S) + max((1.0 - exp(-3.0 * muS - 0.6)) / (1.0 - exp(-3.6)), 0.0) * (1.0 - 1.0 / float(RES_MU_S));
    // better formula
    float uMuS = 0.5 / float(RES_MU_S) + (atan(max(muS, -0.1975) * tan(1.26 * 1.1)) / 1.1 + (1.0 - 0.26)) * 0.5 * (1.0 - 1.0 / float(RES_MU_S));
//#else
//    float uR = 0.5 / float(RES_R) + rho / H * (1.0 - 1.0 / float(RES_R));
//    float uMu = 0.5 / float(RES_MU) + (mu + 1.0) / 2.0 * (1.0 - 1.0 / float(RES_MU));
//    float uMuS = 0.5 / float(RES_MU_S) + max(muS + 0.2, 0.0) / 1.2 * (1.0 - 1.0 / float(RES_MU_S));
//#endif
    float lerp = (nu + 1.0) / 2.0 * (float(RES_NU) - 1.0);
    float uNu = floor(lerp);
    lerp = lerp - uNu;
    return texture(table, vec3((uNu + uMuS) / float(RES_NU), uMu, uR)) * (1.0 - lerp) +
           texture(table, vec3((uNu + uMuS + 1.0) / float(RES_NU), uMu, uR)) * lerp;
}

// Rayleigh phase function
float phaseFunctionR(float mu) {
    return (3.0 / (16.0 * M_PI)) * (1.0 + mu * mu);
}

// Mie phase function
float phaseFunctionM(float mu) {
    return 1.5 * 1.0 / (4.0 * M_PI) * (1.0 - mieG*mieG) * pow(1.0 + (mieG*mieG) - 2.0*mieG*mu, -3.0/2.0) * (1.0 + mu * mu) / (2.0 + mieG*mieG);
}

// approximated single Mie scattering (cf. approximate Cm in paragraph "Angular precision")
vec3 getMie(vec4 rayMie) { // rayMie.rgb=C*, rayMie.w=Cm,r
    return rayMie.rgb * rayMie.w / max(rayMie.r, 1e-4) * (betaR.r / betaR);
}
// single scattered sunlight between two points
// camera=observer
// point=point on the ground
// sundir=unit vector towards the sun
// return scattered light and extinction coefficient
vec3 inScattering(vec3 camera, vec3 point, vec3 sundir, out vec3 extinction, float shaftWidth) {
//#if defined(ATMO_INSCATTER_ONLY) || defined(ATMO_FULL)
    vec3 result;
    vec3 viewdir = point - camera;
    float d = length(viewdir);
    viewdir = normalize(viewdir);
    float r = length(camera);
    if (r < 0.9 * Rg) {
        camera.z += Rg;
        point.z += Rg;
        r = length(camera);
    }
    float rMu = dot(camera, viewdir);
    float mu = rMu / r;
    float r0 = r;
    float mu0 = mu;
    point -= viewdir * clamp(shaftWidth, 0.0, d);

    float deltaSq = SQRT(rMu * rMu - r * r + Rt*Rt, 1e30);
    float din = max(-rMu - deltaSq, 0.0);
    if (din > 0.0 && din < d) {
        camera += din * viewdir;
        rMu += din;
        mu = rMu / Rt;
        r = Rt;
        d -= din;
    }

    if (r <= Rt) {
        float nu = dot(viewdir, sundir);
        float muS = dot(camera, sundir) / r;

        vec4 inScatter;

        if (r < Rg + maxError) {
            // avoids imprecision problems in aerial perspective near ground
            float f = (Rg + maxError) / r;
            r = r * f;
            rMu = rMu * f;
            point = point * f;
        }

        float r1 = length(point);
        float rMu1 = dot(point, viewdir);
        float mu1 = rMu1 / r1;
        float muS1 = dot(point, sundir) / r1;
//		if(ANALYTIC_TRANSMITTANCE)
//		{
	        extinction = min(analyticTransmittance(r, mu, d), 1.0);
//		}
//		else
//		{
//			if (mu > 0.0) {
//            	extinction = min(transmittance(r, mu) / transmittance(r1, mu1), 1.0);
//        	} else {
//            	extinction = min(transmittance(r1, -mu1) / transmittance(r, -mu), 1.0);
//        	}
//		}
        
//#endif

//#ifdef HORIZON_HACK
        const float EPS = 0.004;
        float lim = -sqrt(1.0 - (Rg / r) * (Rg / r));
        if (abs(mu - lim) < EPS) {
            float a = ((mu - lim) + EPS) / (2.0 * EPS);

            mu = lim - EPS;
            r1 = sqrt(r * r + d * d + 2.0 * r * d * mu);
            mu1 = (r * mu + d) / r1;
            vec4 inScatter0 = texture4D(inscatterSampler, r, mu, muS, nu);
            vec4 inScatter1 = texture4D(inscatterSampler, r1, mu1, muS1, nu);
            vec4 inScatterA = max(inScatter0 - inScatter1 * extinction.rgbr, 0.0);

            mu = lim + EPS;
            r1 = sqrt(r * r + d * d + 2.0 * r * d * mu);
            mu1 = (r * mu + d) / r1;
            inScatter0 = texture4D(inscatterSampler, r, mu, muS, nu);
            inScatter1 = texture4D(inscatterSampler, r1, mu1, muS1, nu);
            vec4 inScatterB = max(inScatter0 - inScatter1 * extinction.rgbr, 0.0);

            inScatter = mix(inScatterA, inScatterB, a);
        } else {
            vec4 inScatter0 = texture4D(inscatterSampler, r, mu, muS, nu);
            vec4 inScatter1 = texture4D(inscatterSampler, r1, mu1, muS1, nu);
            inScatter = max(inScatter0 - inScatter1 * extinction.rgbr, 0.0);
        }
//#else
//        vec4 inScatter0 = texture4D(inscatterSampler, r, mu, muS, nu);
//        vec4 inScatter1 = texture4D(inscatterSampler, r1, mu1, muS1, nu);
//        inScatter = max(inScatter0 - inScatter1 * extinction.rgbr, 0.0);
//#endif

        //cancels inscatter when sun hidden by mountains
        //TODO smoothstep values depend on horizon angle in sun direction
        //inScatter.w *= smoothstep(0.035, 0.07, muS);

        // avoids imprecision problems in Mie scattering when sun is below horizon
        inScatter.w *= smoothstep(0.00, 0.02, muS);

        vec3 inScatterM = getMie(inScatter);
        float phase = phaseFunctionR(nu);
        float phaseM = phaseFunctionM(nu);
        result = inScatter.rgb * phase + inScatterM * phaseM;
    } else {
        result = vec3(0.0);
        extinction = vec3(1.0);
    }

    return result * SUN_INTENSITY;
//#else
//    extinction = vec3(1.0);
//    return vec3(0.0);
//#endif
}

varying vec3 pointInOcean;
void vertex()
{
	if(length(CAMERA_RELATIVE_POS) < radius + 100000000.0)
	{	
	float t;
    vec3 cameraDir;
    vec3 oceanDir;
	vec3 color_out;
	uv = oceanPos(VERTEX, INV_PROJECTION_MATRIX, t, cameraDir, oceanDir, color_out); //vertex屏幕坐标
	color = color_out;
    vec3 tangent = vec3(0);
	vec3 bitangent = vec3(0);
	float lod = - t / oceanDir.y * lods_y; // size in meters of one grid cell, projected on the sea surface
	vec3 L = sun_dir;
	float _0f;
	vec3 _0, _1;
//	vec2 duv = oceanPos(VERTEX + vec3(0.0, 0.01, 0.0), INV_PROJECTION_MATRIX, horizon1, horizon1, _0f, _0, _1) - uv;
	vec2 duv = oceanPos(VERTEX + vec3(0.0, 0.01, 0.0), INV_PROJECTION_MATRIX,  _0f, _0, _1, color_out) - uv;
    vec3 dP = vec3(0.0, heightOffset + (radius > 0.0 ? 0.0 : Z0), 0.0);
    vec3 dPdu = vec3(0.0, 0.0, 1.0);
    vec3 dPdv = vec3(1.0, 0.0, 0.0);
	float sigmaSq = sea_roughness;
	color = vec3(1, 0, 0);
    if (duv.x != 0.0 || duv.y != 0.0) {
        float iMin = max(floor((log2(NYQUIST_MIN * lod) - lods_z) * lods_w), 0.0);
        for (float i = iMin; i < nbWaves; ++i) {
            vec4 wt = textureLod(wavesSampler, vec2((i + 0.5) / nbWaves), 0.0);
//			wt.yzw = wt.yzw * 100.0;
            float phase = wt.y * TIME * speed_param - dot(wt.zw, uv); //wt.y  sqrt(9.81f * (2.0f * M_PI_F / lambda));
            float s = sin(phase);
            float c = cos(phase);
            float overk = g / (wt.y * wt.y);  // lambda / 2Pi

            float wm = smoothstep(NYQUIST_MIN, NYQUIST_MAX, (2.0 * PI) * overk / lod);
            vec3 factor = wm * wt.x * vec3(wt.w * overk, 1.0, wt.z * overk);  //cos，1，sin ,单位方向向量

            dP += factor * vec3(s, c, s);

            vec3 dPd = factor * vec3(c, -s, c);
            dPdu -= dPd * wt.z;
            dPdv -= dPd * wt.w;

            wt.zw *= overk;
            float kh = wt.x / overk;
            sigmaSq -= wt.w * wt.w * (1.0 - sqrt(1.0 - kh * kh));
        }
    }
	else
	{
		color = vec3(0, 1, 0);
	}
    vec3 p = t * oceanDir + dP + vec3(0.0, oceanCameraPos.y, 0.0);
    if (radius > 0.0) {
        dPdu += vec3(0.0, -p.x / (radius + p.y), 0.0);
        dPdv += vec3(0.0, -p.z / (radius + p.y), 0.0);
    }
//	dP = vec3(0.0, heightOffset + (radius > 0.0 ? 0.0 : Z0), 0.0);
//	pointInOcean = t * cameraDir + (oceanToCamera * vec4(offsetx, height * 1.0, offsetz, 0)).xyz;
//	pointInOcean = vec4(0, 0, 0, 1).xyz + t * cameraDir;
	float offset = t > distanceMax? distanceOffset : 1.0;
	pointInOcean = t * cameraDir + (oceanToCamera * vec4(dP * offset, 0.0)).xyz;
	if(t > distanceMax)
	{
		color = vec3(1, 0, 0);
//		pointInOcean = pointInOcean - distanceOffset;
	}
	else
	{
		color = vec3(0, 1, 0);
	}
//	if(abs(length(dP)) <= 0.01)
//	{
//		color = vec3(1, 0, 0);
//	}
//	else
//	{
//		color = vec3(0, 1, 0);
//	}
	
//	vec4 vv = inverse(WORLD_MATRIX) * inverse(INV_CAMERA_MATRIX) * vec4( pointInOcean, 1.0);
//	VERTEX =  vv.xyz;
//	NORMAL = -normalize((inverse(INV_CAMERA_MATRIX) * vec4(pointInOcean, 1.0)).xyz + CAMERA_RELATIVE_POS.xyz);
//    POSITION = PROJECTION_MATRIX * vec4(t * cameraDir + oceanToCamera * dP, 1.0);
	
//	NORMAL = normalize((inverse(oceanToWorld) * vec4(NORMAL, 0.0)).xyz);
	POSITION = (PROJECTION_MATRIX  * vec4(pointInOcean, 1.0));
	POSITION = POSITION / POSITION.w;
	
//	oceanLod = lod;
//    oceanP = p;
//    oceanDPdu = dPdu;
//    oceanDPdv = dPdv;
//    oceanRoughness = roughness;
	
	oceanLod = lod;
    oceanP = p;
    oceanDPdu = dPdu;
    oceanDPdv = dPdv;
    oceanSigmaSq = sigmaSq;
	normal = -normalize(cross(dPdu, dPdv));
	disToOrigin = t;
	
	}
}


vec3 ACESFilm( vec3 x )
{
    float tA = 2.51;
    float tB = 0.03;
    float tC = 2.43;
    float tD = 0.59;
    float tE = 0.14;
    return clamp((x*(tA*x+tB))/(x*(tC*x+tD)+tE),0.0,1.0);
}
void fragment(){
	
	
//	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
//
//	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
//	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
//	vec4 world = cameraToOcean * vec4(view);
//	vec3 world_pos =  world.xyz / world.w;
//	float d = sqrt(world_pos.x * world_pos.x + world_pos.z * world_pos.z);
////	float waterDepth = radius - sqrt((radius - d) * (radius + d));
//	float waterDepth = -world_pos.y;
//	waterDepth = waterDepth / max(deep_scale_param, 1); 
////
////	vec4 world = CAMERA_MATRIX * vec4(view);
////	vec3 world_pos =  world.xyz / world.w + CAMERA_RELATIVE_POS.xyz;
////	float waterDepth = radius - length(world_pos) / max(deep_scale_param, 1); 
////
//    float deepFactor = exp2(-deep_curve_param * waterDepth);
//	ALPHA = clamp(mix(deep_color.a, shallow_color.a, deepFactor), 0, 1);
	
	
//
////	ALBEDO = (mix(deep_color.rgb, albeo_color.rgb, deepFactor) + texture(testTex, uv * 0.01).xyz) * shadow_factor;
//
//	ALBEDO = mix(deep_color.rgb, albeo_color.rgb, deepFactor) * shadow_factor;
//    ALBEDO = color; 
            

//	ALBEDO = color;
//	ALPHA = 1.0;
//	METALLIC = 0.0;
//	float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));
//    ROUGHNESS = 0.01 * (1.0 - fresnel);

//	ALBEDO = texture(testTex, UV).xyz;
//	vec3 pos = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz + CAMERA_RELATIVE_POS.xyz;
//	NORMAL = -normalize((inverse(INV_CAMERA_MATRIX) * vec4(pointInOcean, 1.0)).xyz + CAMERA_RELATIVE_POS.xyz);
	

	
	vec3 WSD = sun_dir;
    vec3 WCP = CAMERA_RELATIVE_POS.xyz;
    float lod = oceanLod;
    vec3 dPdu = oceanDPdu;
    vec3 dPdv = oceanDPdv;
//	dPdu = vec3(1, 0, 0);
//	dPdv = vec3(0, 0, 1);
    float roughness = oceanSigmaSq;
//	float iMin = max(0.0, floor((log2(NYQUIST_MIN * lod) - lods_z) * lods_w));
    float iMAX = min(ceil((log2(NYQUIST_MAX * lod) - lods_z) * lods_w), nbWaves - 1.0);
    float iMax = floor((log2(NYQUIST_MIN * lod) - lods_z) * lods_w);
    float iMin = max(0.0, floor((log2(NYQUIST_MIN * lod / lods_x) - lods_z) * lods_w));
    for (float i = iMin; i <= nbWaves; i += 1.0) {
        vec4 wt = texture(wavesSampler, vec2((i + 0.5) / nbWaves, 0), 0.0);
//		wt.yzw = wt.yzw * 100.0;
        float phase = wt.y * TIME * speed_param - dot(wt.zw, uv); //wt.y  sqrt(9.81f * (2.0f * M_PI_F / lambda));
        float s = sin(phase);
        float c = cos(phase);
        float overk = g / (wt.y * wt.y); // lambda / 2Pi

        float wm = smoothstep(NYQUIST_MIN, NYQUIST_MAX, (2.0 * PI) * overk / lod);
        float wn = smoothstep(NYQUIST_MIN, NYQUIST_MAX, (2.0 * PI) * overk / lod * lods_x);
        vec3 factor = (1.0 - wm) * wn * wt.x * vec3(wt.w * overk, 1.0, wt.z * overk);//wt.x 振幅


// 		float wm = smoothstep(NYQUIST_MIN, NYQUIST_MAX, (2.0 * PI) * overk / lod);
//        vec3 factor = wm * wt.x * vec3(wt.z * overk, 1.0, wt.w * overk);  //cos，1，sin ,单位方向向量

        vec3 dPd = factor * vec3(c, -s, c);
        dPdu -= dPd * wt.z;
        dPdv -= dPd * wt.w;

        wt.zw *= overk;
        float kh = i < iMax ? wt.x / overk : 0.0;
        float wkh = (1.0 - wn) * kh;
        roughness -= wt.w * wt.w * (sqrt(1.0 - wkh * wkh) - sqrt(1.0 - kh * kh));
    }

    roughness = max(roughness, 0.001);
//	roughness = 0.0;

    vec3 earthCamera = vec3(0.0, oceanCameraPos.y + radius, 0.0);
    vec3 earthP = radius > 0.0 ? normalize(oceanP + vec3(0.0, radius, 0.0)) * (radius + 10.0) : oceanP;

    vec3 oceanCamera = vec3(0.0, oceanCameraPos.y, 0.0);
	vec3 V = normalize(oceanCamera - oceanP);
	vec3 B = dFdx(oceanP);
	vec3 T = dFdy(oceanP);
	vec3 N2 = normalize(cross(B, T));
	    vec3 N = normalize(cross(dPdu, dPdv));
//	N = -normal;
vec3 cc = vec3(1, 0, 0);
    if (dot(V, N) < normalMax) {
        N = (reflect(N, V)); // reflects backfacing normals
		cc = vec3(0, 1, 0);
    }
//	NORMAL = (INV_CAMERA_MATRIX * oceanToWorld * vec4(N, 0.0)).xyz;
	vec3 L = normalize((worldToOcean * vec4(sun_dir, 0.0)).xyz);
    vec3 sunL = vec3(1, 1, 1) * 1.0;
    vec3 skyE = vec3(1, 1, 1) * sky_param;
    vec3 extinction;
    sunRadianceAndSkyIrradiance(earthP, N, L, sunL, skyE);

    vec3 worldP = (oceanToWorld * vec4(oceanP, 1.0)).xyz;
//
	vec3 Lsun = need_sun_light ? wardReflectedSunRadiance(L, V, N, roughness * sun_roughness_param) * sunL : vec3(0);
	vec3 Lsky = need_sky_light ? meanFresnel2(V, N, roughness * sky_roughness_param) * skyE * sky_param / PI : vec3(0);
	
//    sunL *= cloudsShadow(worldP, WSD, 0.0, dot(normalize(worldP), WSD), radius);
	vec3 Lsea = need_sea_light ? refractedSeaRadiance(V, N, roughness * sea_roughness_param) * albeo_color.xyz * skyE / PI : vec3(0);
//    vec3 surfaceColor = oceanRadiance1(V, N, oceanSunDir, roughness, vec3(1.0,1.0,1.0) * 10.0, vec3(1.0,1.0,1.0), albeo_color.xyz * 0.1);
//	vec3 surfaceColor = (Lsea + Lsun + Lsky);
//    // aerial perspective
//    vec3 inscatter = inScattering(earthCamera, earthP, oceanSunDir, extinction, 0.0);
//    vec3 finalColor = surfaceColor * extinction + inscatter;
	float dotNV = max(1e-6, dot(N, V));
	float dotNL = max(1e-6, dot(N, L));
	float factor = max(dotNL / (dotNL + dotNV), 0.1);
//	float factor = max(dotNL, 0.6);
	


//    ALBEDO = surfaceColor + texture(testTex, uv * 0.01).xyz;
	if(render_type == true)
	{
		float v = dot(V, N);
		ALBEDO = vec3(v, v, v);
	}
	else
	{
		ALBEDO = cc;
	}
	ALBEDO = hdr(Lsea + Lsun + Lsky * sky_color.xyz);
//	ALBEDO = Lsun; //hdr(Lsea + Lsun + Lsky);
	if(fadeWay)
	{
		if(disToOrigin > maxDis)
		{

			float d = sqrt(oceanCamera.y * (2.0 * radius + oceanCamera.y));
			ALPHA = 1.0 - tanh((disToOrigin - maxDis) / (d - k3 - maxDis) * disfactor);

		}
	}
	else
	{
		float d = sqrt(oceanCamera.y * (2.0 * radius + oceanCamera.y));
		float ratio = disToOrigin / d;
		float x = 2.0 / (1.0 + exp(-k1 * -k2 * ratio));
//		ALPHA = 1.0 - tanh((disToOrigin ) / (d ) * disfactor);
		ALPHA = 1.0 - 1.0 / (1.0 + exp(12.0 * x - 6.0));
	}
	
//	ALBEDO = vec3(tanh(disToOrigin * 0.1));
}

//void vertex(){
////	if(length(CAMERA_RELATIVE_POS) < radius + 10000000.0)
////	{	
//		float height = height(VERTEX.xy, TIME * 0.1) ;
//		mat4 projector_to_screen0 = projector_to_screen;
//		projector_to_screen0[2][3] = -1.0;
//		projector_to_screen0[3][3] = 0.0;
//		mat4 screen_to_projector = inverse(projector_to_screen0);
////		vec4 startInProjSpace = vec4(VERTEX.x, VERTEX.y, 0.0, 1.0);
////		vec4 endInProjSpace = vec4(VERTEX.x, VERTEX.y, 1.0, 1.0);
//		vec4 startInProjSpace = vec4(VERTEX.x * 2.0 - 1.0, VERTEX.y * 2.0 - 1.0, -1.0, 1.0);
//		vec4 endInProjSpace = vec4(VERTEX.x * 2.0 - 1.0, VERTEX.y * 2.0 - 1.0, 1.0, 1.0);
//		vec4 startInWolrdSpace = CAMERA_MATRIX * INV_PROJECTION_MATRIX * startInProjSpace;
//		vec4 endInWolrdSpace = CAMERA_MATRIX * INV_PROJECTION_MATRIX * endInProjSpace;
////		vec4 startInWolrdSpace = projector_to_world * screen_to_projector * range_matrix * startInProjSpace;
////		vec4 endInWolrdSpace = projector_to_world * screen_to_projector * range_matrix * endInProjSpace;
//		startInWolrdSpace.xyz = startInWolrdSpace.xyz / startInWolrdSpace.w;
//		endInWolrdSpace.xyz = endInWolrdSpace.xyz / endInWolrdSpace.w;
////		startInWolrdSpace.xyz = startInWolrdSpace.xyz / startInWolrdSpace.w;
////		endInWolrdSpace.xyz = endInWolrdSpace.xyz / endInWolrdSpace.w;
////		vec3 view = normalize(endInWolrdSpace.xyz - startInWolrdSpace.xyz);
//		vec3 view;
//		vec3 oceanDir;
//		float t;
//		vec3 color_out;
//		vec2 intersect = oceanPos(VERTEX * 2.0 - 1.0, INV_PROJECTION_MATRIX, t, view, oceanDir, color_out);
//		color = color_out;
////		vec2 intersect = ray_sphere_intersect(startInWolrdSpace.xyz, view, -CAMERA_RELATIVE_POS.xyz, radius + 3.0);
////		if(length(startInWolrdSpace.xyz) > 100000.0)
////			{
////				color = vec3(1, 0, 0);
////			}
////			else
////			{
////				color = vec3(0, 1, 0);
////			}
//		vec4 fff = projecter_matrix * vec4(0, 0, -1, 1);
//		fff.xyz = fff.xyz / fff.w;
////		if(abs((projecter_matrix[3][1]) - 25483907.0) < 10.0)
////		{
////			color = vec3(1, 0, 0);
////		}
////		else
////		{
////			color = vec3(0, 1, 0);
////		}
////		if(intersect.y > 0.0 && intersect.x < intersect.y)
////		{
////			vec3 pointInOcean = (inverse(cameraToOcean) * vec4(0.0, 0.5, 0.0, 1.0)).xyz + t * normalize(view);
//
////			NORMAL = -normalize(pointInOcean);
////			pointInOcean = pointInOcean - CAMERA_RELATIVE_POS.xyz;
////			vec3 pointInOcean = startInWolrdSpace.xyz + (intersect.x) * view;
////			vec3 pointInView = (INV_CAMERA_MATRIX * vec4(pointInOcean, 1.0)).xyz;
//
////			VERTEX =  pointInOcean.xyz;
//			vec3 pointInOcean = vec3(0, height, 0) + t * view;
//			vec4 vv = inverse(WORLD_MATRIX) * inverse(INV_CAMERA_MATRIX) * vec4( pointInOcean, 1.0);
//			VERTEX =  vv.xyz;
//
//			POSITION = (PROJECTION_MATRIX  * vec4(pointInOcean, 1.0));
//			POSITION = POSITION / POSITION.w;
//			IsDiscard = -1.0;
////			if(abs(length(VERTEX)- (radius)) < 2.0)
////			{
//////				IsDiscard = 1.0;
////				color = vec3(0, 0, 1);
////			}
////			else
////			{
////				color = vec3(0, 0, 1);
////			}
////		}
////		else
////		{
////			VERTEX = endInWolrdSpace.xyz;
//////			POSITION = vec4(VERTEX.x, VERTEX.y, 1.0, 1.0);
////			IsDiscard = 1.0;
//////			color = vec3(1, 0, 0)
////		}
////	}
//}

//vec2 oceanPos(vec3 vertex, mat4 screenToCamera,  vec3 horizon1, vec3 horizon2, out float t, out vec3 cameraDir, out vec3 oceanDir) {
//    float horizon = horizon1.x + horizon1.y * vertex.x - sqrt(horizon2.x + (horizon2.y + horizon2.z * vertex.x) * vertex.x);
//    cameraDir = normalize((screenToCamera * vec4(vertex.x, min(vertex.y, horizon), -1.0, 1.0)).xyz); //视图空间近平面上的点
////	cameraDir = normalize((screenToCamera * vec4(vertex.x, vertex.y, -1.0, 1.0)).xyz); //视图空间近平面上的点
//    oceanDir = (cameraToOcean * vec4(cameraDir, 0.0)).xyz; //转到海洋空间近平面上的点
//    float cz = oceanCameraPos.z;  //海洋空间相机位置z分量
//    float dz = oceanDir.y;  //海洋空间近平面上的点的z分量
//    if (radius == 0.0) {
//        t = (heightOffset + Z0 - cz) / dz;
//    } else { //求与海面的交点
//        float b = dz * (cz + radius);
//        float c = cz * (cz + 2.0 * radius);
//        float tSphere = - b - sqrt(max(b * b - c, 0.0));
//        float tApprox = - cz / dz * (1.0 + cz / (2.0 * radius) * (1.0 - dz * dz));
//        t = abs((tApprox - tSphere) * dz) < 1.0 ? tApprox : tSphere;
//    }
//    return oceanCameraPos.zx + t * oceanDir.zx;
//}