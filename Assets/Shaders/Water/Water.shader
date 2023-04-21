Shader "LitShader"
{
    Properties
    {
        _Speed("Speed", Range(0, 5)) = 1.25
        _Steepness("Steepness", Range(0, 1)) = 0.5
        _WaveSpeed("Wave Speed", Range(0, 5)) = 1.25
        _BaseColor("Base color", 2D) = "white"
        [NoScaleOffset]
        _NormalMap("Normal Map", 2D) = "bump"
        [NoScaleOffset]
        _MetallicSmoothnessMap("Metalic smoothness map", 2D) = "black"
        [NoScaleOffset]
        _OcclusionMap("Occlusion Map", 2D) = "white"

        
        _WaveLenth("Wave Lenth", float) = 10
        _WaveAmp("Wave Amp", float) = 1.0
        _HeightFactor("Height Factor", float) = 1.0
        _HeightCutoff("Height Cutoff", float) = 1.2
        _WindTex("Wind Texture", 2D) = "white" {}
        _WorldSize("World Size", vector) = (1, 1, 1, 1)
        _WindSpeed("Wind Speed", vector) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags
        {
            "Queue"="Geometry"
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

            #include "Assets/Shaders/Water/Waves.hlsl"
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