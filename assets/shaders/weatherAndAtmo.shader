shader_type spatial;
render_mode cull_disabled, unshaded, depth_test_disable;

uniform sampler2D screen_texture;
uniform sampler2D iChannel3;

uniform bool snowy = false;
uniform bool rainy = false;
uniform bool flash = false;

uniform vec4 rainy_color : hint_color = vec4(0.9411,0.9764,1.0,1.0);
uniform float wind_direction : hint_range(-1.5,1.5,0.1) = -0.5; // 风向
uniform float speed : hint_range(0,100,2) = 10; // 速度
uniform int rainy_count : hint_range(0,500,5) = 50; // 粒子数量
uniform int snowy_count : hint_range(0,500,5) = 50; // 粒子数量
uniform float flash_frequency : hint_range(4.0,12.0,0.5) = 8; // 闪电频率
uniform float flash_strength :  hint_range(0.5,4.0,0.5) = 2; // 闪电亮度


uniform bool need_atmosphere = false;


uniform bool use_shadow = true;


uniform float reflectivity = 1;


uniform vec3 sun_dir = vec3(0, 0, 1);


uniform float height = 8848;




uniform vec4 absorption_factor = vec4(1, 1, 1, 1);




uniform float SUN_INTENSITY = 15.0;
uniform float mixFactor = 0.5;
uniform float mixFactor2 = 0.5;
uniform float scaleFactor = 0.5;
uniform float maxDistance = 1000000.0;
uniform float maxError = 600.0;
uniform bool ANALYTIC_TRANSMITTANCE = true;

// ----------------------------------------------------------------------------
// PHYSICAL MODEL PARAMETERS
// ----------------------------------------------------------------------------

const float SCALE = 1000.0;

uniform float Rg = 6378137.0;
uniform float Rt = 6420000.0;
uniform float RL = 6421000.0;
uniform float alpha = 0.5;
uniform float alpha2 = 0.5;
const float AVERAGE_GROUND_REFLECTANCE = 0.1;

// Rayleigh
const float HR = 8.0 * SCALE;
const vec3 betaR = vec3(5.8e-3, 1.35e-2, 3.31e-2) / SCALE;

// Mie
// DEFAULT
const float HM = 1.2 * SCALE;
const vec3 betaMSca = vec3(4e-3) / SCALE;
const vec3 betaMEx = (vec3(4e-3) / SCALE) / 0.9;
const float mieG = 0.8;
// CLEAR SKY
/*const float HM = 1.2 * SCALE;
const vec3 betaMSca = vec3(20e-3) / SCALE;
const vec3 betaMEx = betaMSca / 0.9;
const float mieG = 0.76;*/
// PARTLY CLOUDY
/*const float HM = 3.0 * SCALE;
const vec3 betaMSca = vec3(3e-3) / SCALE;
const vec3 betaMEx = betaMSca / 0.9;
const float mieG = 0.65;*/

const float M_PI = 3.141592657;

// ----------------------------------------------------------------------------
// NUMERICAL INTEGRATION PARAMETERS
// ----------------------------------------------------------------------------

const int TRANSMITTANCE_INTEGRAL_SAMPLES = 500;
const int INSCATTER_INTEGRAL_SAMPLES = 50;
const int IRRADIANCE_INTEGRAL_SAMPLES = 32;
const int INSCATTER_SPHERICAL_INTEGRAL_SAMPLES = 16;

// ----------------------------------------------------------------------------
// PARAMETERIZATION OPTIONS
// ----------------------------------------------------------------------------

const int TRANSMITTANCE_W = 256;
const int TRANSMITTANCE_H = 64;

const int SKY_W = 64;
const int SKY_H = 16;

const int RES_R = 32;
const int RES_MU = 128;
const int RES_MU_S = 32;
const int RES_NU = 8;

//#define TRANSMITTANCE_NON_LINEAR
//#define INSCATTER_NON_LINEAR

// ----------------------------------------------------------------------------
// PARAMETERIZATION FUNCTIONS
// ----------------------------------------------------------------------------

uniform sampler2D transmittanceSampler;

uniform sampler2D skyIrradianceSampler;

uniform highp sampler3D inscatterSampler;

varying vec3 dir;
varying vec3 relativeDir;

