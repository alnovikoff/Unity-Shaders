#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct vertexInput
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float4 uv : TEXCOORD0;
#ifdef LIGHTMAP_ON
    float2 staticLightmapUV : TEXCOORD1;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct fragmentInput
{
    float4 positionCS : SV_POSITION;
    float4 positionWSAndFog : TEXCOORD0;

    float3 normalWS : TEXCOORD1;
    float3 tangentWS : TEXCOORD2;
    float3 bitangentWS : TEXCOORD3;

    float2 uv: TEXCOORD4;

    float3 viewDirectionWS: TEXCOORD5;
#ifdef _MAIN_LIGHT_SHADOWS
    float4 shadowCoord : TEXCOORD6;
#endif
    DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 7);
};

CBUFFER_START(UnityPerMaterial)
float4 _BaseColor_ST;
CBUFFER_END

TEXTURE2D(_BaseColor);
SAMPLER(sampler_BaseColor);

sampler2D _WindTex;

TEXTURE2D(_NormalMap);
SAMPLER(sampler_NormalMap);

TEXTURE2D(_MetallicSmoothnessMap);
SAMPLER(sampler_MetallicSmoothnessMap);

TEXTURE2D(_OcclusionMap);
SAMPLER(sampler_OcclusionMap);
sampler2D _AlphaTex;
float4 _WorldSize;
float _WaveSpeed;
float _WaveAmp;
float _HeightFactor;
float _HeightCutoff;
float4 _WindSpeed;

fragmentInput vertexProgram(vertexInput data)
{
    UNITY_SETUP_INSTANCE_ID(data);

    fragmentInput output;

    float3 positionWS = TransformObjectToWorld(data.positionOS);
    output.positionCS = TransformWorldToHClip(positionWS);
    output.positionWSAndFog = float4(positionWS, ComputeFogFactor(output.positionCS.z));

    VertexNormalInputs normalInput = GetVertexNormalInputs(data.normalOS, data.tangentOS);
    output.normalWS = normalInput.normalWS;
    output.tangentWS = normalInput.tangentWS;
    output.bitangentWS = normalInput.bitangentWS;

    output.uv = TRANSFORM_TEX(data.uv, _BaseColor);

    output.viewDirectionWS = GetWorldSpaceViewDir(positionWS);

#ifdef _MAIN_LIGHT_SHADOWS
    output.shadowCoord = TransformWorldToShadowCoord(positionWS);
#endif

    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
    OUTPUT_SH(output.normalWS, output.vertexSH);

    float4 worldPos = mul(data.positionOS, unity_ObjectToWorld);
    float2 samplePos = worldPos.xz / _WorldSize.xz;
    samplePos += _Time.x * _WindSpeed.xy;
    float windSample = tex2Dlod(_WindTex, float4(samplePos, 1, 1));
    output.positionCS += sin(_WaveSpeed * windSample) * _WaveAmp;
    //output.positionCS.y += cos(_WaveSpeed * windSample) * _WaveAmp;


    return output;
}

InputData InitializeInputData(in fragmentInput input, in float3 normalTS)
{
    InputData inputData;
    inputData.positionCS = input.positionCS;
    inputData.positionWS = input.positionWSAndFog.xyz;

    inputData.tangentToWorld = half3x3(input.tangentWS, input.bitangentWS, input.normalWS);
    inputData.normalWS = TransformTangentToWorld(normalTS, inputData.tangentToWorld);

    inputData.viewDirectionWS = normalize(input.viewDirectionWS);

#ifdef _MAIN_LIGHT_SHADOWS_CASCADE
    inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWSAndFog.xyz);
#elif defined(_MAIN_LIGHT_SHADOWS)
    inputData.shadowCoord = input.shadowCoord;
#else
    inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

    inputData.shadowMask = half4(1, 1, 1, 1);
    inputData.vertexLighting = half3(0, 0, 0);
    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.normalWS);
    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    inputData.fogCoord = input.positionWSAndFog.w;

    return inputData;
}

SurfaceData InitializeSurfaceData(in fragmentInput input, in float3 normalTS)
{
    float4 color = SAMPLE_TEXTURE2D(_BaseColor, sampler_BaseColor, input.uv);
    float4 alpha = tex2D(_AlphaTex, input.uv);
    float4 ms = SAMPLE_TEXTURE2D(_MetallicSmoothnessMap, sampler_MetallicSmoothnessMap, input.uv);
    float occlusion = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, input.uv).r;

    SurfaceData surfaceData;

    surfaceData.albedo = color.rgb;
    surfaceData.alpha = alpha.r;

    surfaceData.occlusion = occlusion;
    surfaceData.metallic = ms.r;
    surfaceData.smoothness = ms.g;
    surfaceData.emission = float3(0, 0, 0);
    surfaceData.specular = float3(0, 0, 0);
    surfaceData.clearCoatMask = 0;
    surfaceData.clearCoatSmoothness = 0;
    surfaceData.normalTS = normalTS;

    return surfaceData;
}

float4 fragmentProgram(fragmentInput input) : SV_Target
{
    float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv));

    SurfaceData surfaceData = InitializeSurfaceData(input, normalTS);

    InputData inputData = InitializeInputData(input, normalTS);

    float4 color = UniversalFragmentPBR(inputData, surfaceData);
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
}
