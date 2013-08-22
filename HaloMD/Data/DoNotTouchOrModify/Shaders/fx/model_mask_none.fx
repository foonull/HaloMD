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
half4 ModelNoMask(
    half4 Diff : COLOR0,
    half4 Spec : COLOR1,
    half2 Tex0  : TEXCOORD0,
    half2 Tex1  : TEXCOORD1,
    half2 Tex2  : TEXCOORD2,
    half4 Tex3  : TEXCOORD3,
    uniform const int nDetailFunction,
    uniform const bool bDetailBeforeReflection,
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
	D0.rgb	= D0 + (T2.g*c_self_illumination_color);
	
	// combiner 2
	R1.a	= T2.b*D1.a;
	R0	= (T2.a*c_primary_change_color) + (1-T2.a);
	
	// combiner 4
	T3.rgb	= T3*D1;
	D0.rgb	= D0*R0;
	
	if(bDetailBeforeReflection)
	{
		// combiner 6
		R0.rgb = (T0*D0) + (T3*R1.a);
		
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
		R0.rgb = (T0*D0) + (T3*R1.a);
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

	SRCALPHA = T0.a * c_primary_change_color.a;

	return half4( SRCCOLOR, SRCALPHA );
}

PixelShader PS_NoMaskDetailBeforeReflectionBiasedMultiply_ps_2_0	= compile PS_2_0_TARGET ModelNoMask( detail_function_biased_multiply, true, false, false );
PixelShader PS_NoMaskDetailBeforeReflectionMultiply_ps_2_0			= compile PS_2_0_TARGET ModelNoMask( detail_function_multiply, true, false, false );
PixelShader PS_NoMaskDetailBeforeReflectionBiasedAdd_ps_2_0			= compile PS_2_0_TARGET ModelNoMask( detail_function_biased_add, true, false, false );
PixelShader PS_NoMaskDetailAfterReflectionBiasedMultiply_ps_2_0		= compile PS_2_0_TARGET ModelNoMask( detail_function_biased_multiply, false, false, false );
PixelShader PS_NoMaskDetailAfterReflectionMultiply_ps_2_0			= compile PS_2_0_TARGET ModelNoMask( detail_function_multiply, false, false, false );
PixelShader PS_NoMaskDetailAfterReflectionBiasedAdd_ps_2_0			= compile PS_2_0_TARGET ModelNoMask( detail_function_biased_add, false, false, false );

PixelShader PS_NoMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_2_0	= compile PS_2_0_TARGET ModelNoMask( detail_function_biased_multiply, true, false, true );
PixelShader PS_NoMaskDetailBeforeReflectionMultiplyComplexFog_ps_2_0		= compile PS_2_0_TARGET ModelNoMask( detail_function_multiply, true, false, true );
PixelShader PS_NoMaskDetailBeforeReflectionBiasedAddComplexFog_ps_2_0		= compile PS_2_0_TARGET ModelNoMask( detail_function_biased_add, true, false, true );
PixelShader PS_NoMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_2_0	= compile PS_2_0_TARGET ModelNoMask( detail_function_biased_multiply, false, false, true );
PixelShader PS_NoMaskDetailAfterReflectionMultiplyComplexFog_ps_2_0			= compile PS_2_0_TARGET ModelNoMask( detail_function_multiply, false, false, true );
PixelShader PS_NoMaskDetailAfterReflectionBiasedAddComplexFog_ps_2_0		= compile PS_2_0_TARGET ModelNoMask( detail_function_biased_add, false, false, true );

Technique NoMaskDetailBeforeReflectionBiasedMultiply_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_NoMaskDetailBeforeReflectionBiasedMultiply_ps_2_0);
	}
}

Technique NoMaskDetailBeforeReflectionMultiply_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_NoMaskDetailBeforeReflectionMultiply_ps_2_0);
	}
}

Technique NoMaskDetailBeforeReflectionBiasedAdd_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_NoMaskDetailBeforeReflectionBiasedAdd_ps_2_0);
	}
}

Technique NoMaskDetailAfterReflectionBiasedMultiply_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_NoMaskDetailAfterReflectionBiasedMultiply_ps_2_0);
	}
}

Technique NoMaskDetailAfterReflectionMultiply_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_NoMaskDetailAfterReflectionMultiply_ps_2_0);
	}
}

Technique NoMaskDetailAfterReflectionBiasedAdd_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_NoMaskDetailAfterReflectionBiasedAdd_ps_2_0);
	}
}

Technique NoMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_NoMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_2_0);
	}
}

Technique NoMaskDetailBeforeReflectionMultiplyComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_NoMaskDetailBeforeReflectionMultiplyComplexFog_ps_2_0);
	}
}

Technique NoMaskDetailBeforeReflectionBiasedAddComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_NoMaskDetailBeforeReflectionBiasedAddComplexFog_ps_2_0);
	}
}

Technique NoMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_NoMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_2_0);
	}
}

Technique NoMaskDetailAfterReflectionMultiplyComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_NoMaskDetailAfterReflectionMultiplyComplexFog_ps_2_0);
	}
}

Technique NoMaskDetailAfterReflectionBiasedAddComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_NoMaskDetailAfterReflectionBiasedAddComplexFog_ps_2_0);
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
    mul R0.rgb, R0, T0

