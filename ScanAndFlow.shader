// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "CS01_03/MyScan1"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_RimColor ("Rim Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_InnerColor ("Inner Color", Color) = (0.0, 0.0, 0.0, 0.0)
		_InnerAlpha ("Inner Alpha", Float) = 0.5
		_RimIntensity ("Rim Intensity", Float) = 1.0
		_RimMin ("Rim Min", Range(-1, 1)) = 0.0
		_RimMax ("Rim Max", Range(0, 2)) = 1.0
		_FlowTex ("Flow Emission", 2D) = "white" {}
		_FlowTilling ("Flow Tilling", Vector) = (2.0, 2.0, 0.0, 0.0)
		_FlowSpeed ("Flow Speed", Vector) = (0.0, 0.0, 0.0, 0.0)
		_FlowIntensity ("Flow Intensity", Float) = 0.5
	}
	SubShader
	{
		Tags { "Queue"="Transparent" }
		LOD 100

		Pass
		{
			Zwrite Off
			Blend SrcAlpha One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 pos_world : TEXCOORD1;
				float3 normal_world : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _RimMin;
			float _RimMax;
			float4 _InnerColor;
			float4 _RimColor;
			float _RimIntensity;
			sampler2D _FlowTex;
			float4 _FlowSpeed;
			float4 _FlowTilling;
			float _FlowIntensity;
			float _InnerAlpha;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				o.normal_world = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
				o.pos_world = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// Rim light
				half3 normal_world = i.normal_world;
				half3 view_world = normalize(_WorldSpaceCameraPos - i.pos_world);
				half NdotV = saturate(dot(normal_world, view_world));
				half fresnel = 1 - NdotV;
				fresnel = smoothstep(_RimMin, _RimMax, fresnel);
				half emiss = pow(tex2D(_MainTex, i.uv).r, 5.0);
				half rim_alpha = saturate(fresnel + emiss);
				half3 rim_color = lerp(_InnerColor.xyz, _RimColor.xyz * _RimIntensity, rim_alpha);

				// Flow Light
				half4 origin_world = mul(unity_ObjectToWorld, float4(0.0, 0.0, 0.0, 1.0));
				half2 uv_flow = (i.pos_world.xy - origin_world.xy) * _FlowTilling.xy + 
								_FlowSpeed.xy * _Time.y;
				float4 flow_emiss = tex2D(_FlowTex, uv_flow);
				float3 flow_color = flow_emiss.rgb * _FlowIntensity;
				float flow_alpha = flow_emiss.a * _FlowIntensity;

				float3 final_color = rim_color + flow_color;
				float final_alpha = saturate(rim_alpha + flow_alpha + _InnerAlpha);

				return float4(final_color, final_alpha);
			}
			ENDCG
		}
	}
}
