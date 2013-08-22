Texture	Texture0;
Texture	Texture1;
Texture	Texture2; 
Texture	Texture3;
/* //DAJ
sampler TexSampler0 = sampler_state
{
    Texture		= (Texture0);
};

sampler TexSampler1 = sampler_state
{
    Texture		= (Texture1);
};

sampler TexSampler2 = sampler_state
{
    Texture		= (Texture2);
};

sampler TexSampler3 = sampler_state
{
    Texture		= (Texture3);
};

half4 c_eye_forward;
half4 c_view_perpendicular_color;
half4 c_view_parallel_color;
half4 c_group_intensity;

half3 CalculateReflectionVector(half2 Tex0, half4 Tex1, half4 Tex2, half4 Tex3)
{
	half3 bump_color = (2*tex2D(TexSampler0, Tex0))-1;

	half3 N = half3(dot(Tex1, bump_color), dot(Tex2, bump_color), dot(Tex3, bump_color));
	half3 E = half3(Tex1.w, Tex2.w, Tex3.w);
	return normalize( ( 2 * dot( N , E ) * N ) - E);
}

half4 GlassReflectionBumped(
    half4 Diff : COLOR0,
    half2 Tex0  : TEXCOORD0,
    half4 Tex1  : TEXCOORD1,
    half4 Tex2  : TEXCOORD2,
    half4 Tex3  : TEXCOORD3) : COLOR
{
	half3 R = CalculateReflectionVector(Tex0, Tex1, Tex2, Tex3);
	
	half3 reflection_color = tex3D( TexSampler3, R );
	half3 specular_color = pow(reflection_color, 8 );
	
	half3 diffuse_reflection = tex2D( TexSampler2, Tex2 );
	diffuse_reflection = dot( (2*diffuse_reflection)-1, c_eye_forward );
	diffuse_reflection = pow( diffuse_reflection, 2 );
	
	half specular_mask = Diff.a * c_group_intensity;
	
	half attenuation = lerp( c_view_parallel_color.a, c_view_perpendicular_color.a, diffuse_reflection.b );
	
	half3 tint_color = lerp( c_view_parallel_color, c_view_perpendicular_color, diffuse_reflection.b );
	
	half3 tinted_reflection = lerp( specular_color, reflection_color, tint_color );

	half3 final_color = tinted_reflection * ( attenuation * specular_mask );
	
	return half4( final_color, 1.0 );
}

Technique ps_2_0
{
    Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= compile PS_2_0_TARGET GlassReflectionBumped();
 	}
}
*/
Technique ps_1_1
{
    Pass P0
	{
		Texture[0]	= (Texture0);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;
			OUTPUT oC0 = result.color;

			PARAM c7 = { 0.5, 0.5, 0.5, 0.5 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			
			TEMP t0_bx2;
			SUB t0_bx2, t0, half;			
			MUL t0_bx2, t0_bx2, two;

			
			DP3_SAT r0, t0_bx2, c7;
			MUL r0, r0, r0;
			MUL r0, r0, r0;
			MUL r0, r0, v0.a;

			MOV oC0, r0;	#DAJ save off
		};
 	}
}

Technique ps_0_0
{
    Pass P0
	{
 	}
}


Technique fallback
{
    Pass P0
	{
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;

		ColorOp[1]			= Disable;
		AlphaOp[1]			= Disable;

		PixelShader			= Null;
	}
}