#define SecondPhaseComplexFogBegin \
    phase \
 \
    texld T0, t0 \
    texld T1, t1 \
    texld T2, t2 \
    texld T3, t3 \
 \
    mul T3.rgb, T3, D1 \
    mad R0.rgb, R0, D0, R1 \
    mad R1.rgb, -D0.a, c_fog_color_correction_E, c_fog_color_correction_1 \
    +mul R1.a, T2.b, D1.a \
    mad R0.rgb, T3, R1.a, R0

#define SecondPhaseComplexFogEnd \
    mul R0.rgb, R0, c_fog_color_correction_0.a \
    lrp R0.rgb, D0.a, c_fog_color_correction_0, R0 \
    add r0.rgb, R0, R1 \
    +mul r0.a, T0.a, c0.a

#define SecondPhaseBegin \
    phase \
 \
    texld T0, t0 \
    texld T1, t1 \
    texld T2, t2 \
    texld T3, t3 \
 \
    mul T3.rgb, T3, D1 \
    mul R0.rgb, R0, D0 \
    +mul R0.a, T2.b, D1.a \
    mad R0.rgb, T3, R0.a, R0

#define SecondPhaseEnd \
    mov r0.rgb, R0 \
    +mul r0.a, T0.a, c0.a

#define BiasedMultiply(R) \
    mul R.rgb, R, T1_x2

#define Multiply(R) \
    mul R.rgb, R, T1

#define BiasedAdd(R) \
    add R.rgb, R, T1_bx2

PixelShader PS_NoMaskDetailBeforeReflectionBiasedMultiply_ps_1_4 = asm
{
    FirstPhaseBegin
    FirstPhaseEnd
    SecondPhaseBegin
    BiasedMultiply(R0)
    SecondPhaseEnd
};

PixelShader PS_NoMaskDetailBeforeReflectionMultiply_ps_1_4 = asm
{
    FirstPhaseBegin
    FirstPhaseEnd
    SecondPhaseBegin
    Multiply(R0)
    SecondPhaseEnd
};

PixelShader PS_NoMaskDetailBeforeReflectionBiasedAdd_ps_1_4 = asm
{
    FirstPhaseBegin
    FirstPhaseEnd
    SecondPhaseBegin
    BiasedAdd(R0)
    SecondPhaseEnd
};

PixelShader PS_NoMaskDetailAfterReflectionBiasedMultiply_ps_1_4 = asm
{
    FirstPhaseBegin
    BiasedMultiply(T0)
    FirstPhaseEnd
    SecondPhaseBegin
    SecondPhaseEnd
};

PixelShader PS_NoMaskDetailAfterReflectionMultiply_ps_1_4 = asm
{
    FirstPhaseBegin
    Multiply(T0)
    FirstPhaseEnd
    SecondPhaseBegin
    SecondPhaseEnd
};

PixelShader PS_NoMaskDetailAfterReflectionBiasedAdd_ps_1_4 = asm
{
    FirstPhaseBegin
    BiasedAdd(T0)
    FirstPhaseEnd
    SecondPhaseBegin
    SecondPhaseEnd
};

PixelShader PS_NoMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    BiasedMultiply(R0)
    SecondPhaseComplexFogEnd
};

PixelShader PS_NoMaskDetailBeforeReflectionMultiplyComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    Multiply(R0)
    SecondPhaseComplexFogEnd
};

PixelShader PS_NoMaskDetailBeforeReflectionBiasedAddComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    BiasedAdd(R0)
    SecondPhaseComplexFogEnd
};

PixelShader PS_NoMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    BiasedMultiply(T0)
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    SecondPhaseComplexFogEnd
};

PixelShader PS_NoMaskDetailAfterReflectionMultiplyComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    Multiply(T0)
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    SecondPhaseComplexFogEnd
};

PixelShader PS_NoMaskDetailAfterReflectionBiasedAddComplexFog_ps_1_4 = asm
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

// 1
Technique NoMaskDetailBeforeReflectionBiasedMultiply_ps_1_4
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
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MUL r4.rgb, r4, v0;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MUL tmp1, r1, mulConst.r;
			MUL r4.rgb, r4, tmp1;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, color;
	    };
        //PixelShader = (PS_NoMaskDetailBeforeReflectionBiasedMultiply_ps_1_4);
	}
}

// 2
Technique NoMaskDetailBeforeReflectionMultiply_ps_1_4
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
			PARAM color = {1.0, 1.0, 0.0, 1.0};
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
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MUL r4.rgb, r4, v0;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MUL r4.rgb, r4, r1;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, color;
	    };
        //PixelShader = (PS_NoMaskDetailBeforeReflectionMultiply_ps_1_4);
	}
}

// 3
Technique NoMaskDetailBeforeReflectionBiasedAdd_ps_1_4
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
			PARAM color = {1.0, 0.0, 1.0, 1.0};
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
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MUL r4.rgb, r4, v0;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MAD tmp1, r1, mulConst.r, -const.b;
			ADD r4.rgb, r4, tmp1;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, color;
	    };
        //PixelShader = (PS_NoMaskDetailBeforeReflectionBiasedAdd_ps_1_4);
	}
}

// 4
Technique NoMaskDetailAfterReflectionBiasedMultiply_ps_1_4
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
			PARAM color = {0.0, 0.0, 1.0, 1.0};
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
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MUL r4.rgb, r4, v0;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, color;
	    };
        //PixelShader = (PS_NoMaskDetailAfterReflectionBiasedMultiply_ps_1_4);
	}
}

