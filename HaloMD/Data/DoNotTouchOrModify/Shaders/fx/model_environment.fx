Texture Texture0;
Texture Texture1;
Texture Texture2;
Texture Texture3;

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

half4 c_primary_change_color;
half4 c_fog_color_correction_0;
half4 c_fog_color_correction_E;
half4 c_fog_color_correction_1;
half4 c_self_illumination_color;

static const int detail_function_biased_multiply	= 0;
static const int detail_function_multiply			= 1;
static const int detail_function_biased_add			= 2;

///////////////////////////////////////////////////////////////////////////////
// Pixel Shader 2.0 shaders
///////////////////////////////////////////////////////////////////////////////
half4 ModelEnvironmentNoMask(
    half4 Diff : COLOR0,
    half4 Spec : COLOR1,
    half2 Tex0  : TEXCOORD0,
    half2 Tex1  : TEXCOORD1,
    half2 Tex2  : TEXCOORD2,
    half4 Tex3  : TEXCOORD3,
    uniform int nDetailFunction,
    uniform bool bDetailBeforeReflection,
    uniform const bool bInverse,
    uniform const bool bPlanarAtmosphericFog) : COLOR
{
	half4 T0 = tex2D( TexSampler0, Tex0 );
	half4 T1 = tex2D( TexSampler1, Tex1 );
	half4 T2 = tex2D( TexSampler2, Tex2 );
	half4 T3 = texCUBE( TexSampler3, Tex3 );
	
	half4 R0;
	half4 R1;
	half4 D0 = Diff;
	half4 D1 = Spec;
	half3 SRCCOLOR;
	half SRCALPHA;
		
	// combiner 0
	
	// combiner 1

	// combiner 2
	R1.a	= T2.b*D1.a;
	
	// combiner 4
	T3.rgb	= T3*D1;
	
	if(bDetailBeforeReflection)
	{
		// combiner 6
		R0 = (T0*D0) + (T3*R1.a);
		
		// combiner 7
		if(detail_function_biased_multiply==nDetailFunction)
		{
			R0.rgb	= (R0*T1)*2;
		}
		else if(detail_function_multiply==nDetailFunction)
		{
			R0.rgb	= R0*T1;
		}
		else if(detail_function_biased_add==nDetailFunction)
		{
			R0.rgb	= R0+((2*T1)-1);
		}
	}
	else
	{
		// combiner 6
		if(detail_function_biased_multiply==nDetailFunction)
		{
			T0.rgb	= (T0*T1)*2;
		}
		else if(detail_function_multiply==nDetailFunction)
		{
			T0.rgb	= T0*T1;
		}
		else if(detail_function_biased_add==nDetailFunction)
		{
			T0.rgb	= T0+((2*T1)-1);
		}
		
		// combiner 7
		R0 = (T0*D0) + (T3*R1.a);
	}

	if(bPlanarAtmosphericFog)
	{
		// combiner 5
		R1.rgb	= saturate(c_fog_color_correction_1 - (D0.a*c_fog_color_correction_E));
		
		// final combiner
		SRCCOLOR = lerp((R0*c_fog_color_correction_0.a), c_fog_color_correction_0, D0.a) + R1;
	}
	else
	{
		// final combiner
		SRCCOLOR = R0;
	}

	SRCALPHA = T2.a;

	return half4( SRCCOLOR, SRCALPHA );
}

PixelShader PS_EnvironmentNoMaskDetailBeforeReflectionBiasedMultiply_ps_2_0	= compile PS_2_0_TARGET ModelEnvironmentNoMask( detail_function_biased_multiply, true, false, false );
PixelShader PS_EnvironmentNoMaskDetailBeforeReflectionMultiply_ps_2_0		= compile PS_2_0_TARGET ModelEnvironmentNoMask( detail_function_multiply, true, false, false );
PixelShader PS_EnvironmentNoMaskDetailBeforeReflectionBiasedAdd_ps_2_0		= compile PS_2_0_TARGET ModelEnvironmentNoMask( detail_function_biased_add, true, false, false );
PixelShader PS_EnvironmentNoMaskDetailAfterReflectionBiasedMultiply_ps_2_0	= compile PS_2_0_TARGET ModelEnvironmentNoMask( detail_function_biased_multiply, false, false, false );
PixelShader PS_EnvironmentNoMaskDetailAfterReflectionMultiply_ps_2_0		= compile PS_2_0_TARGET ModelEnvironmentNoMask( detail_function_multiply, false, false, false );
PixelShader PS_EnvironmentNoMaskDetailAfterReflectionBiasedAdd_ps_2_0		= compile PS_2_0_TARGET ModelEnvironmentNoMask( detail_function_biased_add, false, false, false );

PixelShader PS_EnvironmentNoMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_2_0	= compile PS_2_0_TARGET ModelEnvironmentNoMask( detail_function_biased_multiply, true, false, true );
PixelShader PS_EnvironmentNoMaskDetailBeforeReflectionMultiplyComplexFog_ps_2_0			= compile PS_2_0_TARGET ModelEnvironmentNoMask( detail_function_multiply, true, false, true );
PixelShader PS_EnvironmentNoMaskDetailBeforeReflectionBiasedAddComplexFog_ps_2_0		= compile PS_2_0_TARGET ModelEnvironmentNoMask( detail_function_biased_add, true, false, true );
PixelShader PS_EnvironmentNoMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_2_0	= compile PS_2_0_TARGET ModelEnvironmentNoMask( detail_function_biased_multiply, false, false, true );
PixelShader PS_EnvironmentNoMaskDetailAfterReflectionMultiplyComplexFog_ps_2_0			= compile PS_2_0_TARGET ModelEnvironmentNoMask( detail_function_multiply, false, false, true );
PixelShader PS_EnvironmentNoMaskDetailAfterReflectionBiasedAddComplexFog_ps_2_0			= compile PS_2_0_TARGET ModelEnvironmentNoMask( detail_function_biased_add, false, false, true );

