#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct vertexInput
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
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

float4 _MaskTex_ST;

float _RevealValue;
float _Feater;
float4 _ErodeTexture_ST;
CBUFFER_END

sampler2D _MaskTex;

TEXTURE2D(_BaseColor);
SAMPLER(sampler_BaseColor);

TEXTURE2D(_NormalMap);
SAMPLER(sampler_NormalMap);

TEXTURE2D(_MetallicSmoothnessMap);
SAMPLER(sampler_MetallicSmoothnessMap);

TEXTURE2D(_OcclusionMap);
SAMPLER(sampler_OcclusionMap);

TEXTURE2D(_ErodeTexture);
SAMPLER(sampler_ErodeTexture);

TEXTURE2D(_ErodeNormalMap);
SAMPLER(sampler_ErodeNormalMap);

TEXTURE2D(_ErodeMetallicSmoothnessMap);
SAMPLER(sampler_ErodeMetallicSmoothnessMap);

TEXTURE2D(_ErodeOcclusionMap);
SAMPLER(sampler_ErodeOcclusionMap);

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

    /*output.uv = TRANSFORM_TEX(data.uv, _BaseColor);
    output.uv = TRANSFORM_TEX(data.uv, _ErodeTexture);*/

    output.viewDirectionWS = GetWorldSpaceViewDir(positionWS);

#ifdef _MAIN_LIGHT_SHADOWS
    output.shadowCoord = TransformWorldToShadowCoord(positionWS);
#endif

    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
    OUTPUT_SH(output.normalWS, output.vertexSH);

    output.uv = TRANSFORM_TEX(data.uv, _BaseColor);   //1st texture
    output.uv = TRANSFORM_TEX(data.uv, _ErodeTexture);

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

InputData InitializeInputData2(in fragmentInput input, in float3 normalTS)
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
    float4 ms = SAMPLE_TEXTURE2D(_MetallicSmoothnessMap, sampler_MetallicSmoothnessMap, input.uv);
    float occlusion = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, input.uv).r;

    SurfaceData surfaceData;

    surfaceData.albedo = color.rgb;
    surfaceData.alpha = color.a;

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

SurfaceData InitializeSurfaceData2(in fragmentInput input, in float3 normalTS)
{
    float4 color = SAMPLE_TEXTURE2D(_ErodeTexture, sampler_ErodeTexture, input.uv);
    float4 ms = SAMPLE_TEXTURE2D(_ErodeMetallicSmoothnessMap, sampler_ErodeMetallicSmoothnessMap, input.uv);
    float occlusion = SAMPLE_TEXTURE2D(_ErodeOcclusionMap, sampler_ErodeOcclusionMap, input.uv).r;

    SurfaceData surfaceData;

    surfaceData.albedo = color.rgb;
    surfaceData.alpha = color.a;

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
    float4 mask = tex2D(_MaskTex, input.uv.xy);

    // Bark
    float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv));


    SurfaceData surfaceData = InitializeSurfaceData(input, normalTS);

    InputData inputData = InitializeInputData(input, normalTS);

    float4 color = UniversalFragmentPBR(inputData, surfaceData);
    color.rgb = MixFog(color.rgb, inputData.fogCoord);

    // MOss
    float3 normalTSE = UnpackNormal(SAMPLE_TEXTURE2D(_ErodeNormalMap, sampler_ErodeNormalMap, input.uv));
    SurfaceData surfaceData2 = InitializeSurfaceData2(input, normalTSE);
    InputData inputData2 = InitializeInputData2(input, normalTSE);
    float4 colorE = UniversalFragmentPBR(inputData2, surfaceData2);
    colorE.rgb = MixFog(colorE.rgb, inputData2.fogCoord);

    float revealAmountTop = step(mask.r, _RevealValue + _Feater);
    float revealAmountBottom = step(mask.r, _RevealValue - _Feater);
    float revealDifference = revealAmountTop - revealAmountBottom;
    float3 finalCol = lerp(color.rgb, colorE, revealDifference);
    return float4(finalCol.rgb, colorE.a * revealAmountTop);
}