uniform sampler2D glareSampler;
uniform float hdrExposure = 0.4;


vec2 getTransmittanceUV(float r, float mu) {
    float uR, uMu;
//#ifdef TRANSMITTANCE_NON_LINEAR
    uR = sqrt((r - Rg) / (Rt - Rg));
    uMu = atan((mu + 0.15) / (1.0 + 0.15) * tan(1.5)) / 1.5;
//#else
//    uR = (r - Rg) / (Rt - Rg);
//    uMu = (mu + 0.15) / (1.0 + 0.15);
//#endif
    return vec2(uMu, uR);
}

void getTransmittanceRMu(vec4 gl_FragCoord, out float r, out float muS) {
    r = gl_FragCoord.y / float(TRANSMITTANCE_H);
    muS = gl_FragCoord.x / float(TRANSMITTANCE_W);
//#ifdef TRANSMITTANCE_NON_LINEAR
    r = Rg + (r * r) * (Rt - Rg);
    muS = -0.15 + tan(1.5 * muS) / tan(1.5) * (1.0 + 0.15);
//#else
//    r = Rg + r * (Rt - Rg);
//    muS = -0.15 + muS * (1.0 + 0.15);
//#endif
}

vec2 getIrradianceUV(float r, float muS) {
    float uR = (r - Rg) / (Rt - Rg);
    float uMuS = (muS + 0.2) / (1.0 + 0.2);
    return vec2(uMuS, uR);
}