Technique EnvironmentNoMaskDetailBeforeReflectionBiasedMultiply_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = (PS_EnvironmentNoMaskDetailBeforeReflectionBiasedMultiply_ps_2_0);
	}
}

Technique EnvironmentNoMaskDetailBeforeReflectionMultiply_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = (PS_EnvironmentNoMaskDetailBeforeReflectionMultiply_ps_2_0);
	}
}

Technique EnvironmentNoMaskDetailBeforeReflectionBiasedAdd_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = (PS_EnvironmentNoMaskDetailBeforeReflectionBiasedAdd_ps_2_0);
	}
}

Technique EnvironmentNoMaskDetailAfterReflectionBiasedMultiply_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = (PS_EnvironmentNoMaskDetailAfterReflectionBiasedMultiply_ps_2_0);
	}
}

Technique EnvironmentNoMaskDetailAfterReflectionMultiply_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = (PS_EnvironmentNoMaskDetailAfterReflectionMultiply_ps_2_0);
	}
}

Technique EnvironmentNoMaskDetailAfterReflectionBiasedAdd_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = (PS_EnvironmentNoMaskDetailAfterReflectionBiasedAdd_ps_2_0);
	}
}

Technique EnvironmentNoMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = (PS_EnvironmentNoMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_2_0);
	}
}

Technique EnvironmentNoMaskDetailBeforeReflectionMultiplyComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = (PS_EnvironmentNoMaskDetailBeforeReflectionMultiplyComplexFog_ps_2_0);
	}
}

Technique EnvironmentNoMaskDetailBeforeReflectionBiasedAddComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = (PS_EnvironmentNoMaskDetailBeforeReflectionBiasedAddComplexFog_ps_2_0);
	}
}

Technique EnvironmentNoMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = (PS_EnvironmentNoMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_2_0);
	}
}

Technique EnvironmentNoMaskDetailAfterReflectionMultiplyComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = (PS_EnvironmentNoMaskDetailAfterReflectionMultiplyComplexFog_ps_2_0);
	}
}

Technique EnvironmentNoMaskDetailAfterReflectionBiasedAddComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = (PS_EnvironmentNoMaskDetailAfterReflectionBiasedAddComplexFog_ps_2_0);
	}
}

///////////////////////////////////////////////////////////////////////////////
// Pixel Shader 1.4 shaders
///////////////////////////////////////////////////////////////////////////////
#define D0 v0
#define D1 v1
#define T0 r0
#define T1 r1
#define T1_x2 r1_x2
#define T1_bx2 r1_bx2
#define T2 r2
#define T3 r3
#define R0 r4
#define R1 r5
#define c_primary_change_color c0
#define c_fog_color_correction_0 c1
#define c_fog_color_correction_E c2
#define c_fog_color_correction_1 c3
#define c_self_illumination_color c4

#define FirstPhaseBegin \
    ps_1_4 \
 \
    texld T0, t0 \
    texld T1, t1 \
    texld T2, t2 \
 \
    mad R0, T2.a, c_primary_change_color, 1-T2.a \
    mul R1, T2.g, c_self_illumination_color

#define FirstPhaseEnd \
    mul R0.rgb, R0, T0 \
    mul R1, R0, R1

#define SecondPhaseComplexFogBegin \
    phase \
 \
    texld T0, t0 \
    texld T2, t2 \
    texld T3, t3 \
 \
    mul T3.rgb, T3, D1 \
    mad R0.rgb, D0, R0, R1 \
    mad R1.rgb, -D0.a, c_fog_color_correction_E, c_fog_color_correction_1 \
    +mul R1.a, T2.b, D1.a \
    mad R0.rgb, T3, R1.a, R0

#define SecondPhaseComplexFogEnd \
    mul R0.rgb, R0, c_fog_color_correction_0.a \
    lrp R0.rgb, D0.a, c_fog_color_correction_0, R0 \
    add r0.rgb, R0, R1 \
    +mov r0.a, T2.a

#define SecondPhaseBegin \
    phase \
 \
    texld T0, t0 \
    texld T2, t2 \
    texld T3, t3 \
 \
    mul T3.rgb, T3, D1 \
    mad R0.rgb, D0, R0, R1 \
    +mul R0.a, T2.b, D1.a \
    mad R0.rgb, T3, R0.a, R0

#define SecondPhaseEnd \
    mov r0.rgb, R0 \
    +mov r0.a, T2.a

#define BiasedMultiply(R) \
    mul R.rgb, R, T1_x2

#define Multiply(R) \
    mul R.rgb, R, T1

#define BiasedAdd(R) \
    add R.rgb, R, T1_bx2

PixelShader PS_EnvironmentNoMaskDetailBeforeReflectionBiasedMultiply_ps_1_4 = asm
{
    FirstPhaseBegin
    FirstPhaseEnd
    SecondPhaseBegin
    BiasedMultiply(R0)
    SecondPhaseEnd
};

