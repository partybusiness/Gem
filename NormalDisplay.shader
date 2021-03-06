Shader "Unlit/NormalDisplay"
{
//Enables you to view the normals of the mesh as colours
//these can be rendered to a cubemap to use with the Unlit/Gem2 shader
	Properties
	{
	}
	SubShader
	{
		Tags { 
		"RenderType"="Opaque" 
		"DisableBatching" = "True"
	}
		Cull Off
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 normal: NORMAL;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.normal = v.normal;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = fixed4(i.normal*0.5+0.5,1);
				return col;
			}
			ENDCG
		}
	}
}