// 5
Technique NoMaskDetailAfterReflectionMultiply_ps_1_4
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
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MUL r4.rgb, r4, v0;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, color;
	    };
        //PixelShader = (PS_NoMaskDetailAfterReflectionMultiply_ps_1_4);
	}
}

// 6
Technique NoMaskDetailAfterReflectionBiasedAdd_ps_1_4
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
			PARAM color = {1.0, 0.0, 0.0, 1.0};
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
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MUL r4.rgb, r4, v0;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, color;
	    };
        //PixelShader = (PS_NoMaskDetailAfterReflectionBiasedAdd_ps_1_4);
	}
}

// 7
Technique NoMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_1_4
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
			PARAM color = {1.0, 0.0, 0.0, 1.0};
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
			#TEX r0, tc0, texture[0], 2D;
			#TEX r1, tc1, texture[1], 2D;
			#TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			#MAD r4.rgb, r4, v0, r5;
			MUL r4.rgb, r4, v0;
			MAD r5.rgb, -v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL tmp1, r1, mulConst.r;
			MUL r4.rgb, r4, tmp1;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, color;
	    };
        //PixelShader = (PS_NoMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_1_4);
	}
}

// 8
Technique NoMaskDetailBeforeReflectionMultiplyComplexFog_ps_1_4
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
			PARAM color = {1.0, 0.0, 1.0, 1.0};
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
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, r4, v0, r5;
			MAD r5.rgb, -v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL r4.rgb, r4, r1;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, color;
	    };
        //PixelShader = (PS_NoMaskDetailBeforeReflectionMultiplyComplexFog_ps_1_4);
	}
}

// 9
Technique NoMaskDetailBeforeReflectionBiasedAddComplexFog_ps_1_4
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
			PARAM color = {1.0, 1.0, 0.0, 1.0};
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
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, r4, v0, r5;
			MAD r5.rgb, -v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MAD tmp1, r1, mulConst.r, -const.b;
			ADD r4.rgb, r4, tmp1;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, color;
	    };
        //PixelShader = (PS_NoMaskDetailBeforeReflectionBiasedAddComplexFog_ps_1_4);
	}
}

// 10
Technique NoMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_1_4
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
			PARAM color = {0.0, 0.0, 1.0, 1.0};
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
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, r4, v0, r5;
			MAD r5.rgb, -v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, color;
	    };
        //PixelShader = (PS_NoMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_1_4);
	}
}

// 11
Technique NoMaskDetailAfterReflectionMultiplyComplexFog_ps_1_4
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
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, r4, v0, r5;
			MAD r5.rgb, -v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, color;
	    };
        //PixelShader = (PS_NoMaskDetailAfterReflectionMultiplyComplexFog_ps_1_4);
	}
}

// 12
Technique NoMaskDetailAfterReflectionBiasedAddComplexFog_ps_1_4
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
			PARAM color = {1.0, 0.0, 0.0, 1.0};
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
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], 2D;
			TEX r3, tc3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, r4, v0, r5;
			MAD r5.rgb, -v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, color;
	    };
        //PixelShader = (PS_NoMaskDetailAfterReflectionBiasedAddComplexFog_ps_1_4);
	}
}

