Shader "Custom/TerrainShader2"
{
    Properties
    {
        _Color("Bottom Color", Color) = (1, 1, 1, 1)
        _BottomColor("Bottom Color", Color) = (1, 1, 1, 1)
        _BaseColor("Base color", 2D) = "white"
        [NoScaleOffset]
        _NormalMap("Normal map", 2D) = "bump"
        [NoScaleOffset]
        _MetallicSmoothnessMap("Metallic smoothness map", 2D) = "black"
        [NoScaleOffset]
        _OcclusionMap("Occlusion map", 2D) = "white"

        _HeightMap("Height Map", 2D) = "white" {}
        _HeightAmount("Height Amount", float) = 0.5

        _Tess("Tessellation", Range(1, 32)) = 20
        _MaxTessDistance("Max Tess Distance", Range(1, 32)) = 20
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Geometry" 
        }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vertexProgram
            #pragma fragment fragmentProgram

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Assets/Shaders/Ground/Terrain.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #pragma multi_compile_instancing

            #include "Assets/Shaders/Lit/LitShadowPass.hlsl"
            ENDHLSL
        }

        Pass
        {

            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma multi_compile_instancing

            #include "Assets/Shaders/Lit/LitDepthOnlyPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            ZWrite On

            HLSLPROGRAM
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            #pragma multi_compile_instancing

            #include "Assets/Shaders/Lit/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }
    }
}








