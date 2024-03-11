float3 expand(float3 v)
{
    return (v - 0.5) * 2;
}
void main_fp(
    float4 iPosition      : TEXCOORD0,
    float4 iUvProjection : TEXCOORD1,
    float4 iNormal       : TEXCOORD2,
    float4 iWorldPosition  : TEXCOOR3, //cFoam
    out float4 oColor    : COLOR,
    uniform float3       uEyePosition,
    uniform float        uFullReflectionDistance,
    uniform float        uGlobalTransparency,
    uniform float        uNormalDistortion,
    uniform float3       uWaterColor, //cDepth
    uniform float        uSmoothPower, //cSmooth

    //cSun
    uniform float3       uSunPosition,
	uniform float        uSunStrength,
	uniform float        uSunArea,
	uniform float3       uSunColor,

    //cFoam
    uniform float        uFoamRange,
    uniform float        uFoamMaxDistance,
    uniform float        uFoamScale,
    uniform float        uFoamStart,
    uniform float        uFoamTransparency,

    //cCaustics
    uniform float        uCausticsPower,


    uniform sampler2D    uReflectionMap : register(s0)
    uniform sampler2D    uRefractionMap : register(s1)

    uniform sampler2D    uDepthMap: register(s3) //cDepth

    uniform sampler1D    uFresnelMap      : register(s4)
    uniform sampler2D    uFoamMap         : register(s5) //cFoam

    )
{

    float2 ProjectionCoord = iUvProjection.xy / iUvProjection.w;
    float3 camToSurface = iPosition.xyz - uEyePosition;
    float additionalReflection = camToSurface.x * camToSurface.x + camToSurface.z * camToSurface.z;

    float foamVisibility = 1.0f - saturate(additionalReflection/uFoamMaxDistance); //cFoam


    additionalReflection/=uFullReflectionDistance;
    camToSurface=normalize(-camToSurface);
    float3 pixelNormal = iNormal;
    float2 pixelNormalModified = uNormalDistortion*pixelNormal.zx;
    float dotProduct=dot(-camToSurface,pixelNormal);

    dotProduct=saturate(dotProduct);
    float fresnel = tex1D(uFresnelMap,dotProduct);
    // Add additional reflection and saturate
    fresnel+=additionalReflection;
    fresnel=saturate(fresnel);
    // Decrease the transparency and saturate
    fresnel-=uGlobalTransparency;
    fresnel=saturate(fresnel);
    // Get the reflection/refraction pixels. Make sure to disturb the texcoords by pixelnormal
    float3 reflection=tex2D(uReflectionMap,ProjectionCoord.xy+pixelNormalModified);
    float3 refraction=tex2D(uRefractionMap,ProjectionCoord.xy-pixelNormalModified);

    //cDepth
    float depth = tex2D(uDepthMap,ProjectionCoord.xy-pixelNormalModified).r;
    refraction = lerp(uWaterColor,refraction,depth);

    oColor = float4(lerp(refraction,reflection,fresnel),1);

    //cSun
    float3 relfectedVector = normalize(reflect(-camToSurface,pixelNormal.xyz));
    float3 surfaceToSun=normalize(uSunPosition-iPosition.xyz);
    float3 sunlight = uSunStrength*pow(saturate(dot(relfectedVector,surfaceToSun)),uSunArea)*uSunColor;
    oColor.xyz+=sunlight;

    //cFoam
    float hmap = iPosition.y/uFoamRange*foamVisibility;
	float2 foamTex=iWorldPosition.xz*uFoamScale+pixelNormalModified;
	float foam=tex2D(uFoamMap,foamTex).r;
	float foamTransparency=saturate(hmap-uFoamStart)*uFoamTransparency;
	oColor.xyz=lerp(oColor.xyz,1,foamTransparency*foam);

    //cSmooth
    oColor.xyz = lerp(tex2D(uRefractionMap,ProjectionCoord.xy).xyz,oColor.xyz,saturate((1-tex2D(uDepthMap,ProjectionCoord.xy).r)*uSmoothPower));



}

