Shader "Custom/URP/CamouflageShader"
{
    Properties
    {
        [MainTexture] _BaseMap("Base Map (RGB)", 2D) = "white" {}
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        
        _WhiteReplaceColor("White Replacement Color", Color) = (1, 1, 1, 1)
        _GrayReplaceColor("Gray Replacement Color", Color) = (0.5, 0.5, 0.5, 1)
        _BlackReplaceColor("Black Replacement Color", Color) = (0, 0, 0, 1)
        
        _WhiteThreshold("White Threshold", Range(0.5, 1.0)) = 0.8
        _GrayThreshold("Gray Threshold", Range(0.2, 0.8)) = 0.498
        _BlackThreshold("Black Threshold", Range(0.0, 0.5)) = 0.2
        
        _GrayRange("Gray Detection Range", Range(0.01, 0.3)) = 0.15
        
        [Toggle(_ALPHATEST_ON)] _AlphaTestToggle("Alpha Test", Float) = 0
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        
        [NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Scale", Float) = 1.0
        
        [HDR] _EmissionColor("Emission Color", Color) = (0, 0, 0, 1)
        [NoScaleOffset] _EmissionMap("Emission Map", 2D) = "white" {}
        
        // URP Specific
        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
    }
    
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque" 
            "RenderPipeline" = "UniversalPipeline" 
            "Queue" = "Geometry"
            "IgnoreProjector" = "True"
        }
        LOD 300

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
        float4 _BaseMap_ST;
        half4 _BaseColor;
        half4 _WhiteReplaceColor;
        half4 _GrayReplaceColor;
        half4 _BlackReplaceColor;
        half _WhiteThreshold;
        half _GrayThreshold;
        half _BlackThreshold;
        half _GrayRange;
        half _Cutoff;
        half _Smoothness;
        half _Metallic;
        half _BumpScale;
        half4 _EmissionColor;
        CBUFFER_END
        
        // Calculate luminance of a color
        half Luminance(half3 color)
        {
            return dot(color, half3(0.299, 0.587, 0.114));
        }
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]
            
            HLSLPROGRAM
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment
            
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local _EMISSION
            
            // URP Keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            
            // Unity Keywords
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);
            TEXTURE2D(_EmissionMap);
            SAMPLER(sampler_EmissionMap);
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 uv           : TEXCOORD0;
                float2 lightmapUV   : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                half3 normalWS      : TEXCOORD2;
                #ifdef _NORMALMAP
                    half4 tangentWS : TEXCOORD3;
                #endif
                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    half3 vertexLighting : TEXCOORD4;
                #endif
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 5);
                #ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
                    float4 shadowCoord : TEXCOORD6;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                
                output.positionWS = vertexInput.positionWS;
                output.positionCS = vertexInput.positionCS;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                
                output.normalWS = normalInput.normalWS;
                
                #ifdef _NORMALMAP
                    real sign = input.tangentOS.w * GetOddNegativeScale();
                    output.tangentWS = half4(normalInput.tangentWS.xyz, sign);
                #endif
                
                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                
                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                    output.vertexLighting = vertexLight;
                #endif
                
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    output.shadowCoord = GetShadowCoord(vertexInput);
                #endif
                
                return output;
            }
            
            half4 LitPassFragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                // Sample base color
                float2 uv = input.uv;
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
                half3 albedo = baseMap.rgb * _BaseColor.rgb;
                half alpha = baseMap.a * _BaseColor.a;
                
                #ifdef _ALPHATEST_ON
                    clip(alpha - _Cutoff);
                #endif
                
                // Apply camouflage color replacement
                half lum = Luminance(albedo);
                
                // Apply color replacement
                half whiteAmount = smoothstep(_WhiteThreshold - 0.1, _WhiteThreshold + 0.1, lum);
                half blackAmount = smoothstep(_BlackThreshold + 0.1, _BlackThreshold - 0.1, lum);
                
                // Gray is between white and black
                half grayAmount = 1.0;
                grayAmount -= whiteAmount;
                grayAmount -= blackAmount;
                float grayDistance = abs(lum - _GrayThreshold);
                grayAmount *= saturate(1.0 - grayDistance / _GrayRange);
                
                // Debug visualization to check exact luminance values
                // albedo = half3(lum, lum, lum); // Uncomment to debug
                
                // Blend the colors based on thresholds
                half3 camoColor = albedo;
                camoColor = lerp(camoColor, _WhiteReplaceColor.rgb, whiteAmount);
                camoColor = lerp(camoColor, _GrayReplaceColor.rgb, grayAmount);
                camoColor = lerp(camoColor, _BlackReplaceColor.rgb, blackAmount);
                
                albedo = camoColor;
                
                // Normal mapping
                #ifdef _NORMALMAP
                    half3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv), _BumpScale);
                    half3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, 
                        cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w, input.normalWS));
                    normalWS = normalize(normalWS);
                #else
                    half3 normalWS = normalize(input.normalWS);
                #endif
                
                // Emission
                half3 emission = 0;
                #ifdef _EMISSION
                    emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, input.uv).rgb * _EmissionColor.rgb;
                #endif
                
                // Setup surface data
                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = albedo;
                surfaceData.alpha = alpha;
                surfaceData.emission = emission;
                surfaceData.metallic = _Metallic;
                surfaceData.occlusion = 1.0;
                surfaceData.smoothness = _Smoothness;
                surfaceData.specular = half3(0, 0, 0);
                surfaceData.normalTS = half3(0, 0, 1);
                
                // Setup input data
                InputData inputData = (InputData)0;
                inputData.positionWS = input.positionWS;
                inputData.normalWS = normalWS;
                inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    inputData.shadowCoord = input.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                #else
                    inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif
                
                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    inputData.vertexLighting = input.vertexLighting;
                #else
                    inputData.vertexLighting = half3(0, 0, 0);
                #endif
                
                inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
                
                // Apply lighting
                half4 color = UniversalFragmentPBR(inputData, surfaceData);
                
                // Apply fog
                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                
                return color;
            }
            ENDHLSL
        }
        
        // ShadowCaster pass for shadow casting
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]
            
            HLSLPROGRAM
            #pragma target 2.0
            
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            
            #pragma shader_feature_local _ALPHATEST_ON
            
            #define SHADOWCASTER_PASS
            
            // Include the custom function to sample the texture for alpha clipping
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            // Sample the alpha texture manually rather than using SurfaceInput.hlsl
            #ifdef _ALPHATEST_ON
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            #endif
            
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
            // Shadow caster specific input
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            float3 _LightDirection;
            
            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                // Shadow pass specific
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
                
                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif
                
                output.positionCS = positionCS;
                return output;
            }

            half4 ShadowPassFragment(Varyings input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                
                #ifdef _ALPHATEST_ON
                    half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                    half alpha = texColor.a * _BaseColor.a;
                    clip(alpha - _Cutoff);
                #endif
                
                return 0;
            }
            ENDHLSL
        }
        
        // DepthOnly pass
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
            
            ZWrite On
            ColorMask 0
            Cull[_Cull]
            
            HLSLPROGRAM
            #pragma target 2.0
            
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            
            #pragma shader_feature_local _ALPHATEST_ON
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            // Sample the alpha texture manually rather than using SurfaceInput.hlsl
            #ifdef _ALPHATEST_ON
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            #endif
            
            struct Attributes
            {
                float4 position     : POSITION;
                float2 texcoord     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = TransformObjectToHClip(input.position.xyz);
                return output;
            }

            half4 DepthOnlyFragment(Varyings input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                #ifdef _ALPHATEST_ON
                    half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                    half alpha = texColor.a * _BaseColor.a;
                    clip(alpha - _Cutoff);
                #endif

                return 0;
            }
            ENDHLSL
        }
    }
    
    FallBack "Universal Render Pipeline/Lit"
} 