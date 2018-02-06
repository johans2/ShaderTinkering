// Resolution Games: 
// This is based on the Unity Default-UI shader, but has a different stencil. It also looks at a grayscale LUT 
// to determine which pixels to draw and which to discard. This is controlled by a slider (0 -> no discard, 1-> all discard).

Shader "UI/Johan-MASK"
{
    Properties
    {
        _Color ("Tint", Color) = (1,1,1,1)
        _AlphaLUT ("AlphaLUT", 2D) = "white" {}
        _AlphaDraw ("Alpha draw", Range (.0, 1.0)) = 0.0
        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"= "Geometry-1"
            "IgnoreProjector"="True"
            "RenderType"="TransparentCutout"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

		Stencil
		{
			Ref 1
			Comp always
			Pass replace
		}

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "Default"
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma multi_compile __ UNITY_UI_ALPHACLIP

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            fixed4 _Color;
            float4 _ClipRect;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

                OUT.texcoord = v.texcoord;

                OUT.color = v.color * _Color;
                return OUT;
            }

            sampler2D _AlphaLUT;
            float _AlphaDraw;
            half4 baseColor = half4(1,1,1,1);
            float drawThreshold = 0.9;

            fixed4 frag(v2f IN) : SV_Target
            {
                half4 color = baseColor;

                #ifdef UNITY_UI_CLIP_RECT
                color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif

                // Sample the LUT and set alpha to either 0 or 1 depeding on the sample and the _AlphaDraw value.
                float lutSample = tex2D(_AlphaLUT, IN.texcoord);

                float clampedAlpha = clamp((lutSample - 1.0) + _AlphaDraw, 0.0, 1.0);

                float stepAlpha = step(clampedAlpha, drawThreshold);

            	color.a = stepAlpha;
				
                #ifdef UNITY_UI_ALPHACLIP
                clip (color.a - 0.001);
                #endif

                return color;
            }
        ENDCG
        }
    }
}
