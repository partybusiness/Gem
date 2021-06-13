Shader "Unlit/Gem2"
{
	//A gem shader that uses a sphere and normal cubemap for an approximation of the second refraction, rather than raytracing to every surface of the gem.
	Properties{
		_Cube("Face Normal Map", Cube) = "" {} // use the NormalDisplay on your gem's mesh and render it to a cubemap, which you use here
		_Cube2("Refraction Source", Cube) = "" {} // the environment you will see through the gem
		_Radius("Radius", float) = 1.3 //make this radius slightly larger than your gem's mesh
		_Refraction("Refraction", float) = 1.4
	}
	SubShader{
		Tags{ "RenderType" = "Opaque" 
		"DisableBatching" = "True"}
		//Cull Off
		Pass{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			
			uniform samplerCUBE _Cube;
			uniform samplerCUBE _Cube2;
			float _Radius;

			float _Refraction;
			

			struct vertexInput {
				float4 vertex : POSITION;
				float4 normal : NORMAL;
			};
			struct vertexOutput {
				float4 pos : SV_POSITION;
				float3 worldPos : TEXCOORD0;				
				float3 centrePos: TEXCOORD1;
				float3 normal: NORMAL;
			};
			vertexOutput vert(vertexInput input)
			{
				vertexOutput output;
				output.worldPos = mul(unity_ObjectToWorld, input.vertex).xyz;
				output.pos = UnityObjectToClipPos(input.vertex);
				output.centrePos = mul(unity_ObjectToWorld, float4(0,0,0,1)).xyz;
				output.normal = mul( unity_ObjectToWorld, float4( input.normal.xyz, 0.0 ) ).xyz;
				return output;
			}

			//returns position of sphere where viewDir intersects with a sphere of size radius
			float3 SpherePosition(float3 oc, float3 viewDir, float radius) {
				
				//project oc to a plane perpendicular to 0,0,0
				float3 projOC = oc - viewDir*dot(viewDir, oc);
				oc = projOC;
				float3 l = viewDir;
				float d = -(dot(l, (oc)))
					+ sqrt(
						pow(dot(l, (oc)), 2)
						- (length(oc) - _Radius * _Radius)
					);
				float3 resultDir = oc + d * viewDir;
				//rotate dir to match object rotation
				resultDir = mul( unity_WorldToObject, float4( resultDir, 0.0 ) ).xyz;
				return normalize(resultDir);
			}
			
			float4 frag(vertexOutput input) : COLOR
			{
				float3 inViewDir = normalize(input.worldPos - _WorldSpaceCameraPos);				
				float3 inNormal = normalize(input.normal);

				float3 viewDir = refract (inViewDir,  inNormal, 1.0/_Refraction); //going in
				
				float3 reflectDir = reflect(inViewDir, inNormal);
				if (length(viewDir)==0)
					viewDir = reflectDir;

				float3 sphereDir = SpherePosition(input.worldPos - input.centrePos, viewDir, _Radius);
				float3 innerNormal = normalize((texCUBE(_Cube, sphereDir)-0.5)*2.0); //get inner surface from sphere

				//get viewDir in local rotation
				float3 localView = mul( unity_WorldToObject, float4( viewDir, 0.0 ) ).xyz;
				//use innerNormal for reflecting view dir and sample again
				float3 refractDir = refract (localView, innerNormal, _Refraction); //going out
				
				localView = reflect(localView, innerNormal);

				if (length(refractDir)==0) 
					refractDir = localView;

				//rotate back to world
				viewDir = mul( unity_ObjectToWorld, float4( localView, 0.0 ) ).xyz;
				refractDir = mul( unity_ObjectToWorld, float4( refractDir, 0.0 ) ).xyz;
				float4 innerColour = texCUBE(_Cube2, refractDir, 0, 0);

				return innerColour;
			}
			ENDCG
		}
	}
}