PixelShader PS_EnvironmentNoMaskDetailBeforeReflectionMultiply_ps_1_4 = asm
{
    FirstPhaseBegin
    FirstPhaseEnd
    SecondPhaseBegin
    Multiply(R0)
    SecondPhaseEnd
};

PixelShader PS_EnvironmentNoMaskDetailBeforeReflectionBiasedAdd_ps_1_4 = asm
{
    FirstPhaseBegin
    FirstPhaseEnd
    SecondPhaseBegin
    BiasedAdd(R0)
    SecondPhaseEnd
};

PixelShader PS_EnvironmentNoMaskDetailAfterReflectionBiasedMultiply_ps_1_4 = asm
{
    FirstPhaseBegin
    BiasedMultiply(T0)
    FirstPhaseEnd
    SecondPhaseBegin
    SecondPhaseEnd
};

PixelShader PS_EnvironmentNoMaskDetailAfterReflectionMultiply_ps_1_4 = asm
{
    FirstPhaseBegin
    Multiply(T0)
    FirstPhaseEnd
    SecondPhaseBegin
    SecondPhaseEnd
};

PixelShader PS_EnvironmentNoMaskDetailAfterReflectionBiasedAdd_ps_1_4 = asm
{
    FirstPhaseBegin
    BiasedAdd(T0)
    FirstPhaseEnd
    SecondPhaseBegin
    SecondPhaseEnd
};

////////////////////
PixelShader PS_EnvironmentNoMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    BiasedMultiply(R0)
    SecondPhaseComplexFogEnd
};

PixelShader PS_EnvironmentNoMaskDetailBeforeReflectionMultiplyComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    Multiply(R0)
    SecondPhaseComplexFogEnd
};

PixelShader PS_EnvironmentNoMaskDetailBeforeReflectionBiasedAddComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    BiasedAdd(R0)
    SecondPhaseComplexFogEnd
};

PixelShader PS_EnvironmentNoMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    BiasedMultiply(T0)
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    SecondPhaseComplexFogEnd
};

PixelShader PS_EnvironmentNoMaskDetailAfterReflectionMultiplyComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    Multiply(T0)
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    SecondPhaseComplexFogEnd
};

PixelShader PS_EnvironmentNoMaskDetailAfterReflectionBiasedAddComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    BiasedAdd(T0)
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    SecondPhaseComplexFogEnd
};

// #undef D0
// #undef D1
// #undef T0
// #undef T1
// #undef T1_x2
// #undef T1_bx2
// #undef T2
// #undef T3
// #undef R0
// #undef R1
// #undef c_primary_change_color
// #undef c_fog_color_correction_0
// #undef c_fog_color_correction_E
// #undef c_fog_color_correction_1
// #undef c_self_illumination_color

#define SetState \
    PixelShaderConstant[0] = (c_primary_change_color); \
    PixelShaderConstant[1] = (c_fog_color_correction_0); \
    PixelShaderConstant[2] = (c_fog_color_correction_E); \
    PixelShaderConstant[3] = (c_fog_color_correction_1); \
    PixelShaderConstant[4] = (c_self_illumination_color); \
    Texture[0]	= (Texture0); \
    Texture[1]	= (Texture1); \
    Texture[2]	= (Texture2); \
    Texture[3]	= (Texture3); \
    ColorOp[0]	= Disable; \
    AlphaOp[0]	= Disable;

RAV */

