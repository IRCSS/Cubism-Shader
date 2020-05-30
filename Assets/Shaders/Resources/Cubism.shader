Shader "Unlit/Cubism"
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


#define tiling        0.2
#define seedMaxOffset 1.0
#define lineThickness 1.3
			inline float rand(float seed) {
				return frac(sin(seed*51.24) * 417.26);
			}

			inline float3 sgmentIDtoColor(float3 segmentID) {

				return float3(rand(dot(segmentID, float3(12.26, 712.1, 7.215))),
					rand(dot(segmentID, float3(362.26, 81.16, 2.2))), 
					rand(dot(segmentID, float3(32.26, 8.621, 521.2))));

			}


			

			inline float4x4 AdjustViewMatrix(float4x4 ViewMatrix, float3 segmentSeed) {
				float4x4 toreturn = { ViewMatrix[0][0], ViewMatrix[0][1], ViewMatrix[0][2], ViewMatrix[0][3] + segmentSeed.x,
									  ViewMatrix[1][0], ViewMatrix[1][1], ViewMatrix[1][2], ViewMatrix[1][3] + segmentSeed.y,
									  ViewMatrix[2][0], ViewMatrix[2][1], ViewMatrix[2][2], ViewMatrix[2][3] + segmentSeed.z,
									  ViewMatrix[3][0], ViewMatrix[3][1], ViewMatrix[3][2], ViewMatrix[3][3]   };
				return toreturn;

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
				for (int x = -1; x <= 1; x++) {
					for (int y = -1; y <= 1; y++) {
						for (int z = -1; z <= 1; z++) {

							float3 neighbourPos  = float3(float(x), float(y), float(z));
							float3 randSeed      = sgmentIDtoColor(vPosI + neighbourPos) * seedMaxOffset;
							
							float3 vToNeighbour  = randSeed + neighbourPos - vPosF;
							float  vToNeighbourD = length(vToNeighbour);

							if (vToNeighbourD <= closestDis) {
								closestDis   = vToNeighbourD;
								closestSeed  = neighbourPos + vPosI;
							}
						}
					}
				}


				vPosT = mul(AdjustViewMatrix(UNITY_MATRIX_V, sgmentIDtoColor(closestSeed)),      vPosT);

				vPosT = mul(UNITY_MATRIX_P,      vPosT);

				o.screenpos = ComputeScreenPos(vPosT);
                o.vertex    = vPosT;
                o.uv        = TRANSFORM_TEX(v.uv, _MainTex);

				o.color = sgmentIDtoColor(closestSeed);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
				float2 screenPos = i.screenpos.xy / i.screenpos.w;

				//if (screenPos.x < 0.5) col.xyz = i.color.xyz;


                return col;
            }
            ENDCG
        }
    }
}
