#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct fragmentInput
{
    float4 positionOS : SV_POSITION;
    float3 normalWS : TEXCOORD0;
};

struct vertexInput
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

CBUFFER_START(UnityPerMaterial)
float4 _BaseColor_ST;
CBUFFER_END

fragmentInput DepthNormalsVertex(vertexInput input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    fragmentInput output;
    output.positionOS = TransformObjectToHClip(input.positionOS);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    return output;
}

float4 DepthNormalsFragment(fragmentInput input) : SV_Target
{
    return float4(NormalizeNormalPerPixel(input.normalWS), 0.0);
}