Technique EnvironmentNoMaskDetailBeforeReflectionBiasedMultiply_ps_1_4
{
	Pass P0
	{
		// SetState
		PixelShaderConstant[0] = (c_primary_change_color);
	    PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
	    PixelShaderConstant[4] = (c_self_illumination_color);
	    Texture[0]	= (Texture0);
	    Texture[1]	= (Texture1);
	    Texture[2]	= (Texture2);
	    Texture[3]	= (Texture3);
	    ColorOp[0]	= Disable;
	    AlphaOp[0]	= Disable;
	        
		PixelShader = asm
		{
			TEMP t0, t1, t2, t3, t4, t5, t6, t7, tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM color = {0.0, 1.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB tc0 = fragment.texcoord[0];
			ATTRIB tc1 = fragment.texcoord[1];
			ATTRIB tc2 = fragment.texcoord[2];
			ATTRIB tc3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, tc0, texture[0], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MUL tmp1, r1, mulConst.r;
			MUL r4.rgb, r4, tmp1;
			MOV r0.rgb, r4;
			MOV r0.a, r2.a;
			MOV oC0, r0;
			#MOV oC0, color;
		};
		//PixelShader = (PS_EnvironmentNoMaskDetailBeforeReflectionBiasedMultiply_ps_1_4);
	}
}

Technique EnvironmentNoMaskDetailBeforeReflectionMultiply_ps_1_4
{
	Pass P0
	{
		// SetState
		PixelShaderConstant[0] = (c_primary_change_color);
	    PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
	    PixelShaderConstant[4] = (c_self_illumination_color);
	    Texture[0]	= (Texture0);
	    Texture[1]	= (Texture1);
	    Texture[2]	= (Texture2);
	    Texture[3]	= (Texture3);
	    ColorOp[0]	= Disable;
	    AlphaOp[0]	= Disable;
		    
		PixelShader = asm
		{
			TEMP t0, t1, t2, t3, t4, t5, t6, t7, tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM color = {0.0, 1.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB tc0 = fragment.texcoord[0];
			ATTRIB tc1 = fragment.texcoord[1];
			ATTRIB tc2 = fragment.texcoord[2];
			ATTRIB tc3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, tc0, texture[0], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MUL r4.rgb, r4, r1;
			MOV r0.rgb, r4;
			MOV r0.a, r2.a;
			MOV oC0, r0;
			#MOV oC0, color;
		};
		//PixelShader = (PS_EnvironmentNoMaskDetailBeforeReflectionMultiply_ps_1_4);
	}
}

Technique EnvironmentNoMaskDetailBeforeReflectionBiasedAdd_ps_1_4
{
	Pass P0
	{
		// SetState
		PixelShaderConstant[0] = (c_primary_change_color);
	    PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
	    PixelShaderConstant[4] = (c_self_illumination_color);
	    Texture[0]	= (Texture0);
	    Texture[1]	= (Texture1);
	    Texture[2]	= (Texture2);
	    Texture[3]	= (Texture3);
	    ColorOp[0]	= Disable;
	    AlphaOp[0]	= Disable;
		    
		PixelShader = asm
		{
			TEMP t0, t1, t2, t3, t4, t5, t6, t7, tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM color = {0.0, 1.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB tc0 = fragment.texcoord[0];
			ATTRIB tc1 = fragment.texcoord[1];
			ATTRIB tc2 = fragment.texcoord[2];
			ATTRIB tc3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, tc0, texture[0], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MAD tmp1, r1, mulConst.r, -const.b;
			ADD r4.rgb, r4, tmp1;
			MOV r0.rgb, r4;
			MOV r0.a, r2.a;
			MOV oC0, r0;
			#MOV oC0, color;		
		};
		//PixelShader = (PS_EnvironmentNoMaskDetailBeforeReflectionBiasedAdd_ps_1_4);
	}
}

Technique EnvironmentNoMaskDetailAfterReflectionBiasedMultiply_ps_1_4
{
	Pass P0
	{
		// SetState
		PixelShaderConstant[0] = (c_primary_change_color);
	    PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
	    PixelShaderConstant[4] = (c_self_illumination_color);
	    Texture[0]	= (Texture0);
	    Texture[1]	= (Texture1);
	    Texture[2]	= (Texture2);
	    Texture[3]	= (Texture3);
	    ColorOp[0]	= Disable;
	    AlphaOp[0]	= Disable;
		    
		PixelShader = asm
		{
			TEMP t0, t1, t2, t3, t4, t5, t6, t7, tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM color = {0.0, 1.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB tc0 = fragment.texcoord[0];
			ATTRIB tc1 = fragment.texcoord[1];
			ATTRIB tc2 = fragment.texcoord[2];
			ATTRIB tc3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp1, r1, mulConst.r;
			MUL r0.rgb, r0, tmp1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, tc0, texture[0], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MOV r0.rgb, r4;
			MOV r0.a, r2.a;
			MOV oC0, r0;
			#MOV oC0, color;		
		};
		//PixelShader = (PS_EnvironmentNoMaskDetailAfterReflectionBiasedMultiply_ps_1_4);
	}
}

Technique EnvironmentNoMaskDetailAfterReflectionMultiply_ps_1_4
{
	Pass P0
	{
		// SetState
		PixelShaderConstant[0] = (c_primary_change_color);
	    PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
	    PixelShaderConstant[4] = (c_self_illumination_color);
	    Texture[0]	= (Texture0);
	    Texture[1]	= (Texture1);
	    Texture[2]	= (Texture2);
	    Texture[3]	= (Texture3);
	    ColorOp[0]	= Disable;
	    AlphaOp[0]	= Disable;
		    
		PixelShader = asm
		{
			TEMP t0, t1, t2, t3, t4, t5, t6, t7, tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM color = {0.0, 1.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB tc0 = fragment.texcoord[0];
			ATTRIB tc1 = fragment.texcoord[1];
			ATTRIB tc2 = fragment.texcoord[2];
			ATTRIB tc3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL r0.rgb, r0, r1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, tc0, texture[0], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MOV r0.rgb, r4;
			MOV r0.a, r2.a;
			MOV oC0, r0;
			#MOV oC0, color;
		};
		//PixelShader = (PS_EnvironmentNoMaskDetailAfterReflectionMultiply_ps_1_4);
	}
}

Technique EnvironmentNoMaskDetailAfterReflectionBiasedAdd_ps_1_4
{
	Pass P0
	{
		// SetState
		PixelShaderConstant[0] = (c_primary_change_color);
	    PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
	    PixelShaderConstant[4] = (c_self_illumination_color);
	    Texture[0]	= (Texture0);
	    Texture[1]	= (Texture1);
	    Texture[2]	= (Texture2);
	    Texture[3]	= (Texture3);
	    ColorOp[0]	= Disable;
	    AlphaOp[0]	= Disable;
		    
		PixelShader = asm
		{
			TEMP t0, t1, t2, t3, t4, t5, t6, t7, tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM color = {0.0, 1.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB tc0 = fragment.texcoord[0];
			ATTRIB tc1 = fragment.texcoord[1];
			ATTRIB tc2 = fragment.texcoord[2];
			ATTRIB tc3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MAD tmp1, r1, mulConst.r, -const.b;
			ADD r0.rgb, r0, tmp1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, tc0, texture[0], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MOV r0.rgb, r4;
			MOV r0.a, r2.a;
			MOV oC0, r0;
			#MOV oC0, color;
		};
		//PixelShader = (PS_EnvironmentNoMaskDetailAfterReflectionBiasedAdd_ps_1_4);
	}
}

Technique EnvironmentNoMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_1_4
{
	Pass P0
	{
		// SetState
		PixelShaderConstant[0] = (c_primary_change_color);
	    PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
	    PixelShaderConstant[4] = (c_self_illumination_color);
	    Texture[0]	= (Texture0);
	    Texture[1]	= (Texture1);
	    Texture[2]	= (Texture2);
	    Texture[3]	= (Texture3);
	    ColorOp[0]	= Disable;
	    AlphaOp[0]	= Disable;
		    
		PixelShader = asm
		{
			TEMP t0, t1, t2, t3, t4, t5, t6, t7, tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM color = {0.0, 1.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB tc0 = fragment.texcoord[0];
			ATTRIB tc1 = fragment.texcoord[1];
			ATTRIB tc2 = fragment.texcoord[2];
			ATTRIB tc3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, tc0, texture[0], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MAD r5.rgb, v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL tmp1, r1, mulConst.r;
			MUL r4.rgb, r4, tmp1;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MOV r0.a, r2.a;
			MOV oC0, r0;
			#MOV oC0, color;
		};
		//PixelShader = (PS_EnvironmentNoMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_1_4);
	}
}

Technique EnvironmentNoMaskDetailBeforeReflectionMultiplyComplexFog_ps_1_4
{
	Pass P0
	{
		// SetState
		PixelShaderConstant[0] = (c_primary_change_color);
	    PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
	    PixelShaderConstant[4] = (c_self_illumination_color);
	    Texture[0]	= (Texture0);
	    Texture[1]	= (Texture1);
	    Texture[2]	= (Texture2);
	    Texture[3]	= (Texture3);
	    ColorOp[0]	= Disable;
	    AlphaOp[0]	= Disable;
		    
		PixelShader = asm
		{
			TEMP t0, t1, t2, t3, t4, t5, t6, t7, tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM color = {0.0, 1.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB tc0 = fragment.texcoord[0];
			ATTRIB tc1 = fragment.texcoord[1];
			ATTRIB tc2 = fragment.texcoord[2];
			ATTRIB tc3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, tc0, texture[0], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MAD r5.rgb, v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL r4.rgb, r4, r1;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MOV r0.a, r2.a;
			MOV oC0, r0;
			#MOV oC0, color;
		};
		//PixelShader = (PS_EnvironmentNoMaskDetailBeforeReflectionMultiplyComplexFog_ps_1_4);
	}
}

Technique EnvironmentNoMaskDetailBeforeReflectionBiasedAddComplexFog_ps_1_4
{
	Pass P0
	{
		// SetState
		PixelShaderConstant[0] = (c_primary_change_color);
	    PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
	    PixelShaderConstant[4] = (c_self_illumination_color);
	    Texture[0]	= (Texture0);
	    Texture[1]	= (Texture1);
	    Texture[2]	= (Texture2);
	    Texture[3]	= (Texture3);
	    ColorOp[0]	= Disable;
	    AlphaOp[0]	= Disable;
		    
		PixelShader = asm
		{
			TEMP t0, t1, t2, t3, t4, t5, t6, t7, tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM color = {0.0, 1.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB tc0 = fragment.texcoord[0];
			ATTRIB tc1 = fragment.texcoord[1];
			ATTRIB tc2 = fragment.texcoord[2];
			ATTRIB tc3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, tc0, texture[0], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MAD r5.rgb, v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MAD tmp1, r1, mulConst.r, -const.b;
			ADD r4.rgb, r4, tmp1;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MOV r0.a, r2.a;
			MOV oC0, r0;
			#MOV oC0, color;
		};
		//PixelShader = (PS_EnvironmentNoMaskDetailBeforeReflectionBiasedAddComplexFog_ps_1_4);
	}
}

Technique EnvironmentNoMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_1_4
{
	Pass P0
	{
		// SetState
		PixelShaderConstant[0] = (c_primary_change_color);
	    PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
	    PixelShaderConstant[4] = (c_self_illumination_color);
	    Texture[0]	= (Texture0);
	    Texture[1]	= (Texture1);
	    Texture[2]	= (Texture2);
	    Texture[3]	= (Texture3);
	    ColorOp[0]	= Disable;
	    AlphaOp[0]	= Disable;
		    
		PixelShader = asm
		{
			TEMP t0, t1, t2, t3, t4, t5, t6, t7, tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM color = {0.0, 1.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB tc0 = fragment.texcoord[0];
			ATTRIB tc1 = fragment.texcoord[1];
			ATTRIB tc2 = fragment.texcoord[2];
			ATTRIB tc3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp1, r1, mulConst.r;
			MUL r0.rgb, r0, tmp1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, tc0, texture[0], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MAD r5.rgb, v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MOV r0.a, r2.a;
			MOV oC0, r0;
			#MOV oC0, color;
		};
		//PixelShader = (PS_EnvironmentNoMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_1_4);
	}
}

Technique EnvironmentNoMaskDetailAfterReflectionMultiplyComplexFog_ps_1_4
{
	Pass P0
	{
		// SetState
		PixelShaderConstant[0] = (c_primary_change_color);
	    PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
	    PixelShaderConstant[4] = (c_self_illumination_color);
	    Texture[0]	= (Texture0);
	    Texture[1]	= (Texture1);
	    Texture[2]	= (Texture2);
	    Texture[3]	= (Texture3);
	    ColorOp[0]	= Disable;
	    AlphaOp[0]	= Disable;
		    
		PixelShader = asm
		{
			TEMP t0, t1, t2, t3, t4, t5, t6, t7, tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM color = {0.0, 1.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB tc0 = fragment.texcoord[0];
			ATTRIB tc1 = fragment.texcoord[1];
			ATTRIB tc2 = fragment.texcoord[2];
			ATTRIB tc3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL r0.rgb, r0, r1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, tc0, texture[0], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MAD r5.rgb, v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MOV r0.a, r2.a;
			MOV oC0, r0;
			#MOV oC0, color;
		};
		//PixelShader = (PS_EnvironmentNoMaskDetailAfterReflectionMultiplyComplexFog_ps_1_4);
	}
}

Technique EnvironmentNoMaskDetailAfterReflectionBiasedAddComplexFog_ps_1_4
{
	Pass P0
	{
		// SetState
		PixelShaderConstant[0] = (c_primary_change_color);
	    PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
	    PixelShaderConstant[4] = (c_self_illumination_color);
	    Texture[0]	= (Texture0);
	    Texture[1]	= (Texture1);
	    Texture[2]	= (Texture2);
	    Texture[3]	= (Texture3);
	    ColorOp[0]	= Disable;
	    AlphaOp[0]	= Disable;
		    
		PixelShader = asm
		{
			TEMP t0, t1, t2, t3, t4, t5, t6, t7, tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM color = {0.0, 1.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB tc0 = fragment.texcoord[0];
			ATTRIB tc1 = fragment.texcoord[1];
			ATTRIB tc2 = fragment.texcoord[2];
			ATTRIB tc3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MAD tmp1, r1, mulConst.r, -const.b;
			ADD r0.rgb, r0, tmp1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, tc0, texture[0], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MAD r5.rgb, v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MOV r0.a, r2.a;
			MOV oC0, r0;
			#MOV oC0, color;
		};
		//PixelShader = (PS_EnvironmentNoMaskDetailAfterReflectionBiasedAddComplexFog_ps_1_4);
	}
}

/* RAV

///////////////////////////////////////////////////////////////////////////////
// Pixel Shader 1.1 shaders
///////////////////////////////////////////////////////////////////////////////
#define SetState \
    PixelShaderConstant[0] = (c_primary_change_color); \
    PixelShaderConstant[1] = (c_fog_color_correction_0); \
    PixelShaderConstant[3] = (c_fog_color_correction_1); \
    Texture[0]	= (Texture0); \
    Texture[1]	= (Texture1); \
    Texture[2]	= (Texture2); \
    Texture[3]	= (Texture3); \
    ColorOp[0]	= Disable; \
    AlphaOp[0]	= Disable;

#define ComputeFog	lrp r1, 1-v0.a, r0, c1 \
					mad_sat r0.rgb, r1, c1.a, c3
*/
Technique EnvironmentNoMaskDetailBeforeReflectionBiasedMultiply_ps_1_1
{
	Pass P0
	{
//DAJ	SetState
		PixelShaderConstant[0] = (c_primary_change_color);
		PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);
		Texture[2]	= (Texture2);
		Texture[3]	= (Texture3);
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color.primary;
			ATTRIB v1 = fragment.color.secondary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;	# base map
			TEX t1, f1, texture[1], 2D;	# detail map
			TEX t2, f2, texture[2], 2D;	# multipurpose map
			TEX t3, f3, texture[3], CUBE;	# reflection map
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			
			TEMP oneminus;
#DAJ		MAD r0, t2.a, c0, 1-t2.a;	# primary change color
			SUB oneminus.a, one.a, t2.a;
			MAD r0, t2.a, c0, oneminus.a;
			
			MUL t3, t3, v1;				# "tinted" reflection
			MUL r0, r0, v0;				# apply primary change color to diffuse light
			MUL r0.rgb, t0, r0;			# lit texture
			MUL r0.a, t2.b, v1.a;		# reflection mask times brightness
			MAD r0, t3, r0.a, r0;		# lit texture and reflection
			
#DAJ		MUL_X2 r0.rgb, r0, t1;		# biased multiply
			MUL r0.rgb, r0, t1;
			MUL r0.rgb, r0, two;
			MOV r0.a, t2.a;				# multipurpose map alpha

#DAJ		ComputeFog
			SUB oneminus.a, one.a, v0.a;
			LRP r1, oneminus.a, r0, c1;
			MAD_SAT r0.rgb, r1, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique EnvironmentNoMaskDetailBeforeReflectionMultiply_ps_1_1
{
	Pass P0
	{
//DAJ		SetState
		PixelShaderConstant[0] = (c_primary_change_color);
		PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);
		Texture[2]	= (Texture2);
		Texture[3]	= (Texture3);
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color.primary;
			ATTRIB v1 = fragment.color.secondary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;	# base map
			TEX t1, f1, texture[1], 2D;	# detail map
			TEX t2, f2, texture[2], 2D;	# multipurpose map
			TEX t3, f3, texture[3], CUBE;	# reflection map
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			
			TEMP oneminus;
#DAJ		MAD r0, t2.a, c0, 1-t2.a;	# primary change color
			SUB oneminus.a, one.a, t2.a;
			MAD r0, t2.a, c0, oneminus.a;
			
			MUL t3, t3, v1;				# "tinted" reflection
			MUL r0, r0, v0;				# apply primary change color to diffuse light
			MUL r0.rgb, t0, r0;			# lit texture
			MUL r0.a, t2.b, v1.a;		# reflection mask times brightness
			MAD r0, t3, r0.a, r0;		# lit texture and reflection
			
			MUL r0.rgb, r0, t1;			# multiply
			MOV r0.a, t2.a;				# multipurpose map alpha

#DAJ		ComputeFog
			SUB oneminus.a, one.a, v0.a;
			LRP r1, oneminus.a, r0, c1;
			MAD_SAT r0.rgb, r1, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique EnvironmentNoMaskDetailBeforeReflectionBiasedAdd_ps_1_1
{
	Pass P0
	{
//DAJ		SetState
		PixelShaderConstant[0] = (c_primary_change_color);
		PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);
		Texture[2]	= (Texture2);
		Texture[3]	= (Texture3);
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader			= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color.primary;
			ATTRIB v1 = fragment.color.secondary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;	# base map
			TEX t1, f1, texture[1], 2D;	# detail map
			TEX t2, f2, texture[2], 2D;	# multipurpose map
			TEX t3, f3, texture[3], CUBE;	# reflection map
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			
			TEMP oneminus, t1_bx2;
#DAJ		MAD r0, t2.a, c0, 1-t2.a;	# primary change color
			SUB oneminus.a, one.a, t2.a;
			MAD r0, t2.a, c0, oneminus.a;
			
			MUL t3, t3, v1;				# "tinted" reflection
			MUL r0, r0, v0;				# apply primary change color to diffuse light
			MUL r0.rgb, t0, r0;			# lit texture
			MUL r0.a, t2.b, v1.a;		# reflection mask times brightness
			MAD r0, t3, r0.a, r0;		# lit texture and reflection
			
#DAJ		MUL_X2 r0.rgb, r0, t1_bx2;		# biased multiply
			SUB t1_bx2, t1, half;			
			MUL t1_bx2, t1_bx2, two;
			MUL r0.rgb, r0, t1_bx2;
			MUL r0.rgb, r0, two;
			MOV r0.a, t2.a;				# multipurpose map alpha

#DAJ		ComputeFog
			SUB oneminus.a, one.a, v0.a;
			LRP r1, oneminus.a, r0, c1;
			MAD_SAT r0.rgb, r1, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique EnvironmentNoMaskDetailAfterReflectionBiasedMultiply_ps_1_1
{
	Pass P0
	{
//DAJ		SetState
		PixelShaderConstant[0] = (c_primary_change_color);
		PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);
		Texture[2]	= (Texture2);
		Texture[3]	= (Texture3);
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader			= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color.primary;
			ATTRIB v1 = fragment.color.secondary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;	# base map
			TEX t1, f1, texture[1], 2D;	# detail map
			TEX t2, f2, texture[2], 2D;	# multipurpose map
			TEX t3, f3, texture[3], CUBE;	# reflection map
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			
			TEMP oneminus, t1_bx2;
#DAJ		MAD r0, t2.a, c0, 1-t2.a;	# primary change color
			SUB oneminus.a, one.a, t2.a;
			MAD r0, t2.a, c0, oneminus.a;
			
			MUL t3, t3, v1;				# "tinted" reflection
			MUL r0, r0, v0;				# apply primary change color to diffuse light

#DAJ		MUL_X2 r1, t0, t1;			# biased multiply
			MUL r1, t0, t1;
			MUL r1, r1, two;
			
			MUL r0.rgb, r1, r0;			# lit texture
			MUL r0.a, t2.b, v1.a;		# reflection mask times brightness
			MAD r0.rgb, t3, r0.a, r0;	# lit texture and reflection
			MOV r0.a, t2.a;			# multipurpose map alpha

#DAJ		ComputeFog
			SUB oneminus.a, one.a, v0.a;
			LRP r1, oneminus.a, r0, c1;
			MAD_SAT r0.rgb, r1, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique EnvironmentNoMaskDetailAfterReflectionMultiply_ps_1_1
{
	Pass P0
	{
//DAJ		SetState
		PixelShaderConstant[0] = (c_primary_change_color);
		PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);
		Texture[2]	= (Texture2);
		Texture[3]	= (Texture3);
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader			= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color.primary;
			ATTRIB v1 = fragment.color.secondary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;	# base map
			TEX t1, f1, texture[1], 2D;	# detail map
			TEX t2, f2, texture[2], 2D;	# multipurpose map
			TEX t3, f3, texture[3], CUBE;	# reflection map
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			
			TEMP oneminus;
#DAJ		MAD r0, t2.a, c0, 1-t2.a;	# primary change color
			SUB oneminus.a, one.a, t2.a;
			MAD r0, t2.a, c0, oneminus.a;
			
			MUL t3, t3, v1;				# "tinted" reflection
			MUL r0, r0, v0;				# apply primary change color to diffuse light
			MUL r1, t0, t1;				# multiply
			MUL r0.rgb, r1, r0;			# lit texture
			MUL r0.a, t2.b, v1.a;		# reflection mask times brightness
			MAD r0.rgb, t3, r0.a, r0;	# lit texture and reflection
			MOV r0.a, t2.a;			# multipurpose map alpha

#DAJ		ComputeFog
			SUB oneminus.a, one.a, v0.a;
			LRP r1, oneminus.a, r0, c1;
			MAD_SAT r0.rgb, r1, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique EnvironmentNoMaskDetailAfterReflectionBiasedAdd_ps_1_1
{
	Pass P0
	{
//DAJ		SetState
		PixelShaderConstant[0] = (c_primary_change_color);
		PixelShaderConstant[1] = (c_fog_color_correction_0);
	    PixelShaderConstant[2] = (c_fog_color_correction_E);
	    PixelShaderConstant[3] = (c_fog_color_correction_1);
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);
		Texture[2]	= (Texture2);
		Texture[3]	= (Texture3);
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader			= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color.primary;
			ATTRIB v1 = fragment.color.secondary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;	# base map
			TEX t1, f1, texture[1], 2D;	# detail map
			TEX t2, f2, texture[2], 2D;	# multipurpose map
			TEX t3, f3, texture[3], CUBE;	# reflection map
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			
			TEMP oneminus, t1_bx2;
#DAJ		MAD r0, t2.a, c0, 1-t2.a;	# primary change color
			SUB oneminus.a, one.a, t2.a;
			MAD r0, t2.a, c0, oneminus.a;
			
			MUL t3, t3, v1;				# "tinted" reflection
			MUL r0, r0, v0;				# apply primary change color to diffuse light
			SUB t1_bx2, t1, half;			
			MUL t1_bx2, t1_bx2, two;
			MUL r1, t0, t1_bx2;			# biased add
			MUL r0.rgb, r1, r0;			# lit texture
			MUL r0.a, t2.b, v1.a;		# reflection mask times brightness
			MAD r0.rgb, t3, r0.a, r0;	# lit texture and reflection
			MOV r0.a, t2.a;			# multipurpose map alpha

#DAJ		ComputeFog
			SUB oneminus.a, one.a, v0.a;
			LRP r1, oneminus.a, r0, c1;
			MAD_SAT r0.rgb, r1, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}
/*
///////////////////////////////////////////////////////////////////////////////
// Fixed Function shaders
///////////////////////////////////////////////////////////////////////////////
#define FixedFunctionDiffuseMacro		Texture[0]			= (Texture0); \
										Texture[1]			= (Texture1); \
										ColorOp[0]			= Modulate;	\
										ColorArg1[0]		= Texture;	\
										ColorArg2[0]		= Diffuse;	\
										AlphaOp[0]			= SelectArg1;	\
										AlphaArg1[0]		= Diffuse;	\
										ColorOp[1]			= SelectArg1;	\
										ColorArg1[1]		= Current;	\
										AlphaOp[1]			= SelectArg1;	\
										AlphaArg1[1]		= Texture;	\
										ColorOp[2]			= Disable;	\
										AlphaOp[2]			= Disable;	\
										PixelShader			= Null;
*/
Technique EnvironmentNoMaskDetailBeforeReflectionBiasedMultiply_ps_0_0
{
	Pass P0
	{
		Texture[0]			= (Texture0);
		Texture[1]			= (Texture1);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Diffuse;
		ColorOp[1]			= SelectArg1;
		ColorArg1[1]		= Current;
		AlphaOp[1]			= SelectArg1;
		AlphaArg1[1]		= Texture;
		ColorOp[2]			= Disable;
		AlphaOp[2]			= Disable;
		PixelShader			= Null;

	}
}

Technique EnvironmentNoMaskDetailBeforeReflectionMultiply_ps_0_0
{
	Pass P0
	{
		Texture[0]			= (Texture0);
		Texture[1]			= (Texture1);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Diffuse;
		ColorOp[1]			= SelectArg1;
		ColorArg1[1]		= Current;
		AlphaOp[1]			= SelectArg1;
		AlphaArg1[1]		= Texture;
		ColorOp[2]			= Disable;
		AlphaOp[2]			= Disable;
		PixelShader			= Null;

	}
}

Technique EnvironmentNoMaskDetailBeforeReflectionBiasedAdd_ps_0_0
{
	Pass P0
	{
		Texture[0]			= (Texture0);
		Texture[1]			= (Texture1);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Diffuse;
		ColorOp[1]			= SelectArg1;
		ColorArg1[1]		= Current;
		AlphaOp[1]			= SelectArg1;
		AlphaArg1[1]		= Texture;
		ColorOp[2]			= Disable;
		AlphaOp[2]			= Disable;
		PixelShader			= Null;

	}
}

Technique EnvironmentNoMaskDetailAfterReflectionBiasedMultiply_ps_0_0
{
	Pass P0
	{
		Texture[0]			= (Texture0);
		Texture[1]			= (Texture1);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Diffuse;
		ColorOp[1]			= SelectArg1;
		ColorArg1[1]		= Current;
		AlphaOp[1]			= SelectArg1;
		AlphaArg1[1]		= Texture;
		ColorOp[2]			= Disable;
		AlphaOp[2]			= Disable;
		PixelShader			= Null;

	}
}

Technique EnvironmentNoMaskDetailAfterReflectionMultiply_ps_0_0
{
	Pass P0
	{
		Texture[0]			= (Texture0);
		Texture[1]			= (Texture1);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Diffuse;
		ColorOp[1]			= SelectArg1;
		ColorArg1[1]		= Current;
		AlphaOp[1]			= SelectArg1;
		AlphaArg1[1]		= Texture;
		ColorOp[2]			= Disable;
		AlphaOp[2]			= Disable;
		PixelShader			= Null;

	}
}

Technique EnvironmentNoMaskDetailAfterReflectionBiasedAdd_ps_0_0
{
	Pass P0
	{
		Texture[0]			= (Texture0);
		Texture[1]			= (Texture1);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Diffuse;
		ColorOp[1]			= SelectArg1;
		ColorArg1[1]		= Current;
		AlphaOp[1]			= SelectArg1;
		AlphaArg1[1]		= Texture;
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
