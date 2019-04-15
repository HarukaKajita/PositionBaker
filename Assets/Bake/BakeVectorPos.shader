Shader "ShaderBaker/ObjectPosVectorBake"
{
  Properties
  {
    [KeywordEnum(VectorMode, LengthMode, RawPosition)] _BakeValue ("Bake Value", int) = 0
    _MaxLength ("Max Length", float) = 200
  }
  SubShader
  {
    Tags { "RenderType" = "Transparent" }
    Cull Off
    LOD 100
    ZTest Always
    
    Pass
    {
      CGPROGRAM
      
      #pragma vertex vert
      #pragma geometry geom
      #pragma fragment frag
      
      #include "UnityCG.cginc"
      
      struct appdata
      {
        float4 vertex: POSITION;
        float2 uv: TEXCOORD0;
      };
      
      struct v2f
      {
        float2 uv: TEXCOORD0;
        float4 vertex: SV_POSITION;
        float3 pos: TEXCOORD1;
      };
      
      int _BakeValue;
      float _MaxLength;
      
      float3 adjustVec(float3 normalizedVec)
      {
        float3 retCol = normalizedVec = normalizedVec * 0.5 + 0.5;
        return retCol;
      }
      
      fixed3 adjustLength(float length)
      {
        float maxLength = _MaxLength;
        uint bits = length / maxLength * (pow(2, 24) - 1);
        uint R = bits % 256;
        uint G = (bits >> 8) % 256;
        uint B = (bits >> 16) % 256;
        fixed3 color = fixed3((float)R / 255, (float)G / 255, (float)B / 255);
        return color;
      }
      
      float decodeLength(fixed3 color)
      {
        float maxLength = _MaxLength;
        uint3 RGB = color * 255.0;
        uint v0 = RGB.r;
        uint v1 = RGB.g << 8;
        uint v2 = RGB.b << 16;
        uint scaledLength = v0 + v1 + v2;
        float length = scaledLength / (pow(2, 24) - 1) * maxLength;
        return length;
      }
      
      v2f vert(appdata v)
      {
        v2f o;
        o.vertex = v.vertex;
        o.uv = v.uv;
        o.pos = v.vertex.xyz;
        return o;
      }
      //1024/9 = 113....
      [maxvertexcount(6 )]
      void geom(triangle v2f input[3], inout TriangleStream < v2f > outStream)
      {
        [unroll]
        for (int j = 0; j < 3; j ++)
        {
          float2 uv = input[j].uv;
          float3 position = float3(uv, 2);
          input[j].vertex = mul(UNITY_MATRIX_VP, float4(position, 1));
          
          outStream.Append(input[j]);
        }

        outStream.RestartStrip();

        [unroll]
        for(int k = 0; k < 3; k++){
          input[k].vertex = UnityObjectToClipPos(input[k].pos);
          outStream.Append(input[k]);
        }
      }
      
      float4 frag(v2f i): SV_Target
      {
        float4 col = float4(i.pos, 1);
        
        
        if(_BakeValue == 0 || _BakeValue == 2)
        {
          float3 c = col.rgb;
          if (_BakeValue == 0) c = normalize(c);
          col.rgb = adjustVec(c);
        }
        else if(_BakeValue == 1)
        {
          float l = length(col.rgb);
          col.rgb = adjustLength(l);
        }
        return col;
      }
      ENDCG
      
    }
  }
}