/* RAV

///////////////////////////////////////////////////////////////////////////////
// Pixel Shader 1.1 shaders
///////////////////////////////////////////////////////////////////////////////
#define ComputeChangeColorMacroWithIllumination			dp3_sat r1, t2, c6 \
														mad r0.rgb, t2.a, c0, 1-t2.a \
														+ mov r0.a, r1.b \
														mad r1, r0.a, c4, v0
													
#define ComputeChangeColorMacro							mad r0.rgb, t2.a, c0, 1-t2.a \
														+ mov r0.a, t2.a

#define ComputeTintedReflectionMacro					mul t3, t3, v1 \

#define ComputeDetailBeforeReflectionBiasedMultiply(reg)	mul r0.rgb, r0, reg	\
															mul r0.rgb, t0, r0 \
															+ mul r0.a, t2.b, v1.a \
															mad r0.rgb, t3, r0.a, r0 \
															mul_x2 r0.rgb, r0, t1 \
															+ mul r0.a, t0.a, c0.a
													
#define ComputeDetailBeforeReflectionMultiply(reg)			mul r0.rgb, r0, reg	\
															mul r0.rgb, t0, r0 \
															+ mul r0.a, t2.b, v1.a \
															mad r0.rgb, t3, r0.a, r0 \
															mul r0.rgb, r0, t1 \
															+ mul r0.a, t0.a, c0.a

#define ComputeDetailBeforeReflectionBiasedAdd(reg)			mul r0.rgb, r0, reg	\
															mul r0.rgb, t0, r0 \
															+ mul r0.a, t2.b, v1.a \
															mad r0.rgb, t3, r0.a, r0 \
															mul r0.rgb, r0, t1_bx2 \
															+ mul r0.a, t0.a, c0.a

#define ComputeDetailAfterReflectionBiasedMultiply(reg)		mul r0.rgb, r0, reg	\
															mul_x2 r1.rgb, t0, t1 \
															mul r0.rgb, r1, r0 \
															+ mul r0.a, t2.b, v1.a \
															mad r0.rgb, t3, r0.a, r0 \
															+ mul r0.a, t0.a, c0.a

#define ComputeDetailAfterReflectionMultiply(reg)			mul r0.rgb, r0, reg	\
															mul r1.rgb, t0, t1 \
															mul r0.rgb, r1, r0 \
															+ mul r0.a, t2.b, v1.a \
															mad r0.rgb, t3, r0.a, r0 \
															+ mul r0.a, t0.a, c0.a

#define ComputeDetailAfterReflectionBiasedAdd(reg)			mul r0.rgb, r0, reg	\
															mul r1.rgb, t0, t1_bx2 \
															mul r0.rgb, r1, r0 \
															+ mul r0.a, t2.b, v1.a \
															mad r0.rgb, t3, r0.a, r0 \
															+ mul r0.a, t0.a, c0.a

#define ComputeFog											lrp r1, 1-v0.a, r0, c1 \
															mad_sat r0.rgb, r1, c1.a, c3

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

PixelShader	PS_NoMaskDetailBeforeReflectionBiasedMultiply_ps_1_1 = asm
{
	ps_1_1

	def c6, 0.0, 1.0, 0.0, 0.0
	def c7, 0.5, 0.5, 0.5, 0.5

	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map

	ComputeChangeColorMacro
	ComputeTintedReflectionMacro
	ComputeDetailBeforeReflectionBiasedMultiply(v0)
	ComputeFog
};
		
PixelShader PS_NoMaskDetailBeforeReflectionMultiply_ps_1_1 = asm
{
	ps_1_1

	def c6, 0.0, 1.0, 0.0, 0.0
	def c7, 1.0, 1.0, 1.0, 1.0

	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacro
	ComputeTintedReflectionMacro
	ComputeDetailBeforeReflectionMultiply(v0)
	ComputeFog
};

PixelShader PS_NoMaskDetailBeforeReflectionBiasedAdd_ps_1_1 = asm
{
	ps_1_1

	def c6, 0.0, 1.0, 0.0, 0.0
	def c7, 0.5, 0.5, 0.5, 0.5
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map

	ComputeChangeColorMacro
	ComputeTintedReflectionMacro
	ComputeDetailBeforeReflectionBiasedAdd(v0)
	ComputeFog
};

PixelShader PS_NoMaskDetailAfterReflectionBiasedMultiply_ps_1_1 = asm
{
	ps_1_1

	def c6, 0.0, 1.0, 0.0, 0.0
	def c7, 0.5, 0.5, 0.5, 0.5
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacro
	ComputeTintedReflectionMacro
	ComputeDetailAfterReflectionBiasedMultiply(v0)
	ComputeFog
};

PixelShader PS_NoMaskDetailAfterReflectionMultiply_ps_1_1 = asm
{
	ps_1_1

	def c6, 0.0, 1.0, 0.0, 0.0
	def c7, 1.0, 1.0, 1.0, 1.0
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacro
	ComputeTintedReflectionMacro
	ComputeDetailAfterReflectionMultiply(v0)
	ComputeFog
};

PixelShader PS_NoMaskDetailAfterReflectionBiasedAdd_ps_1_1 = asm
{
	ps_1_1

	def c6, 0.0, 1.0, 0.0, 0.0
	def c7, 0.5, 0.5, 0.5, 0.5
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacro
	ComputeTintedReflectionMacro
	ComputeDetailAfterReflectionBiasedAdd(v0)
	ComputeFog
};

PixelShader	PS_NoMaskDetailBeforeReflectionBiasedMultiplySelfIllumination_ps_1_1 = asm
{
	ps_1_1

	def c6, 0.0, 1.0, 0.0, 0.0
	def c7, 0.5, 0.5, 0.5, 0.5

	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map

	ComputeChangeColorMacroWithIllumination
	ComputeTintedReflectionMacro
	ComputeDetailBeforeReflectionBiasedMultiply(r1)
};
		
PixelShader PS_NoMaskDetailBeforeReflectionMultiplySelfIllumination_ps_1_1 = asm
{
	ps_1_1

	def c6, 0.0, 1.0, 0.0, 0.0
	def c7, 1.0, 1.0, 1.0, 1.0

	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacroWithIllumination
	ComputeTintedReflectionMacro
	ComputeDetailBeforeReflectionMultiply(r1)
};

PixelShader PS_NoMaskDetailBeforeReflectionBiasedAddSelfIllumination_ps_1_1 = asm
{
	ps_1_1

	def c6, 0.0, 1.0, 0.0, 0.0
	def c7, 0.5, 0.5, 0.5, 0.5
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map

	ComputeChangeColorMacroWithIllumination
	ComputeTintedReflectionMacro
	ComputeDetailBeforeReflectionBiasedAdd(r1)
};

PixelShader PS_NoMaskDetailAfterReflectionBiasedMultiplySelfIllumination_ps_1_1 = asm
{
	ps_1_1

	def c6, 0.0, 1.0, 0.0, 0.0
	def c7, 0.5, 0.5, 0.5, 0.5
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacroWithIllumination
	ComputeTintedReflectionMacro
	ComputeDetailAfterReflectionBiasedMultiply(r1)
};

PixelShader PS_NoMaskDetailAfterReflectionMultiplySelfIllumination_ps_1_1 = asm
{
	ps_1_1

	def c6, 0.0, 1.0, 0.0, 0.0
	def c7, 1.0, 1.0, 1.0, 1.0
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacroWithIllumination
	ComputeTintedReflectionMacro
	ComputeDetailAfterReflectionMultiply(r1)
};

PixelShader PS_NoMaskDetailAfterReflectionBiasedAddSelfIllumination_ps_1_1 = asm
{
	ps_1_1

	def c6, 0.0, 1.0, 0.0, 0.0
	def c7, 0.5, 0.5, 0.5, 0.5
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacroWithIllumination
	ComputeTintedReflectionMacro
	ComputeDetailAfterReflectionBiasedAdd(r1)
};
*/
Technique NoMaskDetailBeforeReflectionBiasedMultiply_ps_1_1
{
	Pass P0
	{
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
		
//		PixelShader	= (PS_NoMaskDetailBeforeReflectionBiasedMultiply_ps_1_1);
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
			PARAM c6 = { 0.0, 1.0, 0.0, 1.0	};
			PARAM c7 = { 0.5, 0.5, 0.5, 0.5	};

			TEMP oneminus, r1_bx2;

		# ComputeChangeColorMacro						
			SUB oneminus.a, one.a, t2.a;					
			MAD r0.rgb, t2.a, c0, oneminus.a;
			MOV r0.a, t2.a;

		# ComputeTintedReflectionMacro					
			MUL t3, t3, v1;

		# ComputeDetailBeforeReflectionBiasedMultiply_v0
			MUL r0.rgb, r0, v0;
			MUL r0.rgb, t0, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
#DAJ		MUL_X2 r0.rgb, r0, t1;
			MUL r0.rgb, r0, t1;
			MUL r0.rgb, r0, two;
			MUL r0.a, t0.a, c0.a;

		# ComputeFog
			SUB oneminus.a, one.a, v0.a;
			LRP r1, oneminus.a, r0, c1;
			MAD_SAT r0.rgb, r1, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique NoMaskDetailBeforeReflectionMultiply_ps_1_1
{
	Pass P0
	{
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
		
//		PixelShader	= (PS_NoMaskDetailBeforeReflectionMultiply_ps_1_1);
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
			PARAM c6 = { 0.0, 1.0, 0.0, 1.0	};
			PARAM c7 = { 1.0, 1.0, 1.0, 1.0	};

			TEMP oneminus, r1_bx2;
			
		# ComputeChangeColorMacro						
			SUB oneminus.a, one.a, t2.a;					
			MAD r0.rgb, t2.a, c0, oneminus.a;
			MOV r0.a, t2.a;

		# ComputeTintedReflectionMacro					
			MUL t3, t3, v1;

		# ComputeDetailBeforeReflectionMultiply_v0	
			MUL r0.rgb, r0, v0;
			MUL r0.rgb, t0, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			MUL r0.rgb, r0, t1;
			MUL r0.a, t0.a, c0.a;

		# ComputeFog
			SUB oneminus.a, one.a, v0.a;
			LRP r1, oneminus.a, r0, c1;
			MAD_SAT r0.rgb, r1, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique NoMaskDetailBeforeReflectionBiasedAdd_ps_1_1
{
	Pass P0
	{
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
		
//		PixelShader	= (PS_NoMaskDetailBeforeReflectionBiasedAdd_ps_1_1);
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
			PARAM c6 = { 0.0, 1.0, 0.0, 1.0	};
			PARAM c7 = { 0.5, 0.5, 0.5, 0.5	};

			TEMP oneminus, t1_bx2;

		# ComputeChangeColorMacro						
			SUB oneminus.a, one.a, t2.a;					
			MAD r0.rgb, t2.a, c0, oneminus.a;
			MOV r0.a, t2.a;

		# ComputeTintedReflectionMacro					
			MUL t3, t3, v1;

		# ComputeDetailBeforeReflectionBiasedAdd_v0	
			MUL r0.rgb, r0, v0;
			MUL r0.rgb, t0, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			SUB t1_bx2, t1, half;			
			MUL t1_bx2, t1_bx2, two;
			MUL r0.rgb, r0, t1_bx2;
			MUL r0.a, t0.a, c0.a;

		# ComputeFog
			SUB oneminus.a, one.a, v0.a;
			LRP r1, oneminus.a, r0, c1;
			MAD_SAT r0.rgb, r1, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique NoMaskDetailAfterReflectionBiasedMultiply_ps_1_1
{
	Pass P0
	{
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

//		PixelShader	= (PS_NoMaskDetailAfterReflectionBiasedMultiply_ps_1_1);
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
			PARAM c6 = { 0.0, 1.0, 0.0, 1.0	};
			PARAM c7 = { 0.5, 0.5, 0.5, 0.5	};

			TEMP oneminus, r1_bx2;
			
		# ComputeChangeColorMacro						
			SUB oneminus.a, one.a, t2.a;					
			MAD r0.rgb, t2.a, c0, oneminus.a;
			MOV r0.a, t2.a;

		# ComputeTintedReflectionMacro					
			MUL t3, t3, v1;

		# ComputeDetailAfterReflectionBiasedMultiply_v0
			MUL r0.rgb, r0, v0;
#DAJ		MUL_X2 r1.rgb, t0, t1;
			MUL r1.rgb, t0, t1;
			MUL r1.rgb, r1, two;
			MUL r0.rgb, r1, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			MUL r0.a, t0.a, c0.a;

		# ComputeFog
			SUB oneminus.a, one.a, v0.a;
			LRP r1, oneminus.a, r0, c1;
			MAD_SAT r0.rgb, r1, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique NoMaskDetailAfterReflectionMultiply_ps_1_1
{
	Pass P0
	{
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
		
//		PixelShader	= (PS_NoMaskDetailAfterReflectionMultiply_ps_1_1);
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
			PARAM c6 = { 0.0, 1.0, 0.0, 1.0	};
			PARAM c7 = { 1.0, 1.0, 1.0, 1.0	};

			TEMP oneminus, r1_bx2;
			
		# ComputeChangeColorMacro						
			SUB oneminus.a, one.a, t2.a;					
			MAD r0.rgb, t2.a, c0, oneminus.a;
			MOV r0.a, t2.a;

		# ComputeTintedReflectionMacro					
			MUL t3, t3, v1;

		# ComputeDetailAfterReflectionMultiply_v0
			MUL r0.rgb, r0, v0;
			MUL r1.rgb, t0, t1;
			MUL r0.rgb, r1, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			MUL r0.a, t0.a, c0.a;

		# ComputeFog
			SUB oneminus.a, one.a, v0.a;
			LRP r1, oneminus.a, r0, c1;
			MAD_SAT r0.rgb, r1, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique NoMaskDetailAfterReflectionBiasedAdd_ps_1_1
{
	Pass P0
	{
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
		
//		PixelShader	= (PS_NoMaskDetailAfterReflectionBiasedAdd_ps_1_1);
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
			PARAM c6 = { 0.0, 1.0, 0.0, 1.0	};
			PARAM c7 = { 0.5, 0.5, 0.5, 0.5	};

			TEMP oneminus, t1_bx2;
			
		# ComputeChangeColorMacro						
			SUB oneminus.a, one.a, t2.a;					
			MAD r0.rgb, t2.a, c0, oneminus.a;
			MOV r0.a, t2.a;

		# ComputeTintedReflectionMacro					
			MUL t3, t3, v1;

		# ComputeDetailAfterReflectionBiasedAdd_v0
			MUL r0.rgb, r0, v0;
			SUB t1_bx2, t1, half;			
			MUL t1_bx2, t1_bx2, two;
			MUL r1.rgb, t0, t1_bx2;
			MUL r0.rgb, r1, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			MUL r0.a, t0.a, c0.a;

		# ComputeFog
			SUB oneminus.a, one.a, v0.a;
			LRP r1, oneminus.a, r0, c1;
			MAD_SAT r0.rgb, r1, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

//////////////////////////
Technique NoMaskDetailBeforeReflectionBiasedMultiplySelfIllumination_ps_1_1
{
	Pass P0
	{
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
		
//		PixelShader	= (PS_NoMaskDetailBeforeReflectionBiasedMultiplySelfIllumination_ps_1_1);
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
			PARAM c4 = program.env[4];
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			PARAM c6 = { 0.0, 1.0, 0.0, 1.0	};
			PARAM c7 = { 0.5, 0.5, 0.5, 0.5	};

			TEMP oneminus, r1_bx2;

		# ComputeChangeColorMacroWithIllumination			
			DP3_SAT r1, t2, c6;
			SUB oneminus.a, one.a, t2.a;					
			MAD r0.rgb, t2.a, c0, oneminus.a;
			MOV r0.a, r1.b;
			MAD r1, r0.a, c4, v0;
															
		# ComputeTintedReflectionMacro					
			MUL t3, t3, v1;

		# ComputeDetailBeforeReflectionBiasedMultiply_r1
			MUL r0.rgb, r0, r1;
			MUL r0.rgb, t0, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
#DAJ		MUL_X2 r0.rgb, r0, t1;
			MUL r0.rgb, r0, t1;
			MUL r0.rgb, r0, two;
			MUL r0.a, t0.a, c0.a;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique NoMaskDetailBeforeReflectionMultiplySelfIllumination_ps_1_1
{
	Pass P0
	{
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
		
//		PixelShader	= (PS_NoMaskDetailBeforeReflectionMultiplySelfIllumination_ps_1_1);
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
			PARAM c4 = program.env[4];
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			PARAM c6 = { 0.0, 1.0, 0.0, 1.0	};
			PARAM c7 = { 1.0, 1.0, 1.0, 1.0	};

			TEMP oneminus, r1_bx2;
			
		# ComputeChangeColorMacroWithIllumination			
			DP3_SAT r1, t2, c6;
			SUB oneminus.a, one.a, t2.a;					
			MAD r0.rgb, t2.a, c0, oneminus.a;
			MOV r0.a, r1.b;
			MAD r1, r0.a, c4, v0;
															
		# ComputeTintedReflectionMacro					
			MUL t3, t3, v1;

		# ComputeDetailBeforeReflectionMultiply_r1		
			MUL r0.rgb, r0, r1;
			MUL r0.rgb, t0, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			MUL r0.rgb, r0, t1;
			MUL r0.a, t0.a, c0.a;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique NoMaskDetailBeforeReflectionBiasedAddSelfIllumination_ps_1_1
{
	Pass P0
	{
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
		
//		PixelShader	= (PS_NoMaskDetailBeforeReflectionBiasedAddSelfIllumination_ps_1_1);
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
			PARAM c4 = program.env[4];
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			PARAM c6 = { 0.0, 1.0, 0.0, 1.0	};
			PARAM c7 = { 0.5, 0.5, 0.5, 0.5	};

			TEMP oneminus, t1_bx2;

		# ComputeChangeColorMacroWithIllumination			
			DP3_SAT r1, t2, c6;
			SUB oneminus.a, one.a, t2.a;					
			MAD r0.rgb, t2.a, c0, oneminus.a;
			MOV r0.a, r1.b;
			MAD r1, r0.a, c4, v0;
															
		# ComputeTintedReflectionMacro					
			MUL t3, t3, v1;

		# ComputeDetailBeforeReflectionBiasedAdd_r1			
			MUL r0.rgb, r0, r1;
			MUL r0.rgb, t0, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			SUB t1_bx2, t1, half;			
			MUL t1_bx2, t1_bx2, two;
			MUL r0.rgb, r0, t1_bx2;
			MUL r0.a, t0.a, c0.a;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique NoMaskDetailAfterReflectionBiasedMultiplySelfIllumination_ps_1_1
{
	Pass P0
	{
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

//		PixelShader	= (PS_NoMaskDetailAfterReflectionBiasedMultiplySelfIllumination_ps_1_1);
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
			PARAM c4 = program.env[4];
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			PARAM c6 = { 0.0, 1.0, 0.0, 1.0	};
			PARAM c7 = { 0.5, 0.5, 0.5, 0.5	};

			TEMP oneminus, r1_bx2;
			
		# ComputeChangeColorMacroWithIllumination			
			DP3_SAT r1, t2, c6;
			SUB oneminus.a, one.a, t2.a;					
			MAD r0.rgb, t2.a, c0, oneminus.a;
			MOV r0.a, r1.b;
			MAD r1, r0.a, c4, v0;
															
		# ComputeTintedReflectionMacro					
			MUL t3, t3, v1;

		# ComputeDetailAfterReflectionBiasedMultiply_r1
			MUL r0.rgb, r0, r1;
#DAJ		MUL_X2 r1.rgb, t0, t1;
			MUL r1.rgb, t0, t1;
			MUL r1.rgb, r1, two;
			MUL r0.rgb, r1, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			MUL r0.a, t0.a, c0.a;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique NoMaskDetailAfterReflectionMultiplySelfIllumination_ps_1_1
{
	Pass P0
	{
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
		
//		PixelShader	= (PS_NoMaskDetailAfterReflectionMultiplySelfIllumination_ps_1_1);
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
			PARAM c4 = program.env[4];
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			PARAM c6 = { 0.0, 1.0, 0.0, 1.0	};
			PARAM c7 = { 1.0, 1.0, 1.0, 1.0	};

			TEMP oneminus, r1_bx2;
			
		# ComputeChangeColorMacroWithIllumination			
			DP3_SAT r1, t2, c6;
			SUB oneminus.a, one.a, t2.a;					
			MAD r0.rgb, t2.a, c0, oneminus.a;
			MOV r0.a, r1.b;
			MAD r1, r0.a, c4, v0;
															
		# ComputeTintedReflectionMacro					
			MUL t3, t3, v1;

		# ComputeDetailAfterReflectionMultiply_r1	
			MUL r0.rgb, r0, r1;
			MUL r1.rgb, t0, t1;
			MUL r0.rgb, r1, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			MUL r0.a, t0.a, c0.a;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique NoMaskDetailAfterReflectionBiasedAddSelfIllumination_ps_1_1
{
	Pass P0
	{
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
		
//		PixelShader	= (PS_NoMaskDetailAfterReflectionBiasedAddSelfIllumination_ps_1_1);
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
			PARAM c4 = program.env[4];
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			PARAM c6 = { 0.0, 1.0, 0.0, 1.0	};
			PARAM c7 = { 0.5, 0.5, 0.5, 0.5	};

			TEMP oneminus, t1_bx2;
			
		# ComputeChangeColorMacroWithIllumination			
			DP3_SAT r1, t2, c6;
			SUB oneminus.a, one.a, t2.a;					
			MAD r0.rgb, t2.a, c0, oneminus.a;
			MOV r0.a, r1.b;
			MAD r1, r0.a, c4, v0;
															
		# ComputeTintedReflectionMacro					
			MUL t3, t3, v1;

		# ComputeDetailAfterReflectionBiasedAdd_r1
			MUL r0.rgb, r0, r1;
			SUB t1_bx2, t1, half;			
			MUL t1_bx2, t1_bx2, two;
			MUL r1.rgb, t0, t1_bx2;
			MUL r0.rgb, r1, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			MUL r0.a, t0.a, c0.a;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

/*
///////////////////////////////////////////////////////////////////////////////
// Fixed Function shaders
///////////////////////////////////////////////////////////////////////////////
#define FixedFunctionDiffuseMacro		Texture[0]			= (Texture0); \
										ColorOp[0]			= Modulate;	\
										ColorArg1[0]		= Texture;	\
										ColorArg2[0]		= Diffuse;	\
										AlphaOp[0]			= SelectArg1;	\
										AlphaArg1[0]		= Texture;	\
										ColorOp[1]			= Disable;	\
										AlphaOp[1]			= Disable;	\
										PixelShader			= Null;

#define FixedFunctionChangeColorMacro	AlphaBlendEnable	= True; \
										SrcBlend			= Zero; \
										DestBlend			= SrcColor; \
										BlendOp				= Add; \
										ZWriteEnable		= False; \
										ZFunc				= Equal; \
										Texture[0]			= (Texture1); \
										ColorOp[0]			= Modulate;	\
										ColorArg1[0]		= Texture|AlphaReplicate;	\
										ColorArg2[0]		= TFactor;	\
										AlphaOp[0]			= SelectArg1;	\
										AlphaArg1[0]		= Texture;	\
										ColorOp[1]			= Disable;	\
										AlphaOp[1]			= Disable;	\
										PixelShader			= Null;
*/
Technique NoMaskDetailBeforeReflectionBiasedMultiply_ps_0_0
{
	Pass P0
	{
		Texture[0]			= (Texture0);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;
		ColorOp[1]			= Disable;
		AlphaOp[1]			= Disable;
		PixelShader			= Null;

	}
	Pass P1
	{
		AlphaBlendEnable	= True;
		SrcBlend			= Zero;
		DestBlend			= SrcColor;
		BlendOp				= Add;
		ZWriteEnable		= False;
		ZFunc				= Equal;
		Texture[0]			= (Texture1);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture|AlphaReplicate;
		ColorArg2[0]		= TFactor;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;
		ColorOp[1]			= Disable;
		AlphaOp[1]			= Disable;
		PixelShader			= Null;

	}
}

Technique NoMaskDetailBeforeReflectionMultiply_ps_0_0
{
	Pass P0
	{
		Texture[0]			= (Texture0);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;
		ColorOp[1]			= Disable;
		AlphaOp[1]			= Disable;
		PixelShader			= Null;

	}
	Pass P1
	{
		AlphaBlendEnable	= True;
		SrcBlend			= Zero;
		DestBlend			= SrcColor;
		BlendOp				= Add;
		ZWriteEnable		= False;
		ZFunc				= Equal;
		Texture[0]			= (Texture1);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture|AlphaReplicate;
		ColorArg2[0]		= TFactor;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;
		ColorOp[1]			= Disable;
		AlphaOp[1]			= Disable;
		PixelShader			= Null;

	}
}

Technique NoMaskDetailBeforeReflectionBiasedAdd_ps_0_0
{
	Pass P0
	{
		Texture[0]			= (Texture0);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;
		ColorOp[1]			= Disable;
		AlphaOp[1]			= Disable;
		PixelShader			= Null;

	}
	Pass P1
	{
		AlphaBlendEnable	= True;
		SrcBlend			= Zero;
		DestBlend			= SrcColor;
		BlendOp				= Add;
		ZWriteEnable		= False;
		ZFunc				= Equal;
		Texture[0]			= (Texture1);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture|AlphaReplicate;
		ColorArg2[0]		= TFactor;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;
		ColorOp[1]			= Disable;
		AlphaOp[1]			= Disable;
		PixelShader			= Null;

	}
}

Technique NoMaskDetailAfterReflectionBiasedMultiply_ps_0_0
{
	Pass P0
	{
		Texture[0]			= (Texture0);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;
		ColorOp[1]			= Disable;
		AlphaOp[1]			= Disable;
		PixelShader			= Null;

	}
	Pass P1
	{
		AlphaBlendEnable	= True;
		SrcBlend			= Zero;
		DestBlend			= SrcColor;
		BlendOp				= Add;
		ZWriteEnable		= False;
		ZFunc				= Equal;
		Texture[0]			= (Texture1);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture|AlphaReplicate;
		ColorArg2[0]		= TFactor;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;
		ColorOp[1]			= Disable;
		AlphaOp[1]			= Disable;
		PixelShader			= Null;

	}
}

Technique NoMaskDetailAfterReflectionMultiply_ps_0_0
{
	Pass P0
	{
		Texture[0]			= (Texture0);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;
		ColorOp[1]			= Disable;
		AlphaOp[1]			= Disable;
		PixelShader			= Null;

	}
	Pass P1
	{
		AlphaBlendEnable	= True;
		SrcBlend			= Zero;
		DestBlend			= SrcColor;
		BlendOp				= Add;
		ZWriteEnable		= False;
		ZFunc				= Equal;
		Texture[0]			= (Texture1);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture|AlphaReplicate;
		ColorArg2[0]		= TFactor;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;
		ColorOp[1]			= Disable;
		AlphaOp[1]			= Disable;
		PixelShader			= Null;

	}
}

Technique NoMaskDetailAfterReflectionBiasedAdd_ps_0_0
{
	Pass P0
	{
		Texture[0]			= (Texture0);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;
		ColorOp[1]			= Disable;
		AlphaOp[1]			= Disable;
		PixelShader			= Null;

	}
	Pass P1
	{
		AlphaBlendEnable	= True;
		SrcBlend			= Zero;
		DestBlend			= SrcColor;
		BlendOp				= Add;
		ZWriteEnable		= False;
		ZFunc				= Equal;
		Texture[0]			= (Texture1);
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture|AlphaReplicate;
		ColorArg2[0]		= TFactor;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;
		ColorOp[1]			= Disable;
		AlphaOp[1]			= Disable;
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
