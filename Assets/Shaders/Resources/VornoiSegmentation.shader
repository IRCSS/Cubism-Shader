Shader "Unlit/VornoiSegmentation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex   vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv        : TEXCOORD0;
                float4 vertex    : SV_POSITION;
				float3 color     : TEXCOORD1;
				float4 screenpos : TEXCOORD2;

            };

            sampler2D _MainTex;
            float4    _MainTex_ST;


#define tiling        0.20
#define seedMaxOffset 0.20
			float rand(float seed) {
				return frac(sin(seed*51.24) * 417.26);
			}

			float3 sgmentIDtoColor(float3 segmentID) {

				return float3(rand(segmentID.x+1.52), rand(segmentID.y), rand(segmentID.z+0.21));

			}

			
			


            v2f vert (appdata v)
            {
                v2f o;

				float4 vPosT = v.vertex;
				vPosT = mul(unity_ObjectToWorld, vPosT);


				float3 vPosF = frac(vPosT*tiling);
				float3 vPosI = floor(vPosT*tiling);


				float  closestDis   = 10000.;
				float3 closestSeed  = float3(0., 0., 0.);
				float3 vertexToSeed = float3(0., 0., 0.);

				for (int x = -1; x <= 1; x++) {
					for (int y = -1; y <= 1; y++) {
						for (int z = -1; z <= 1; z++) {
							float3 neighbourPos = float3(float(x), float(y), float(z)) -float3(0.5,0.5,0.5);
							
							float3 vToNeighbour  = neighbourPos - vPosF;
							float  vToNeighbourD = length(vToNeighbour);

							if (vToNeighbourD < closestDis) {
								closestDis   = vToNeighbourD;
								closestSeed  = neighbourPos;
								vertexToSeed = vToNeighbour;
							}
						}
					}
				}




				vPosT = mul(UNITY_MATRIX_V,      vPosT);
				vPosT = mul(UNITY_MATRIX_P,      vPosT);

				o.screenpos = ComputeScreenPos(vPosT);
                o.vertex    = vPosT;
                o.uv        = TRANSFORM_TEX(v.uv, _MainTex);

				o.color = sgmentIDtoColor(vPosI + closestSeed) ;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
				float2 screenPos = i.screenpos.xy / i.screenpos.w;

				if (screenPos.x < 0.5) col.xyz = i.color.xyz;


                return col;
            }
            ENDCG
        }
    }
}
