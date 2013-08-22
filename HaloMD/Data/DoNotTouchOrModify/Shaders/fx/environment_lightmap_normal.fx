Texture	Texture0;
Texture	Texture1;
Texture	Texture2;
Texture	Texture3;

/* DAJ
sampler TexSampler0 = sampler_state
{
    Texture = (Texture0);
};

sampler TexSampler1 = sampler_state
{
    Texture = (Texture1);
};

sampler TexSampler2 = sampler_state
{
    Texture = (Texture2);
};

sampler TexSampler3 = sampler_state
{
    Texture = (Texture3);
};

half4 c_material_color;
half4 c_plasma_animation;
half4 c_primary_color;
half4 c_secondary_color;
half4 c_plasma_on_color;
half4 c_plasma_off_color;

half calculate_plasma(half4 color)
{
	half plasma_intermediate1 = pow( c_plasma_animation.b + (0.5-color.a), 2 );
	half plasma_intermediate2 = pow( color.a + c_plasma_animation.a, 2 );
	
	half plasma = plasma_intermediate1 > 0.5 ? plasma_intermediate1 : plasma_intermediate2;

	plasma = pow(plasma,2);

	plasma = pow((2*plasma)-1,2);
	
	plasma = ( plasma > 0.5 ) ? 0 : plasma;
	
	return plasma;
}

half4 LightmapNormal(
    half4 Diff : COLOR0,
    half2 Tex0  : TEXCOORD0,
    half2 Tex1  : TEXCOORD1,
    half2 Tex2  : TEXCOORD2,
    half3 Tex3  : TEXCOORD3) : COLOR
{
	half4 bump_color = tex2D(TexSampler0,Tex0);
	half4 self_illumination_color = tex2D(TexSampler1, Tex1);
	half4 lightmap_color = tex2D(TexSampler2, Tex2);
	half4 normal_color = texCUBE(TexSampler3, Tex3);

	////////////////////////////////////////////////////////////
	// calculate plasma
	////////////////////////////////////////////////////////////
	half plasma = calculate_plasma(self_illumination_color);
		
	////////////////////////////////////////////////////////////
	// calculate bump attenuation
	////////////////////////////////////////////////////////////
	half bump_attenuation = dot((2*bump_color)-1, (2*normal_color)-1);
//	bump_attenuation = (bump_attenuation * Diff.a) + 1-Diff.a;
	
	////////////////////////////////////////////////////////////
	// calculate primary and secondary glow
	////////////////////////////////////////////////////////////
	half3 primary_and_secondary_glow = (c_primary_color * self_illumination_color.r) + (c_secondary_color * self_illumination_color.g);
	
	half3 plasma_color = (c_plasma_on_color * plasma) + c_plasma_off_color;
	
	half3 plasma_primary_and_secondary = (plasma_color * self_illumination_color.b) + primary_and_secondary_glow;
	
//	half4 final_color = half4(((c_material_color * bump_attenuation) * lightmap_color) + plasma_primary_and_secondary, bump_color.a);
	
//	return final_color;

	return half4((c_material_color * lightmap_color) + plasma_primary_and_secondary, bump_color.a);
}

PixelShader PS_LightmapNormal_ps_2_0 = compile PS_2_0_TARGET LightmapNormal();

Technique ps_2_0
{
    Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_LightmapNormal_ps_2_0);
 	}
}
*/
Technique ps_1_1
{
    Pass P0
	{
		PixelShaderConstant[0] = (c_material_color);
		PixelShaderConstant[1] = (c_plasma_animation);
		PixelShaderConstant[2] = (c_primary_color);
		PixelShaderConstant[3] = (c_secondary_color);
		PixelShaderConstant[4] = (c_plasma_on_color);
		PixelShaderConstant[5] = (c_plasma_off_color);

		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);
		Texture[2]	= (Texture2);
		Texture[3]	= (Texture3);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader			= asm
		{
			TEMP r0, r1, r2;
		
			PARAM c0 = program.env[0];	# c0 - material color
			PARAM c1 = program.env[1];	# c1 - plasma animation
			PARAM c2 = program.env[2];	# c2 - primary color
			PARAM c3 = program.env[3];	# c3 - secondary color
			PARAM c4 = program.env[4];	# c4 - plasma on color
			PARAM c5 = program.env[5];	# c5 - plasma off color
			
			PARAM c6 = { 1.0, 0.0, 0.0, 0.0	};	# c6 - primary mask
			PARAM c7 = { 0.0, 1.0, 0.0, 1.0	};	# c7 - secondary mask
			
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color.primary;
			ATTRIB v1 = fragment.color.secondary;
			
			TEMP t0, t1, t2, t3;
			TEMP t0_bx2, t3_bx2;
			TEX t0, f0, texture[0], 2D;
			TEX t1, f1, texture[1], 2D;
			TEX t2, f2, texture[2], 2D;
			TEX t3, f3, texture[3], CUBE;

			OUTPUT oC0 = result.color;
			
			SUB t0_bx2, t0, half;			
			MUL t0_bx2, t0_bx2, two;
			SUB t3_bx2, t3, half;			
			MUL t3_bx2, t3_bx2, two;
			DP3_SAT t0, t0_bx2, t3_bx2;
			MOV t0.a, v0.a;					#DAJ BUGFIX othewise alpha is zero
			
			DP3_SAT r0, t1, c6;
			DP3_SAT r1, t1, c7;
			MUL r1.rgb, r1, c3;
			MAD r1.rgb, r0, c2, r1;
			
#DAJ 		MAD r1.a, v0.a, t0.b, 1-v0.a;
			SUB	r2.a, c7.a, v0.a;
			MAD r1.a, v0.a, t0.b, r2.a;
			
			MAD r0.rgb, c4, r1.a, c5;
			MOV r0.a, t1.b;
			MAD r0.rgb, r0, r0.a, r1;
			MUL r0.a, r1.a, c0;
			MAD r0.rgb, t2, c0, r0;	
			MOV r0.a, t0.a;

			MOV     oC0, r0;	#DAJ save off
		};
 	}
}

Technique ps_0_0
{
    Pass P0
	{
		ColorOp[0]			= SelectArg1;
		ColorArg1[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;

		ColorOp[1]			= Add;
		ColorArg1[1]		= Texture;
		ColorArg2[1]		= Current;
		AlphaOp[1]			= SelectArg1;
		AlphaArg1[1]		= Current;

		ColorOp[2]			= Disable;
		AlphaOp[2]			= Disable;

		PixelShader			= Null;
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
