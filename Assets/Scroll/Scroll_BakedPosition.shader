Shader "UVScroll/BakedPosition"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GridScale ("GridScale", Range(0,100)) = 70
        _GridWidth ("GridWidth", Range(0,1)) = 0.05

        _ScrollLineWidth ("Scroll Line Width", Range(0,1)) = 0.1
        _ScrollSpeed ("ScrollSpeed", Range(0,1)) = 0.3
        [HDR] _EmissiveColor ("Emisive Color", color) = (1, 0, 1, 1)

        _BakedVectorTex ("Baked Vector Tex", 2D) = "white"{}
        _BakedLengthTex ("Baked Length Tex", 2D) = "white"{}
        _MaxLength ("Max Length", float) = 200

        [Toggle] _Debug ("Debug", int) = 0
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

            sampler2D _BakedVectorTex;
            sampler2D _BakedLengthTex;
            float2 _BakedLengthTex_TexelSize;
            float _MaxLength;

            bool _Debug;

            float decodeLength(fixed3 color);
            float3 decodeBakedPos(sampler2D vectorTex, sampler2D lengthTex, float2 texelSize, float2 uv);

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

                //ベイクした座標を復元
                float3 bakedPosition = decodeBakedPos(_BakedVectorTex, _BakedLengthTex, _BakedLengthTex_TexelSize, i.uv);
                float dist = abs(bakedPosition.y - (frac(_Time.y * _ScrollSpeed)-0.5) * 2.5);
                float contribution = smoothstep(0, _ScrollLineWidth, dist);

                if(isGridLine) col.rgb = lerp(_EmissiveColor, col.rgb, contribution);
                if (_Debug) col.rgb = bakedPosition;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }

            //Lengthテクスチャからベクトルの長さを復元する関数
            float decodeLength(fixed3 color){
                float maxLength = _MaxLength;//ベイク時に使った値が必要
                uint3 RGB = color * 255.0;
                uint v0 = RGB.r;
                uint v1 = RGB.g << 8;
                uint v2 = RGB.b << 16;
                uint scaledLength = v0 + v1 + v2;
                float length = scaledLength/(pow(2,24)-1) * maxLength;
                return length;
            }

            //ベイクテクスチャから座標を取得する関数
            float3 decodeBakedPos(sampler2D vectorTex, sampler2D lengthTex, float2 texelSize, float2 uv){
                float3 col = tex2D(vectorTex, uv)*2.0 - 1;
                //近傍をサンプリングして馴染ませる
                int colorNum = 0;
                float w = 1;
                float3 l0 = tex2D(lengthTex, uv + texelSize * float2(0,0)*w);
                float3 l1 = tex2D(lengthTex, uv + texelSize * float2(1,0)*w);
                float3 l2 = tex2D(lengthTex, uv + texelSize * float2(0,1)*w);
                float3 l3 = tex2D(lengthTex, uv + texelSize * float2(-1,0)*w);
                float3 l4 = tex2D(lengthTex, uv + texelSize * float2(0,-1)*w);
                colorNum = (l0 != float3(0,0,0)) + (l1 != float3(0,0,0)) + (l2 != float3(0,0,0)) + (l3 != float3(0,0,0)) + (l4 != float3(0,0,0));
                //float length = decodeLength((l0 + l1 + l2 + l3 + l4) / colorNum);
                float length = decodeLength(l0);
                col *= length;
                return col;
            }
            ENDCG
        }
    }
}