void getIrradianceRMuS(vec4 gl_FragCoord, out float r, out float muS) {
    r = Rg + (gl_FragCoord.y - 0.5) / (float(SKY_H) - 1.0) * (Rt - Rg);
    muS = -0.2 + (gl_FragCoord.x - 0.5) / (float(SKY_W) - 1.0) * (1.0 + 0.2);
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

void getMuMuSNu(vec4 gl_FragCoord, float r, vec4 dhdH, out float mu, out float muS, out float nu) {
    float x = gl_FragCoord.x - 0.5;
    float y = gl_FragCoord.y - 0.5;
//#ifdef INSCATTER_NON_LINEAR
    if (y < float(RES_MU) / 2.0) {
        float d = 1.0 - y / (float(RES_MU) / 2.0 - 1.0);
        d = min(max(dhdH.z, d * dhdH.w), dhdH.w * 0.999);
        mu = (Rg * Rg - r * r - d * d) / (2.0 * r * d);
        mu = min(mu, -sqrt(1.0 - (Rg / r) * (Rg / r)) - 0.001);
    } else {
        float d = (y - float(RES_MU) / 2.0) / (float(RES_MU) / 2.0 - 1.0);
        d = min(max(dhdH.x, d * dhdH.y), dhdH.y * 0.999);
        mu = (Rt * Rt - r * r - d * d) / (2.0 * r * d);
    }
    muS = mod(x, float(RES_MU_S)) / (float(RES_MU_S) - 1.0);
    // paper formula
    //muS = -(0.6 + log(1.0 - muS * (1.0 -  exp(-3.6)))) / 3.0;
    // better formula
    muS = tan((2.0 * muS - 1.0 + 0.26) * 1.1) / tan(1.26 * 1.1);
    nu = -1.0 + floor(x / float(RES_MU_S)) / (float(RES_NU) - 1.0) * 2.0;
//#else
//    mu = -1.0 + 2.0 * y / (float(RES_MU) - 1.0);
//    muS = mod(x, float(RES_MU_S)) / (float(RES_MU_S) - 1.0);
//    muS = -0.2 + muS * 1.2;
//    nu = -1.0 + floor(x / float(RES_MU_S)) / (float(RES_NU) - 1.0) * 2.0;
//#endif
}

// ----------------------------------------------------------------------------
// UTILITY FUNCTIONS
// ----------------------------------------------------------------------------

// nearest intersection of ray r,mu with ground or top atmosphere boundary
// mu=cos(ray zenith angle at ray origin)
float limit(float r, float mu) {
    float dout = -r * mu + sqrt(r * r * (mu * mu - 1.0) + RL * RL);
    float delta2 = r * r * (mu * mu - 1.0) + Rg * Rg;
    if (delta2 >= 0.0) {
        float din = -r * mu - sqrt(delta2);
        if (din >= 0.0) {
            dout = min(dout, din);
        }
    }
    return dout;
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

// transmittance(=transparency) of atmosphere for infinite ray (r,mu)
// (mu=cos(view zenith angle)), intersections with ground ignored
vec3 transmittance(float r, float mu) {
    vec2 uv = getTransmittanceUV(r, mu);
    return texture(transmittanceSampler, uv).rgb;
}

// transmittance(=transparency) of atmosphere for ray (r,mu) of length d
// (mu=cos(view zenith angle)), intersections with ground ignored
// uses analytic formula instead of transmittance texture
vec3 analyticTransmittance(float r, float mu, float d) {
    return exp(- betaR * opticalDepth(HR, r, mu, d) - betaMEx * opticalDepth(HM, r, mu, d));
}

// transmittance(=transparency) of atmosphere for infinite ray (r,mu)
// (mu=cos(view zenith angle)), or zero if ray intersects ground
vec3 transmittanceWithShadow(float r, float mu) {
    return mu < -sqrt(1.0 - (Rg / r) * (Rg / r)) ? vec3(0.0) : transmittance(r, mu);
}

// transmittance(=transparency) of atmosphere between x and x0
// assume segment x,x0 not intersecting ground
// r=||x||, mu=cos(zenith angle of [x,x0) ray at x), v=unit direction vector of [x,x0) ray
vec3 transmittance1(float r, float mu, vec3 v, vec3 x0) {
    vec3 result;
    float r1 = length(x0);
    float mu1 = dot(x0, v) / r;
    if (mu > 0.0) {
        result = min(transmittance(r, mu) / transmittance(r1, mu1), 1.0);
    } else {
        result = min(transmittance(r1, -mu1) / transmittance(r, -mu), 1.0);
    }
    return result;
}

// transmittance(=transparency) of atmosphere between x and x0
// assume segment x,x0 not intersecting ground
// d = distance between x and x0, mu=cos(zenith angle of [x,x0) ray at x)
vec3 transmittance2(float r, float mu, float d) {
    vec3 result;
    float r1 = sqrt(r * r + d * d + 2.0 * r * mu * d);
    float mu1 = (r * mu + d) / r1;
    if (mu > 0.0) {
        result = min(transmittance(r, mu) / transmittance(r1, mu1), 1.0);
    } else {
        result = min(transmittance(r1, -mu1) / transmittance(r, -mu), 1.0);
    }
    return result;
}

vec3 irradiance(sampler2D sampler, float r, float muS) {
    vec2 uv = getIrradianceUV(r, muS);
    return texture(sampler, uv).rgb;
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

float SQRT(float f, float err) {
//#ifdef OPTIMIZE
//    return sqrt(f);
//#else
    return f >= 0.0 ? sqrt(f) : err;
//#endif
}

// ----------------------------------------------------------------------------
// PUBLIC FUNCTIONS
// ----------------------------------------------------------------------------

// incident sun light at given position (radiance)
// r=length(x)
// muS=dot(x,s) / r
vec3 sunRadiance(float r, float muS) {
//#if defined(ATMO_SUN_ONLY) || defined(ATMO_FULL)
    return transmittanceWithShadow(r, muS) * SUN_INTENSITY;
//#elif defined(ATMO_NONE)
//    return vec3(SUN_INTENSITY);
//#else
//    return vec3(0.0);
//#endif
}

// incident sky light at given position, integrated over the hemisphere (irradiance)
// r=length(x)
// muS=dot(x,s) / r
vec3 skyIrradiance(float r, float muS) {
//#if defined(ATMO_SKY_ONLY) || defined(ATMO_FULL)
    return irradiance(skyIrradianceSampler, r, muS) * SUN_INTENSITY;
//#else
//    return vec3(0.0);
//#endif
}

// single scattered sunlight between two points
// camera=observer
// viewdir=unit vector towards observed point
// sundir=unit vector towards the sun
// return scattered light and extinction coefficient
vec3 skyRadiance(vec3 camera, vec3 viewdir, vec3 sundir, out vec3 extinction, float shaftWidth)
{
//#if defined(ATMO_INSCATTER_ONLY) || defined(ATMO_FULL)
    vec3 result;
    camera += viewdir * max(shaftWidth, 0.0);
    float r = length(camera);
    float rMu = dot(camera, viewdir);
    float mu = rMu / r;
    float r0 = r;
    float mu0 = mu;

    float deltaSq = SQRT(rMu * rMu - r * r + Rt*Rt, 1e30);
    float din = max(-rMu - deltaSq, 0.0);
    if (din > 0.0) {
        camera += din * viewdir;
        rMu += din;
        mu = rMu / Rt;
        r = Rt;
    }

    if (r <= Rt) {
        float nu = dot(viewdir, sundir);
        float muS = dot(camera, sundir) / r;

        vec4 inScatter = texture4D(inscatterSampler, r, rMu / r, muS, nu);
        if (shaftWidth > 0.0) {
            if (mu > 0.0) {
                inScatter *= min(transmittance(r0, mu0) / transmittance(r, mu), 1.0).rgbr;
            } else {
                inScatter *= min(transmittance(r, -mu) / transmittance(r0, -mu0), 1.0).rgbr;
            }
        }
        extinction = transmittance(r, mu);

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
		if(ANALYTIC_TRANSMITTANCE)
		{
	        extinction = min(analyticTransmittance(r, mu, d), 1.0);
		}
		else
		{
			if (mu > 0.0) {
            	extinction = min(transmittance(r, mu) / transmittance(r1, mu1), 1.0);
        	} else {
            	extinction = min(transmittance(r1, -mu1) / transmittance(r, -mu), 1.0);
        	}
		}
        
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

    return result * SUN_INTENSITY * mixFactor2;
//#else
//    extinction = vec3(1.0);
//    return vec3(0.0);
//#endif
}

vec3 outerSunRadiance(vec3 viewdir)
{
    vec3 data = viewdir.z > 0.0 ? texture(glareSampler, vec2(0.5) + viewdir.xy * 4.0).rgb : vec3(0.0);
    return pow(data, vec3(2.2)) * SUN_INTENSITY;
}
vec3 hdr(vec3 L) {
    L = L * hdrExposure;
    L.r = L.r < 1.413 ? pow(L.r * 0.38317, 1.0 / 2.2) : 1.0 - exp(-L.r);
    L.g = L.g < 1.413 ? pow(L.g * 0.38317, 1.0 / 2.2) : 1.0 - exp(-L.g);
    L.b = L.b < 1.413 ? pow(L.b * 0.38317, 1.0 / 2.2) : 1.0 - exp(-L.b);
    return L;
}

vec3 Flash(vec4 fragCoord,vec2 iResolution){
	vec2 q = fragCoord.xy/iResolution.xy;
    vec2 p = -1.0+2.0*q;
	p.x *= iResolution.x/iResolution.y;
	vec3 origin = vec3(6.0, 3.0 + 4.0, -4.0);
	vec3 target = vec3( 0.0, 0.8, 1.2 );
	
	vec3 cw = normalize( target-origin);
	vec3 cp = vec3( 0.0, 1.0, 0.0 );
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = ( cross(cu,cw) );
	vec3 ray = normalize( p.x*cu + p.y*cv + 2.5*cw );
	
	float iTime = TIME * 2.;
	vec3 col = vec3(0);
	vec3 flash_ = vec3(0.0);
	vec2 res = vec2(0.1);
	float t = res.x;
	float m = res.y;
	
   	vec3 pos = origin + t*ray;
	vec3 nor = vec3(0.1);
	float shiny = 0.0;
	
	float f = 1.;
	col += f * .07;
	shiny *= f*.25;
	vec3 lig = normalize( vec3(-0.3, 1.3, -0.5) );
       float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
	float sh = 0.4;
	dif *= sh;
	
	vec3 brdf = 1.50*dif*vec3(1.00);
	
	float ti = mod(iTime, flash_frequency); // 此处控制闪电的频率
	f = 0.0;
	for (int i = 0; i < 4; i++)
	{
		f+=.25;
		if (i == 2) f-=.1;
		flash_ = smoothstep(1.3+f,1.35+f, ti) * smoothstep(1.8+f,1.4+f, ti)*vec3(2.)*sh * flash_strength; // 控制亮度
		brdf += flash_;
		shiny += flash_.x;
		shiny = clamp(shiny, 0.0, 1.0);
	}
	float pp = clamp( dot( reflect(ray,nor), lig ), 0.0, 1.0 );
	float spe = sh*pow(max(pp, 0.0),2.0)*shiny;

	col = (col*brdf + spe) * exp(-0.0005*t*t*t*t);

	return vec3( clamp(col,0.0,1.0) );
}

vec3 Snowy(vec4 fragCoord,vec2 iResolution){
	vec2 uv = vec2(1.,iResolution.y/iResolution.x)*fragCoord.xy / iResolution.xy;
	const mat3 p = mat3(vec3(13.323122,23.5112,21.71123),
	vec3(21.1212,28.7312,11.9312),
	vec3(21.8112,14.7212,61.3934));
	
	//vec3 acc = vec3(col);
	float dof = 5.*sin(TIME*.1);
	vec3 col_ = vec3(0);
	for (int i=0;i<snowy_count;i++) 
	{
		float fi = float(i);
		vec2 q = uv*(1.+fi* 0.1);
		if(wind_direction == 0.) q += vec2(q.y*(0.8 * mod(fi*7.238917,1.)- 0.8*.5),0.5* TIME/(1.+fi*0.1*.03) * speed / 10.0) ; // 无风
		else q += vec2(q.y*wind_direction,0.5* TIME/(1.+fi*0.1*.03) * speed / 10.0) ; // 有风
		vec3 n = vec3(floor(q),31.189+fi);
		vec3 m = floor(n)*.00001 + fract(n);
		vec3 mp = (31415.9+m)/fract(p*m);
		vec3 r = fract(mp);
		vec2 s = abs(mod(q,1.)-.5+.9*r.xy-.45);
		s += .01*abs(2.*fract(10.*q.yx)-1.); 
		float d = .6*max(s.x-s.y,s.x+s.y)+max(s.x,s.y)-.01;
		float edge = .005+.05*min(.5*abs(fi-5.-dof),1.) * 3.; // 调整粒子大下
		col_ += vec3(smoothstep(edge,-edge,d * 7.0)*(r.x/(1.+.02*fi* 0.1))) * 0.5;
	}
	return col_;
}

vec3 Rainy(vec4 fragCoord,vec2 iResolution){
	float iTime = TIME;
	vec2 q = fragCoord.xy/iResolution.xy;
    vec2 p = -1.0+2.0*q;
	p.x *= iResolution.x/iResolution.y;
	vec3 vCameraPos = vec3(0.0, 0.0, 9.8);
	float ang = iTime * .3 + 3.4;
	float head = pow(abs(sin(ang*8.0)), 1.5) * .15;
	vCameraPos += vec3(cos(ang) * 2.5, head,  sin(ang) * 8.5);
    vec2 coord = fragCoord.xy / iResolution.xy;
	vec3 vCameraIntrest = vec3(-1.0, head, 25.0);
	vec3 normal;
	
	// Do the pixel colours...	
    vec3 col = vec3(0);
	
	float dis = 1.;
	for (int i = 0; i < 12; i++)
	{
		vec3 plane = vCameraPos;
		
			float f = pow(dis, .45)+.25;

			vec2 st =  f * (q * vec2(2.5, .17)+vec2(-iTime*.1+q.y*wind_direction, iTime*.16)); // 可以设置方向
			f = (texture(iChannel3, st * .5, -99.0).x + texture(iChannel3, st*.284, -99.0).y);
			f = clamp(pow(abs(f)*.75, 10.0) * speed, 0.00, q.y*.4+.05);

			vec3 bri = vec3(.25) * float(rainy_count) / 100.;
			for (int t = 0; t < 11; t++)
			{
				vec3 v3 = - plane.xyz;
				float l = dot(v3, v3);
				l = max(3.0-(l*l * .02), 0.0);
				
			}
			col += bri*f;
		
		dis += 3.5;
	}
	return clamp(col, 0.0, 1.0);
}



mat4 get_projection_matrix(float fov, float aspect, float near, float far)
{
	float mat11 = 1.0 / (tan(fov / 2.0) * aspect);
	float mat22 = 1.0 / tan(fov / 2.0);
	float mat33 = (near + far) / (near - far);
	float mat34 = 2.0 * near * far / (near - far);
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
vec3 ACESFilm( vec3 x )
{
    float tA = 2.51;
    float tB = 0.03;
    float tC = 2.43;
    float tD = 0.59;
    float tE = 0.14;
    return clamp((x*(tA*x+tB))/(x*(tC*x+tD)+tE),0.0,1.0);
}


vec3 getCameraPos(mat4 inv_camera_mat)
{
	vec3 R = inv_camera_mat[0].xyz;
	vec3 U = inv_camera_mat[1].xyz;
	vec3 V = inv_camera_mat[2].xyz;
	vec3 W = inv_camera_mat[3].xyz;
	
	mat3 ruv_mat = mat3(R, U, V);
	mat3 inv_ruv_mat = inverse(ruv_mat);
	vec3 pos = inv_ruv_mat * W;
	return -pos;
}






/*
Finally, draw the atmosphere to screen

we first get the camera vector and position, as well as the light dir
*/

vec3 depthToWorld(sampler2D depthTexture, vec2 screenUV, mat4 invProjectMatrix, mat4 cameraMatrix)
{
	float depth = texture(depthTexture, screenUV).x;
	vec3 ndc = vec3(screenUV, depth) * 2.0 - 1.0;
	vec4 view = invProjectMatrix * vec4(ndc, 1.0);
	vec4 world = cameraMatrix * vec4(view);
	vec3 world_pos =  world.xyz / world.w;
	return world_pos;
}




void vertex()
{
	vec3 WSD = sun_dir;

    dir = (CAMERA_MATRIX * vec4((INV_PROJECTION_MATRIX * vec4(VERTEX, 1.0)).xyz, 0.0)).xyz;
	dir = normalize(dir);
    // construct a rotation that transforms sundir to (0,0,1);
    float theta = acos(WSD.z);
    float phi = atan(WSD.y, WSD.x);
    mat3 rz = mat3(vec3(cos(phi), -sin(phi), 0.0), vec3(sin(phi), cos(phi), 0.0), vec3(0.0, 0.0, 1.0));
    mat3 ry = mat3(vec3(cos(theta), 0.0, sin(theta)), vec3(0.0, 1.0, 0.0), vec3(-sin(theta), 0.0, cos(theta)));
    // apply this rotation to view dir to get relative viewdir
    relativeDir = (ry * rz) * dir;

//    POSITION = vec4(VERTEX.xy, 0.9999999, 1.0);
	POSITION = vec4(VERTEX, 1.0);
	
	
	
}
void fragment() {
	ALBEDO = texture(SCREEN_TEXTURE, SCREEN_UV).xyz;
	vec2 iResolution = VIEWPORT_SIZE;
	vec4 fragCoord = FRAGCOORD;
	vec3 col = vec3(0);
	if(flash) {
		col += Flash(fragCoord,iResolution);
	}
	if(snowy) {
		col += Snowy(fragCoord,iResolution);
	}
	if(rainy) {
		col += Rainy(fragCoord,iResolution) * rainy_color.rgb;
	}
	if(need_atmosphere)
	{
		vec3 WSD = sun_dir;
        vec3 WCP = CAMERA_RELATIVE_POS.xyz;

        vec3 d = normalize(dir);

        vec3 sunColor = outerSunRadiance(relativeDir);

        vec3 extinction;

	    // get the color of the sphere
//	    vec4 color = texture(screen_texture, SCREEN_UV);
	    vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
	    color.xyz = mix(pow((color.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)),vec3(2.4)),color.rgb * (1.0 / 12.92),lessThan(color.rgb,vec3(0.04045)));
	    vec3 inscatter = skyRadiance(WCP, d, WSD, extinction, 0.0);
	    vec3 finalColor = (sunColor * extinction + inscatter) * mixFactor;
	    vec3 pos = CAMERA_RELATIVE_POS.xyz;
//	    vec2 planet_intersect = ray_sphere_intersect(pos, dir, 6378137.0); 
        // if the ray hit the planet, set the max distance to that ray

	    if(length(CAMERA_RELATIVE_POS.xyz) >= Rg + 9000.0)
	    {
//	    	if (0.0 < planet_intersect.y) {
//	        	color.w = max(planet_intersect.x, 0.0);
//  
//	            // sample position, where the pixel is
//	            vec3 sample_pos = pos + (dir * planet_intersect.x);
//  
//	            // and the surface normal
//	            vec3 surface_normal = normalize(sample_pos);
//  
//	            // get wether this point is shadowed, + how much light scatters towards the camera according to the lommel-seelinger law
//  
//	    		if(use_shadow)
//	    		{
//	    			vec3 N = surface_normal;
//	            	vec3 V = -dir;
//	            	vec3 L = sun_dir;
//	            	float dotNV = max(1e-6, dot(N, V));
//	            	float dotNL = max(1e-6, dot(N, L));
//	            	float shadow = dotNL / (dotNL + dotNV);
//	    			color.xyz *= shadow * reflectivity;
//	    		}
//	            // apply the shadow
//	            else
//	    		{
//	    			color.xyz *= reflectivity;
//	    		}
//	    		ALBEDO = finalColor + color.xyz;
//  
//  
//	            // apply skylight
////    			if(use_sky_light)
////    			{
////    	        	color.xyz += clamp(skylight(sample_pos, surface_normal, light_dir, vec3(10.0)) * color.xyz, min_sky_light, max_sky_light);
////    			}
////    	        color.xyz += clamp(skylight(sample_pos, surface_normal, light_dir, vec3(10.0)) * color.xyz, 0.0, 1.0);
//        	}
//	    	else
//	    	{
	    		ALBEDO = finalColor;
//	    		ALPHA = length(extinction);
	    		ALPHA = alpha;
//	    	}
	    }
	    else
	    {
	    	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	    		//float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	    	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	    	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
//      	view.xyz /= view.w;
	    	vec4 world = CAMERA_MATRIX * vec4(view);
	    	vec3 piexlPos =  world.xyz / world.w + CAMERA_RELATIVE_POS.xyz;
	    	float dis = length(piexlPos - CAMERA_RELATIVE_POS.xyz);
//	    	if(depth < 10.0)
//	    	if(true)
	    	if(dis < maxDistance)
	    	{
	    		color.w = max(dis, 0.0);

	            // sample position, where the pixel is
	            vec3 sample_pos = piexlPos;

	            // and the surface normal
	            vec3 surface_normal = normalize(sample_pos);

	            // get wether this point is shadowed, + how much light scatters towards the camera according to the lommel-seelinger law
	    		if(use_shadow)
	    		{
	    			vec3 N = surface_normal;
	            	vec3 V = -dir;
	            	vec3 L = sun_dir;
	            	float dotNV = max(1e-6, dot(N, V));
	            	float dotNL = max(1e-6, dot(N, L));
	            	float shadow = dotNL / (dotNL + dotNV);
	    			color.xyz *= shadow * reflectivity;

	    		}
	            // apply the shadow
	            else
	    		{
	    			color.xyz *= reflectivity;
	    		}
	    		vec3 extinction2;
	    	    vec3 inscatter2 = inScattering(WCP, piexlPos, WSD, extinction2, 0.0);


//	    		if(dis < 1000.0)
//	    		{
//	    			ALPHA = 0.0;
//	    		}
//	    		else
//	    		{
	    			ALBEDO = (color.rgb * extinction2  + inscatter2 ) + col;
//	    			ALBEDO = (finalColor);
	    			ALPHA = alpha2;
//	    		}
//	    		ALBEDO = ( inscatter2);
	            // apply the shadow
//	            color.xyz *= shadow * reflectivity;
//	    		color.xyz *=  reflectivity;
//	    		color.xyz *= 2.0;
	            // apply skylight
//	    		if(use_sky_light)
//	    		{
//	            	color.xyz += clamp(skylight(sample_pos, surface_normal, light_dir, vec3(10.0)) * color.xyz, min_sky_light, max_sky_light);				
//	    		}
//	            color.xyz += clamp(skylight(sample_pos, surface_normal, light_dir, vec3(10.0)) * color.xyz, 0.0, 1.0);
	    	}
	    	else
	    	{
	    		ALBEDO = (finalColor) + col;
	    		ALPHA = alpha;
	    	}

	    }
	}
	else
	{
		ALBEDO = texture(SCREEN_TEXTURE, SCREEN_UV).xyz + col;
		ALPHA = 0.5;
	}
//	ALBEDO = vec3(1, 0, 0);
	
}