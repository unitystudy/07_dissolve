Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_GradationTex("Gradation Texture", 2D) = "white" {}
		_AlphaTex("Alpha Texture", 2D) = "white" {}
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
            // make fog work
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
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
			sampler2D _GradationTex;
			sampler2D _AlphaTex;
			float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

			fixed2 random2(float2 st) {
				st = float2(dot(st, fixed2(127.1, 311.7)),
					dot(st, fixed2(269.5, 183.3)));
				return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
			}

			float Noise(float2 st)
			{
				float2 p = floor(st);
				float2 f = frac(st);
				float2 u = f * f * (3.0 - 2.0 * f);

				float v00 = random2(p + fixed2(0, 0));
				float v10 = random2(p + fixed2(1, 0));
				float v01 = random2(p + fixed2(0, 1));
				float v11 = random2(p + fixed2(1, 1));

				return lerp(lerp(dot(random2(p + float2(0.0, 0.0)), f - float2(0.0, 0.0)),
					dot(random2(p + float2(1.0, 0.0)), f - float2(1.0, 0.0)), u.x),
					lerp(dot(random2(p + float2(0.0, 1.0)), f - float2(0.0, 1.0)),
						dot(random2(p + float2(1.0, 1.0)), f - float2(1.0, 1.0)), u.x), u.y);
			}

			float Fbm(float2 texcoord)
			{
				float2 tc = texcoord * float2(-3.0, 1.0);
				float time = -0.1 * _Time.y;
				float noise = sin(tc.y +
					abs(Noise((tc + time) * 1.0)) +
					abs(Noise((tc + time) * 2.0)) * 0.5 +
					abs(Noise((tc + time) * 4.0)) * 0.25 +
					abs(Noise((tc + time) * 8.0)) * 0.125 +
					abs(Noise((tc + time) * 16.0)) * 0.0625 +
					abs(Noise((tc + time) * 32.0)) * 0.03125 +
					abs(Noise((tc + time) * 64.0)) * 0.015625 +
					abs(Noise((tc + time) * 128.0)) * 0.0078125);
				noise = noise / (1.0 + 0.5 + 0.25 + 0.125 + 0.0625 + 0.03125 + 0.015625 + 0.0078125); // 正規化
				noise = sin(100 * noise);           // 縞模様をつける
				noise = noise * 0.5 + 0.5;          // 正値化

				return noise;
			}

			fixed4 frag (v2f i) : SV_Target
            {
				fixed4 col = tex2D(_MainTex, i.uv);

				float fbm = Fbm(i.uv);

				float param = frac(0.2 * _Time.y);// [0,1]
				param = 4.0 * param - 2.0;// [-2,2]

				fbm = fbm + param;
				if (1.0 < fbm) discard;

				fixed4 fire = tex2D(_GradationTex, float2(fbm, 0));

				float alpha = tex2D(_AlphaTex, float2(fbm, 0));
				
				col = lerp(fire, col, alpha);

//				col.rgb = fbm;

				return col;
            }
            ENDCG
        }
    }
}
