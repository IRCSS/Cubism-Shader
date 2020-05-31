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
#define cubsimStren   0.5 * sin(_Time)
			inline float rand(float seed) {
				return frac(sin(seed*51.24) * 417.26);
			}

			inline float3 sgmentIDtoColor(float3 segmentID) {

				return float3(rand(dot(segmentID, float3(12.26, 712.1, 7.215))),
					rand(dot(segmentID, float3(362.26, 81.16, 2.2))), 
					rand(dot(segmentID, float3(32.26, 8.621, 521.2))));

			}


			

			inline float4x4 AdjustViewMatrixToCubism(float4x4 ViewMatrix, float3 segmentSeed) {

				float3   camPosition = ViewMatrix._m03_m13_m23;
				float3   randSeed    = sgmentIDtoColor(segmentSeed) * (0.5 * sin(_Time.y + dot(segmentSeed.xyz, float3(5.2,0.215,7.721))) +0.6)*0.5;
					     
				float3   segmentOnZ  = max(4.,abs(dot(ViewMatrix._m02_m12_m22, segmentSeed - camPosition )))
					* ViewMatrix._m02_m12_m22 + camPosition;

				         camPosition = camPosition + randSeed;

				float3   foward      = normalize(segmentOnZ - camPosition);
				float3   right       = -cross(ViewMatrix._m01_m11_m21, foward );
				float3   up          = -cross(foward, right);
				float4x4 toreturn    = { right.x,   up.x,   foward.x, camPosition.x,
									     right.y,   up.y,   foward.y, camPosition.y,
									     right.z,   up.z,   foward.z, camPosition.z,
									          0.,     0.,         0.,            1.};
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
								closestSeed  = neighbourPos + vPosI + randSeed;
							}
						}
					}
				}


				vPosT = mul(AdjustViewMatrixToCubism(UNITY_MATRIX_V, closestSeed),      vPosT);
				//vPosT = mul(UNITY_MATRIX_V, vPosT);
				//vPosT.xyz += sgmentIDtoColor(closestSeed);

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
