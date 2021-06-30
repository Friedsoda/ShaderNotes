Shader "MyLit/MyPhong"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_AOMap ("AO Map", 2D) = "white" {}
		_SpecMask ("Specular Mask", 2D) = "white" {}
		_NormalMap ("Normal Map", 2D) = "white" {}
		_NormalIntensity ("Normal Intensity", Range(0.0, 5.0)) = 1.0 
		_Shininess ("Shininess", Range(0.01, 100)) = 1.0
		_SpecIntensity ("Specular Intensity", Range(0.01, 5)) = 1.0
		_AmbientColor ("Ambient Color", Color) = (0,0,0,0)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal_dir : TEXCOORD1; 
				float3 pos_world : TEXCOORD2;
				float3 tangent_dir : TEXCOORD3;
				float3 binormal_dir : TEXCOORD4;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _AOMap;
			sampler2D _SpecMask;
			sampler2D _NormalMap;
			float _NormalIntensity;

			float4 _LightColor0;
			float _Shininess;
			float4 _AmbientColor;
			float _SpecIntensity;

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.normal_dir = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
				o.tangent_dir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.binormal_dir = normalize(cross(o.normal_dir, o.tangent_dir)) * v.tangent.w;
				o.pos_world = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				half4 base_col = tex2D(_MainTex, i.uv);
				half4 ao_col = tex2D(_AOMap, i.uv);
				half4 spec_mask = tex2D(_SpecMask, i.uv);
				half4 normalmap = tex2D(_NormalMap, i.uv);
				half3 normal_data = UnpackNormal(normalmap);
				normal_data.xy = normal_data.xy * _NormalIntensity;

				// normal map
				half3 normal_dir = normalize(i.normal_dir);
				half3 tangent_dir = normalize(i.tangent_dir);
				half3 binormal_dir = normalize(i.binormal_dir);
				float3x3 TBN = float3x3(tangent_dir, binormal_dir, normal_dir);
				normal_dir = normalize(mul(normal_data.xyz, TBN));
				//normal_dir = normalize(tangent_dir * normal_data.x * _NormalIntensity + binormal_dir * normal_data.y * _NormalIntensity + normal_dir * normal_data.z);

				half3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
				half3 light_dir = normalize(_WorldSpaceLightPos0.xyz);

				// diffuse light
				half NdotL = dot(normal_dir, light_dir);
				half3 diffuse_col = max(0.0, NdotL) * _LightColor0.xyz * base_col;
				// specular 
				half3 half_dir = normalize(light_dir + view_dir);
				half NdotH = dot(normal_dir, half_dir);
				half3 specular_col = pow(max(0, NdotH), _Shininess) * _LightColor0.xyz * _SpecIntensity * spec_mask;

				half3 final_col = (diffuse_col + specular_col + _AmbientColor) * ao_col;
				return half4(final_col, 1.0);
			}
			ENDCG
		}

		Pass
		{
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdadd

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal_dir : TEXCOORD1; 
				float3 pos_world : TEXCOORD2;
				float3 tangent_dir : TEXCOORD3;
				float3 binormal_dir : TEXCOORD4;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _AOMap;
			sampler2D _SpecMask;
			sampler2D _NormalMap;
			float _NormalIntensity;

			float4 _LightColor0;
			float _Shininess;
			float _SpecIntensity;

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.normal_dir = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
				o.tangent_dir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.binormal_dir = normalize(cross(o.normal_dir, o.tangent_dir)) * v.tangent.w;
				o.pos_world = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				half4 base_col = tex2D(_MainTex, i.uv);
				half4 ao_col = tex2D(_AOMap, i.uv);
				half4 spec_mask = tex2D(_SpecMask, i.uv);
				half4 normalmap = tex2D(_NormalMap, i.uv);
				half3 normal_data = UnpackNormal(normalmap);
				normal_data.xy = normal_data.xy * _NormalIntensity;

				// normal map
				half3 normal_dir = normalize(i.normal_dir);
				half3 tangent_dir = normalize(i.tangent_dir);
				half3 binormal_dir = normalize(i.binormal_dir);
				float3x3 TBN = float3x3(tangent_dir, binormal_dir, normal_dir);
				normal_dir = normalize(mul(normal_data.xyz, TBN));
				//normal_dir = normalize(tangent_dir * normal_data.x * _NormalIntensity + binormal_dir * normal_data.y * _NormalIntensity + normal_dir * normal_data.z);

				half3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
				#if defined (DIRECTIONAL)
				half3 light_dir = normalize(_WorldSpaceLightPos0.xyz);
				half attenuation = 1.0;
				#elif defined (POINT)
				half3 light_dir = normalize(_WorldSpaceLightPos0.xyz - i.pos_world);
				half distance = length(_WorldSpaceLightPos0.xyz - i.pos_world);
				half range = 1.0 / unity_WorldToLight[0][0];
				half attenuation = saturate((range - distance) / range);
				#endif

				// diffuse light
				half NdotL = dot(normal_dir, light_dir);
				half3 diffuse_col = max(0.0, NdotL) * _LightColor0.xyz * base_col * attenuation;
				// specular 
				half3 half_dir = normalize(light_dir + view_dir);
				half NdotH = dot(normal_dir, half_dir);
				half3 specular_col = pow(max(0, NdotH), _Shininess) * _LightColor0.xyz * _SpecIntensity * spec_mask * attenuation;

				half3 final_col = (diffuse_col + specular_col) * ao_col;
				return half4(final_col, 1.0);
			}
			ENDCG
		}
	}
}
