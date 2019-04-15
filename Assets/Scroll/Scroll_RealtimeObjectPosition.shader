Shader "UVScroll/RealtimeObjectPosition"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GridScale ("GridScale", Range(0,100)) = 30
        _GridWidth ("GridWidth", Range(0,1)) = 0.05

        _ScrollLineWidth ("Scroll Line Width", Range(0,1)) = 0.05
        _ScrollSpeed ("ScrollSpeed", Range(0,1)) = 0.1
        [HDR] _EmissiveColor ("Emisive Color", color) = (1, 0, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 oPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _GridWidth;
            float _GridScale;
            float _ScrollLineWidth;
            float _ScrollSpeed;
            fixed3 _EmissiveColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.oPos = v.vertex.xyz;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv)*0.8;
                bool isGridLine = false;
                float2 scaledUV = i.uv *_GridScale;
                if(abs(frac(scaledUV.x-0.5)) < _GridWidth || abs(frac(scaledUV.y-0.5)) < _GridWidth) isGridLine = true;

                float dist = abs(i.oPos.y - (frac(_Time.y * _ScrollSpeed)-0.5) * 2.5);
                float contribution = smoothstep(0, _ScrollLineWidth, dist);

                if(isGridLine) col.rgb = lerp(_EmissiveColor, col.rgb, contribution);

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
