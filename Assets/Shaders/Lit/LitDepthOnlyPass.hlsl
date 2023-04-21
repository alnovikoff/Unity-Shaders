#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

CBUFFER_START(UnityPerMaterial)
float4 _BaseColor_ST;
CBUFFER_END

struct vertexInput
{
    float4 positionOS : POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

float4 DepthOnlyVertex(vertexInput input) : SV_POSITION
{
    UNITY_SETUP_INSTANCE_ID(input);
    return TransformObjectToHClip(input.positionOS);
}

float4 DepthOnlyFragment(float4 positionCS : SV_POSITION) : SV_Target
{
    return 0;
}
