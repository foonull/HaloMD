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
half4 ModelMaskReflection(
    half4 Diff	: COLOR0,
    half4 Spec	: COLOR1,
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
	R0		= (T2.a*c_primary_change_color) + (1-T2.a);
	
	// combiner 3
	if(detail_function_multiply==nDetailFunction)
	{
		T1.rgb = bInverse ? lerp( T1, 1.0, T2.b ) : lerp( 1.0, T1, T2.b );
	}
	else
	{
		T1.rgb = bInverse ? lerp( T1, 0.5, T2.b ) : lerp( 0.5, T1, T2.b );
	}
	
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
		R1.rgb	= saturate(c_fog_color_correction_1 - (D0.a * c_fog_color_correction_E));
		
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

PixelShader PS_ReflectionMaskInverseDetailBeforeReflectionBiasedMultiply_ps_2_0	= compile PS_2_0_TARGET ModelMaskReflection( detail_function_biased_multiply, true, true, false );
PixelShader PS_ReflectionMaskInverseDetailBeforeReflectionMultiply_ps_2_0		= compile PS_2_0_TARGET ModelMaskReflection( detail_function_multiply, true, true, false );
PixelShader PS_ReflectionMaskInverseDetailBeforeReflectionBiasedAdd_ps_2_0		= compile PS_2_0_TARGET ModelMaskReflection( detail_function_biased_add, true, true, false );
PixelShader PS_ReflectionMaskInverseDetailAfterReflectionBiasedMultiply_ps_2_0	= compile PS_2_0_TARGET ModelMaskReflection( detail_function_biased_multiply, false, true, false );
PixelShader PS_ReflectionMaskInverseDetailAfterReflectionMultiply_ps_2_0		= compile PS_2_0_TARGET ModelMaskReflection( detail_function_multiply, false, true, false );
PixelShader PS_ReflectionMaskInverseDetailAfterReflectionBiasedAdd_ps_2_0		= compile PS_2_0_TARGET ModelMaskReflection( detail_function_biased_add, false, true, false );
PixelShader PS_ReflectionMaskDetailBeforeReflectionBiasedMultiply_ps_2_0		= compile PS_2_0_TARGET ModelMaskReflection( detail_function_biased_multiply, true, false, false );
PixelShader PS_ReflectionMaskDetailBeforeReflectionMultiply_ps_2_0				= compile PS_2_0_TARGET ModelMaskReflection( detail_function_multiply, true, false, false );
PixelShader PS_ReflectionMaskDetailBeforeReflectionBiasedAdd_ps_2_0				= compile PS_2_0_TARGET ModelMaskReflection( detail_function_biased_add, true, false, false );
PixelShader PS_ReflectionMaskDetailAfterReflectionBiasedMultiply_ps_2_0			= compile PS_2_0_TARGET ModelMaskReflection( detail_function_biased_multiply, false, false, false );
PixelShader PS_ReflectionMaskDetailAfterReflectionMultiply_ps_2_0				= compile PS_2_0_TARGET ModelMaskReflection( detail_function_multiply, false, false, false );
PixelShader PS_ReflectionMaskDetailAfterReflectionBiasedAdd_ps_2_0				= compile PS_2_0_TARGET ModelMaskReflection( detail_function_biased_add, false, false, false );

PixelShader PS_ReflectionMaskInverseDetailBeforeReflectionBiasedMultiplyComplexFog_ps_2_0	= compile PS_2_0_TARGET ModelMaskReflection( detail_function_biased_multiply, true, true, true );
PixelShader PS_ReflectionMaskInverseDetailBeforeReflectionMultiplyComplexFog_ps_2_0			= compile PS_2_0_TARGET ModelMaskReflection( detail_function_multiply, true, true, true );
PixelShader PS_ReflectionMaskInverseDetailBeforeReflectionBiasedAddComplexFog_ps_2_0		= compile PS_2_0_TARGET ModelMaskReflection( detail_function_biased_add, true, true, true );
PixelShader PS_ReflectionMaskInverseDetailAfterReflectionBiasedMultiplyComplexFog_ps_2_0	= compile PS_2_0_TARGET ModelMaskReflection( detail_function_biased_multiply, false, true, true );
PixelShader PS_ReflectionMaskInverseDetailAfterReflectionMultiplyComplexFog_ps_2_0			= compile PS_2_0_TARGET ModelMaskReflection( detail_function_multiply, false, true, true );
PixelShader PS_ReflectionMaskInverseDetailAfterReflectionBiasedAddComplexFog_ps_2_0			= compile PS_2_0_TARGET ModelMaskReflection( detail_function_biased_add, false, true, true );
PixelShader PS_ReflectionMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_2_0			= compile PS_2_0_TARGET ModelMaskReflection( detail_function_biased_multiply, true, false, true );
PixelShader PS_ReflectionMaskDetailBeforeReflectionMultiplyComplexFog_ps_2_0				= compile PS_2_0_TARGET ModelMaskReflection( detail_function_multiply, true, false, true );
PixelShader PS_ReflectionMaskDetailBeforeReflectionBiasedAddComplexFog_ps_2_0				= compile PS_2_0_TARGET ModelMaskReflection( detail_function_biased_add, true, false, true );
PixelShader PS_ReflectionMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_2_0			= compile PS_2_0_TARGET ModelMaskReflection( detail_function_biased_multiply, false, false, true );
PixelShader PS_ReflectionMaskDetailAfterReflectionMultiplyComplexFog_ps_2_0					= compile PS_2_0_TARGET ModelMaskReflection( detail_function_multiply, false, false, true );
PixelShader PS_ReflectionMaskDetailAfterReflectionBiasedAddComplexFog_ps_2_0				= compile PS_2_0_TARGET ModelMaskReflection( detail_function_biased_add, false, false, true );

Technique ReflectionMaskInverseDetailBeforeReflectionBiasedMultiply_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskInverseDetailBeforeReflectionBiasedMultiply_ps_2_0);
	}
}

Technique ReflectionMaskInverseDetailBeforeReflectionMultiply_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskInverseDetailBeforeReflectionMultiply_ps_2_0);
	}
}

Technique ReflectionMaskInverseDetailBeforeReflectionBiasedAdd_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskInverseDetailBeforeReflectionBiasedAdd_ps_2_0);
	}
}

Technique ReflectionMaskInverseDetailAfterReflectionBiasedMultiply_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskInverseDetailAfterReflectionBiasedMultiply_ps_2_0);
	}
}

Technique ReflectionMaskInverseDetailAfterReflectionMultiply_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskInverseDetailAfterReflectionMultiply_ps_2_0);
	}
}

Technique ReflectionMaskInverseDetailAfterReflectionBiasedAdd_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskInverseDetailAfterReflectionBiasedAdd_ps_2_0);
	}
}

Technique ReflectionMaskDetailBeforeReflectionBiasedMultiply_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskDetailBeforeReflectionBiasedMultiply_ps_2_0);
	}
}

Technique ReflectionMaskDetailBeforeReflectionMultiply_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskDetailBeforeReflectionMultiply_ps_2_0);
	}
}

Technique ReflectionMaskDetailBeforeReflectionBiasedAdd_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskDetailBeforeReflectionBiasedAdd_ps_2_0);
	}
}

Technique ReflectionMaskDetailAfterReflectionBiasedMultiply_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskDetailAfterReflectionBiasedMultiply_ps_2_0);
	}
}

Technique ReflectionMaskDetailAfterReflectionMultiply_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskDetailAfterReflectionMultiply_ps_2_0);
	}
}

Technique ReflectionMaskDetailAfterReflectionBiasedAdd_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskDetailAfterReflectionBiasedAdd_ps_2_0);
	}
}

Technique ReflectionMaskInverseDetailBeforeReflectionBiasedMultiplyComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskInverseDetailBeforeReflectionBiasedMultiplyComplexFog_ps_2_0);
	}
}

Technique ReflectionMaskInverseDetailBeforeReflectionMultiplyComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskInverseDetailBeforeReflectionMultiplyComplexFog_ps_2_0);
	}
}

Technique ReflectionMaskInverseDetailBeforeReflectionBiasedAddComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskInverseDetailBeforeReflectionBiasedAddComplexFog_ps_2_0);
	}
}

Technique ReflectionMaskInverseDetailAfterReflectionBiasedMultiplyComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskInverseDetailAfterReflectionBiasedMultiplyComplexFog_ps_2_0);
	}
}

Technique ReflectionMaskInverseDetailAfterReflectionMultiplyComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskInverseDetailAfterReflectionMultiplyComplexFog_ps_2_0);
	}
}

Technique ReflectionMaskInverseDetailAfterReflectionBiasedAddComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskInverseDetailAfterReflectionBiasedAddComplexFog_ps_2_0);
	}
}

Technique ReflectionMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_2_0);
	}
}

Technique ReflectionMaskDetailBeforeReflectionMultiplyComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskDetailBeforeReflectionMultiplyComplexFog_ps_2_0);
	}
}

Technique ReflectionMaskDetailBeforeReflectionBiasedAddComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskDetailBeforeReflectionBiasedAddComplexFog_ps_2_0);
	}
}

Technique ReflectionMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_2_0);
	}
}

Technique ReflectionMaskDetailAfterReflectionMultiplyComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskDetailAfterReflectionMultiplyComplexFog_ps_2_0);
	}
}

Technique ReflectionMaskDetailAfterReflectionBiasedAddComplexFog_ps_2_0
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		PixelShader = (PS_ReflectionMaskDetailAfterReflectionBiasedAddComplexFog_ps_2_0);
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

#define MultiplyInverse \
    mad T1, T1, T2.b, 1-T2.b

#define MultiplyNotInverse \
    mad T1, T1, 1-T2.b, T2.b

#define NotMultiplyInverse \
    mad_d2 T1, T1_x2, 1-T2.b, T2.b

#define NotMultiplyNotInverse \
    mad_d2 T1, T1_x2, T2.b, 1-T2.b

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
    +mul r0.a, T0.a, c0.a

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
    +mul r0.a, T0.a, c0.a

#define BiasedMultiply(R) \
    mul R.rgb, R, T1_x2

#define Multiply(R) \
    mul R.rgb, R, T1

#define BiasedAdd(R) \
    add R.rgb, R, T1_bx2

PixelShader PS_ReflectionMaskInverseDetailBeforeReflectionBiasedMultiply_ps_1_4 = asm
{
    FirstPhaseBegin
    NotMultiplyInverse
    FirstPhaseEnd
    SecondPhaseBegin
    BiasedMultiply(R0)
    SecondPhaseEnd
};

PixelShader PS_ReflectionMaskInverseDetailBeforeReflectionMultiply_ps_1_4 = asm
{
    FirstPhaseBegin
    MultiplyInverse
    FirstPhaseEnd
    SecondPhaseBegin
    Multiply(R0)
    SecondPhaseEnd
};

PixelShader PS_ReflectionMaskInverseDetailBeforeReflectionBiasedAdd_ps_1_4 = asm
{
    FirstPhaseBegin
    NotMultiplyInverse
    FirstPhaseEnd
    SecondPhaseBegin
    BiasedAdd(R0)
    SecondPhaseEnd
};

PixelShader PS_ReflectionMaskInverseDetailAfterReflectionBiasedMultiply_ps_1_4 = asm
{
    FirstPhaseBegin
    NotMultiplyInverse
    BiasedMultiply(T0)
    FirstPhaseEnd
    SecondPhaseBegin
    SecondPhaseEnd
};

PixelShader PS_ReflectionMaskInverseDetailAfterReflectionMultiply_ps_1_4 = asm
{
    FirstPhaseBegin
    MultiplyInverse
    Multiply(T0)
    FirstPhaseEnd
    SecondPhaseBegin
    SecondPhaseEnd
};

PixelShader PS_ReflectionMaskInverseDetailAfterReflectionBiasedAdd_ps_1_4 = asm
{
    FirstPhaseBegin
    NotMultiplyInverse
    BiasedAdd(T0)
    FirstPhaseEnd
    SecondPhaseBegin
    SecondPhaseEnd
};

PixelShader PS_ReflectionMaskDetailBeforeReflectionBiasedMultiply_ps_1_4 = asm
{
    FirstPhaseBegin
    NotMultiplyNotInverse
    FirstPhaseEnd
    SecondPhaseBegin
    BiasedMultiply(R0)
    SecondPhaseEnd
};

PixelShader PS_ReflectionMaskDetailBeforeReflectionMultiply_ps_1_4 = asm
{
    FirstPhaseBegin
    MultiplyNotInverse
    FirstPhaseEnd
    SecondPhaseBegin
    Multiply(R0)
    SecondPhaseEnd
};

PixelShader PS_ReflectionMaskDetailBeforeReflectionBiasedAdd_ps_1_4 = asm
{
    FirstPhaseBegin
    NotMultiplyNotInverse
    FirstPhaseEnd
    SecondPhaseBegin
    BiasedAdd(R0)
    SecondPhaseEnd
};

PixelShader PS_ReflectionMaskDetailAfterReflectionBiasedMultiply_ps_1_4 = asm
{
    FirstPhaseBegin
    NotMultiplyNotInverse
    BiasedMultiply(T0)
    FirstPhaseEnd
    SecondPhaseBegin
    SecondPhaseEnd
};

PixelShader PS_ReflectionMaskDetailAfterReflectionMultiply_ps_1_4 = asm
{
    FirstPhaseBegin
    MultiplyNotInverse
    Multiply(T0)
    FirstPhaseEnd
    SecondPhaseBegin
    SecondPhaseEnd
};

PixelShader PS_ReflectionMaskDetailAfterReflectionBiasedAdd_ps_1_4 = asm
{
    FirstPhaseBegin
    NotMultiplyNotInverse
    BiasedAdd(T0)
    FirstPhaseEnd
    SecondPhaseBegin
    SecondPhaseEnd
};

///////////////////////////////////
PixelShader PS_ReflectionMaskInverseDetailBeforeReflectionBiasedMultiplyComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    NotMultiplyInverse
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    BiasedMultiply(R0)
    SecondPhaseComplexFogEnd
};

PixelShader PS_ReflectionMaskInverseDetailBeforeReflectionMultiplyComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    MultiplyInverse
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    Multiply(R0)
    SecondPhaseComplexFogEnd
};

PixelShader PS_ReflectionMaskInverseDetailBeforeReflectionBiasedAddComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    NotMultiplyInverse
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    BiasedAdd(R0)
    SecondPhaseComplexFogEnd
};

PixelShader PS_ReflectionMaskInverseDetailAfterReflectionBiasedMultiplyComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    NotMultiplyInverse
    BiasedMultiply(T0)
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    SecondPhaseComplexFogEnd
};

PixelShader PS_ReflectionMaskInverseDetailAfterReflectionMultiplyComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    MultiplyInverse
    Multiply(T0)
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    SecondPhaseComplexFogEnd
};

PixelShader PS_ReflectionMaskInverseDetailAfterReflectionBiasedAddComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    NotMultiplyInverse
    BiasedAdd(T0)
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    SecondPhaseComplexFogEnd
};

PixelShader PS_ReflectionMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    NotMultiplyNotInverse
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    BiasedMultiply(R0)
    SecondPhaseComplexFogEnd
};

PixelShader PS_ReflectionMaskDetailBeforeReflectionMultiplyComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    MultiplyNotInverse
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    Multiply(R0)
    SecondPhaseComplexFogEnd
};

PixelShader PS_ReflectionMaskDetailBeforeReflectionBiasedAddComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    NotMultiplyNotInverse
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    BiasedAdd(R0)
    SecondPhaseComplexFogEnd
};

PixelShader PS_ReflectionMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    NotMultiplyNotInverse
    BiasedMultiply(T0)
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    SecondPhaseComplexFogEnd
};

PixelShader PS_ReflectionMaskDetailAfterReflectionMultiplyComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    MultiplyNotInverse
    Multiply(T0)
    FirstPhaseEnd
    SecondPhaseComplexFogBegin
    SecondPhaseComplexFogEnd
};

PixelShader PS_ReflectionMaskDetailAfterReflectionBiasedAddComplexFog_ps_1_4 = asm
{
    FirstPhaseBegin
    NotMultiplyNotInverse
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

Technique ReflectionMaskInverseDetailBeforeReflectionBiasedMultiply_ps_1_4
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
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp0, r1, mulConst.r;
			SUB tmp1, const.b, r2;
			MAD r1, tmp0, tmp1.b, r2.b;
			MUL r1, r1, divConst.r;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			#TEX r0, t0, texture[0], 2D;
			#TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MUL tmp1, r1, mulConst.r;
			MUL r4.rgb, r4, tmp1;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;		
	    };
		//PixelShader = (PS_ReflectionMaskInverseDetailBeforeReflectionBiasedMultiply_ps_1_4);
	}
}

Technique ReflectionMaskInverseDetailBeforeReflectionMultiply_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			SUB tmp1, const.b, r2;
			MAD r1, r1, r2.b, tmp1.b;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MUL r4.rgb, r4, r1;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskInverseDetailBeforeReflectionMultiply_ps_1_4);
	}
}

Technique ReflectionMaskInverseDetailBeforeReflectionBiasedAdd_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp0, r1, mulConst.r;
			SUB tmp1, const.b, r2;
			MAD r1, tmp0, tmp1.b, r2.b;
			MUL r1, r1, divConst.r;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MAD tmp1, r1, mulConst.r, -const.b;
			ADD r4.rgb, r4, tmp1;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskInverseDetailBeforeReflectionBiasedAdd_ps_1_4);
	}
}

Technique ReflectionMaskInverseDetailAfterReflectionBiasedMultiply_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp0, r1, mulConst.r;
			SUB tmp1, const.b, r2;
			MAD r1, tmp0, tmp1.b, r2.b;
			MUL r1, r1, divConst.r;
			MUL tmp1, r1, mulConst.r;
			MUL r0.rgb, r0, tmp1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskInverseDetailAfterReflectionBiasedMultiply_ps_1_4);
	}
}

Technique ReflectionMaskInverseDetailAfterReflectionMultiply_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			SUB tmp1, const.b, r2;
			MAD r1, r1, r2.b, tmp1.b;
			MUL r0.rgb, r0, r1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskInverseDetailAfterReflectionMultiply_ps_1_4);
	}
}

Technique ReflectionMaskInverseDetailAfterReflectionBiasedAdd_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp0, r1, mulConst.r;
			SUB tmp1, const.b, r2;
			MAD r1, tmp0, tmp1.b, r2.b;
			MUL r1, r1, divConst.r;
			MAD tmp1, r1, mulConst.r, -const.b;
			ADD r0.rgb, r0, tmp1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskInverseDetailAfterReflectionBiasedAdd_ps_1_4);
	}
}

Technique ReflectionMaskDetailBeforeReflectionBiasedMultiply_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp0, r1, mulConst.r;
			SUB tmp1, const.b, r2;
			MAD r1, tmp0, r2.b, tmp1.b;
			MUL r1, r1, divConst.r;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MUL tmp1, r1, mulConst.r;
			MUL r4.rgb, r4, tmp1;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskDetailBeforeReflectionBiasedMultiply_ps_1_4);
	}
}

Technique ReflectionMaskDetailBeforeReflectionMultiply_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			SUB tmp1, const.b, r2;
			MAD r1, r1, tmp1.b, r2.b;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MUL r4.rgb, r4, r1;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskDetailBeforeReflectionMultiply_ps_1_4);
	}
}

Technique ReflectionMaskDetailBeforeReflectionBiasedAdd_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp0, r1, mulConst.r;
			SUB tmp1, const.b, r2;
			MAD r1, tmp0, r2.b, tmp1.b;
			MUL r1, r1, divConst.r;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MAD tmp1, r1, mulConst.r, -const.b;
			ADD r4.rgb, r4, tmp1;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskDetailBeforeReflectionBiasedAdd_ps_1_4);
	}
}

Technique ReflectionMaskDetailAfterReflectionBiasedMultiply_ps_1_4
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
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp0, r1, mulConst.r;
			SUB tmp1, const.b, r2;
			MAD r1, tmp0, r2.b, tmp1.b;
			MUL r1, r1, divConst.r;
			MUL tmp1, r1, mulConst.r;
			MUL r0.rgb, r0, tmp1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			#TEX r0, t0, texture[0], 2D;
			#TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
	    };
		//PixelShader = (PS_ReflectionMaskDetailAfterReflectionBiasedMultiply_ps_1_4);
	}
}

Technique ReflectionMaskDetailAfterReflectionMultiply_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			SUB tmp1, const.b, r2;
			MAD r1, r1, tmp1.b, r2.b;
			MUL r0.rgb, r0, r1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskDetailAfterReflectionMultiply_ps_1_4);
	}
}

Technique ReflectionMaskDetailAfterReflectionBiasedAdd_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp0, r1, mulConst.r;
			SUB tmp1, const.b, r2;
			MAD r1, tmp0, r2.b, tmp1.b;
			MUL r1, r1, divConst.r;
			MAD tmp1, r1, mulConst.r, -const.b;
			ADD r0.rgb, r0, tmp1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MUL r4.a, r2.b, v1.a;
			MAD r4.rgb, r3, r4.a, r4;
			MOV r0.rgb, r4;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskDetailAfterReflectionBiasedAdd_ps_1_4);
	}
}

Technique ReflectionMaskInverseDetailBeforeReflectionBiasedMultiplyComplexFog_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp0, r1, mulConst.r;
			SUB tmp1, const.b, r2;
			MAD r1, tmp0, tmp1.b, r2.b;
			MUL r1, r1, divConst.r;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			#TEX r0, t0, texture[0], 2D;
			#TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
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
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			##MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskInverseDetailBeforeReflectionBiasedMultiplyComplexFog_ps_1_4);
	}
}

Technique ReflectionMaskInverseDetailBeforeReflectionMultiplyComplexFog_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			SUB tmp1, const.b, r2;
			MAD r1, r1, r2.b, tmp1.b;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MAD r5.rgb, v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL r4.rgb, r4, r1;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskInverseDetailBeforeReflectionMultiplyComplexFog_ps_1_4);
	}
}

Technique ReflectionMaskInverseDetailBeforeReflectionBiasedAddComplexFog_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp0, r1, mulConst.r;
			SUB tmp1, const.b, r2;
			MAD r1, tmp0, tmp1.b, r2.b;
			MUL r1, r1, divConst.r;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
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
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskInverseDetailBeforeReflectionBiasedAddComplexFog_ps_1_4);
	}
}

Technique ReflectionMaskInverseDetailAfterReflectionBiasedMultiplyComplexFog_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp0, r1, mulConst.r;
			SUB tmp1, const.b, r2;
			MAD r1, tmp0, tmp1.b, r2.b;
			MUL r1, r1, divConst.r;
			MUL tmp1, r1, mulConst.r;
			MUL r0.rgb, r0, tmp1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MAD r5.rgb, v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskInverseDetailAfterReflectionBiasedMultiplyComplexFog_ps_1_4);
	}
}

Technique ReflectionMaskInverseDetailAfterReflectionMultiplyComplexFog_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			SUB tmp1, const.b, r2;
			MAD r1, r1, r2.b, tmp1.b;
			MUL r0.rgb, r0, r1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MAD r5.rgb, v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskInverseDetailAfterReflectionMultiplyComplexFog_ps_1_4);
	}
}

Technique ReflectionMaskInverseDetailAfterReflectionBiasedAddComplexFog_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp0, r1, mulConst.r;
			SUB tmp1, const.b, r2;
			MAD r1, tmp0, tmp1.b, r2.b;
			MUL r1, r1, divConst.r;
			MAD tmp1, r1, mulConst.r, -const.b;
			ADD r0.rgb, r0, tmp1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MAD r5.rgb, v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskInverseDetailAfterReflectionBiasedAddComplexFog_ps_1_4);
	}
}

Technique ReflectionMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp0, r1, mulConst.r;
			SUB tmp1, const.b, r2;
			MAD r1, tmp0, r2.b, tmp1.b;
			MUL r1, r1, divConst.r;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
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
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskDetailBeforeReflectionBiasedMultiplyComplexFog_ps_1_4);
	}
}

Technique ReflectionMaskDetailBeforeReflectionMultiplyComplexFog_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			SUB tmp1, const.b, r2;
			MAD r1, r1, tmp1.b, r2.b;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MAD r5.rgb, v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL r4.rgb, r4, r1;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskDetailBeforeReflectionMultiplyComplexFog_ps_1_4);
	}
}

Technique ReflectionMaskDetailBeforeReflectionBiasedAddComplexFog_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp0, r1, mulConst.r;
			SUB tmp1, const.b, r2;
			MAD r1, tmp0, r2.b, tmp1.b;
			MUL r1, r1, divConst.r;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
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
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskDetailBeforeReflectionBiasedAddComplexFog_ps_1_4);
	}
}

Technique ReflectionMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp0, r1, mulConst.r;
			SUB tmp1, const.b, r2;
			MAD r1, tmp0, r2.b, tmp1.b;
			MUL r1, r1, divConst.r;
			MUL tmp1, r1, mulConst.r;
			MUL r0.rgb, r0, tmp1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			#TEX r0, t0, texture[0], 2D;
			#TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MAD r5.rgb, v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			##MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskDetailAfterReflectionBiasedMultiplyComplexFog_ps_1_4);
	}
}

Technique ReflectionMaskDetailAfterReflectionMultiplyComplexFog_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			SUB tmp1, const.b, r2;
			MAD r1, r1, tmp1.b, r2.b;
			MUL r0.rgb, r0, r1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MAD r5.rgb, v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskDetailAfterReflectionMultiplyComplexFog_ps_1_4);
	}
}

Technique ReflectionMaskDetailAfterReflectionBiasedAddComplexFog_ps_1_4
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
	    	
			TEMP tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM red = {1.0, 0.0, 0.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c4 = program.env[4];
			ATTRIB t0 = fragment.texcoord[0];
			ATTRIB t1 = fragment.texcoord[1];
			ATTRIB t2 = fragment.texcoord[2];
			ATTRIB t3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			ATTRIB v1 = fragment.color.secondary;
			OUTPUT oC0 = result.color;
			TEX r0, t0, texture[0], 2D;
			TEX r1, t1, texture[1], 2D;
			TEX r2, t2, texture[2], 2D;
			SUB tmp1, const.b, r2;
			MAD r4, r2.a, c0, tmp1.a;
			MUL r5, r2.g, c4;
			MUL tmp0, r1, mulConst.r;
			SUB tmp1, const.b, r2;
			MAD r1, tmp0, r2.b, tmp1.b;
			MUL r1, r1, divConst.r;
			MAD tmp1, r1, mulConst.r, -const.b;
			ADD r0.rgb, r0, tmp1;
			MUL r4.rgb, r4, r0;
			MUL r5, r4, r5;
			TEX r0, t0, texture[0], 2D;
			TEX r2, t2, texture[2], 2D;
			TEX r3, t3, texture[3], CUBE;
			MUL r3.rgb, r3, v1;
			MAD r4.rgb, v0, r4, r5;
			MAD r5.rgb, v0.a, c2, c3;
			MUL r5.a, r2.b, v1.a;
			MAD r4.rgb, r3, r5.a, r4;
			MUL r4.rgb, r4, c1.a;
			LRP r4.rgb, v0.a, c1, r4;
			ADD r0.rgb, r4, r5;
			MUL r0.a, r0.a, c0.a;
			MOV oC0, r0;
			#MOV oC0, red;
			
	    };
		//PixelShader = (PS_ReflectionMaskDetailAfterReflectionBiasedAddComplexFog_ps_1_4);
	}
}

/* RAV

///////////////////////////////////////////////////////////////////////////////
// Pixel Shader 1.1 shaders
///////////////////////////////////////////////////////////////////////////////
#define ComputeChangeColorMacro						mad r0.rgb, t2.a, c0, 1-t2.a \
													+ mov_sat r0.a, t2.b

#define ComputeDetailMacro							lrp r1, r0.a, t1, c7

#define ComputeInverseDetailMacro					lrp r1, r0.a, c7, t1

#define ComputeTintedReflectionMacro				mul t3, t3, v1

#define ComputeDetailBeforeReflectionBiasedMultiply	mul r0.rgb, r0, v0	\
													mul r0.rgb, t0, r0 \
													+ mul r0.a, t2.b, v1.a \
													mad r0.rgb, t3, r0.a, r0 \
													mul_x2 r0.rgb, r0, r1 \
													+ mul r0.a, t0.a, c0.a
													
#define ComputeDetailBeforeReflectionMultiply		mul r0.rgb, r0, v0	\
													mul r0.rgb, t0, r0 \
													+ mul r0.a, t2.b, v1.a \
													mad r0.rgb, t3, r0.a, r0 \
													mul r0.rgb, r0, r1 \
													+ mul r0.a, t0.a, c0.a

#define ComputeDetailBeforeReflectionBiasedAdd		mul r0.rgb, r0, v0	\
													mul r0.rgb, t0, r0 \
													+ mul r0.a, t2.b, v1.a \
													mad r0.rgb, t3, r0.a, r0 \
													mul r0.rgb, r0, r1_bx2 \
													+ mul r0.a, t0.a, c0.a

#define ComputeDetailAfterReflectionBiasedMultiply	mul r0.rgb, r0, v0	\
													mul_x2 r1.rgb, t0, r1 \
													mul r0.rgb, r1, r0 \
													+ mul r0.a, t2.b, v1.a \
													mad r0.rgb, t3, r0.a, r0 \
													+ mul r0.a, t0.a, c0.a

#define ComputeDetailAfterReflectionMultiply		mul r0.rgb, r0, v0	\
													mul r1.rgb, t0, r1 \
													mul r0.rgb, r1, r0 \
													+ mul r0.a, t2.b, v1.a \
													mad r0.rgb, t3, r0.a, r0 \
													+ mul r0.a, t0.a, c0.a

#define ComputeDetailAfterReflectionBiasedAdd		mul r0.rgb, r0, v0	\
													mul r1.rgb, t0, r1_bx2 \
													mul r0.rgb, r1, r0 \
													+ mul r0.a, t2.b, v1.a \
													mad r0.rgb, t3, r0.a, r0 \
													+ mul r0.a, t0.a, c0.a

#define	ComputeFog									mad_sat r0.rgb, r0, c1.a, c3

#define SetState \
    PixelShaderConstant[0] = (c_primary_change_color); \
    PixelShaderConstant[1] = (c_fog_color_correction_0); \
    PixelShaderConstant[2] = (c_fog_color_correction_1); \
    Texture[0]	= (Texture0); \
    Texture[1]	= (Texture1); \
    Texture[2]	= (Texture2); \
    Texture[3]	= (Texture3); \
    ColorOp[0]	= Disable; \
    AlphaOp[0]	= Disable;

PixelShader	PS_ReflectionMaskInverseDetailBeforeReflectionBiasedMultiply_ps_1_1 = asm
{
	ps_1_1

	def c7, 0.5, 0.5, 0.5, 0.5

	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map

	ComputeChangeColorMacro
	ComputeInverseDetailMacro
	ComputeTintedReflectionMacro
	ComputeDetailBeforeReflectionBiasedMultiply
	ComputeFog
};
		
PixelShader PS_ReflectionMaskInverseDetailBeforeReflectionMultiply_ps_1_1 = asm
{
	ps_1_1

	def c7, 1.0, 1.0, 1.0, 1.0
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacro
	ComputeInverseDetailMacro
	ComputeTintedReflectionMacro
	ComputeDetailBeforeReflectionMultiply
	ComputeFog
};

PixelShader PS_ReflectionMaskInverseDetailBeforeReflectionBiasedAdd_ps_1_1 = asm
{
	ps_1_1

	def c7, 0.5, 0.5, 0.5, 0.5
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map

	ComputeChangeColorMacro
	ComputeInverseDetailMacro
	ComputeTintedReflectionMacro
	ComputeDetailBeforeReflectionBiasedAdd
	ComputeFog
};

PixelShader PS_ReflectionMaskInverseDetailAfterReflectionBiasedMultiply_ps_1_1 = asm
{
	ps_1_1

	def c7, 0.5, 0.5, 0.5, 0.5
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacro
	ComputeInverseDetailMacro
	ComputeTintedReflectionMacro
	ComputeDetailAfterReflectionBiasedMultiply
	ComputeFog
};

PixelShader PS_ReflectionMaskInverseDetailAfterReflectionMultiply_ps_1_1 = asm
{
	ps_1_1

	def c7, 1.0, 1.0, 1.0, 1.0
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacro
	ComputeInverseDetailMacro
	ComputeTintedReflectionMacro
	ComputeDetailAfterReflectionMultiply
	ComputeFog
};

PixelShader PS_ReflectionMaskInverseDetailAfterReflectionBiasedAdd_ps_1_1 = asm
{
	ps_1_1

	def c7, 0.5, 0.5, 0.5, 0.5
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacro
	ComputeInverseDetailMacro
	ComputeTintedReflectionMacro
	ComputeDetailAfterReflectionBiasedAdd
	ComputeFog
};

PixelShader PS_ReflectionMaskDetailBeforeReflectionBiasedMultiply_ps_1_1 = asm
{
	ps_1_1

	def c7, 0.5, 0.5, 0.5, 0.5

	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacro
	ComputeDetailMacro
	ComputeTintedReflectionMacro
	ComputeDetailBeforeReflectionBiasedMultiply
	ComputeFog
};

PixelShader PS_ReflectionMaskDetailBeforeReflectionMultiply_ps_1_1 = asm
{
	ps_1_1

	def c7, 1.0, 1.0, 1.0, 1.0
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacro
	ComputeDetailMacro
	ComputeTintedReflectionMacro
	ComputeDetailBeforeReflectionMultiply
	ComputeFog
};

PixelShader PS_ReflectionMaskDetailBeforeReflectionBiasedAdd_ps_1_1 = asm
{
	ps_1_1

	def c7, 0.5, 0.5, 0.5, 0.5
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacro
	ComputeDetailMacro
	ComputeTintedReflectionMacro
	ComputeDetailBeforeReflectionBiasedAdd
	ComputeFog
};

PixelShader	PS_ReflectionMaskDetailAfterReflectionBiasedMultiply_ps_1_1 = asm
{
	ps_1_1

	def c7, 0.5, 0.5, 0.5, 0.5
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacro
	ComputeDetailMacro
	ComputeTintedReflectionMacro
	ComputeDetailAfterReflectionBiasedMultiply
	ComputeFog
};

PixelShader	PS_ReflectionMaskDetailAfterReflectionMultiply_ps_1_1 = asm
{
	ps_1_1

	def c7, 1.0, 1.0, 1.0, 1.0
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacro
	ComputeDetailMacro
	ComputeTintedReflectionMacro
	ComputeDetailAfterReflectionMultiply
	ComputeFog
};

PixelShader PS_ReflectionMaskDetailAfterReflectionBiasedAdd_ps_1_1 = asm
{
	ps_1_1

	def c7, 0.5, 0.5, 0.5, 0.5
	
	tex t0	// base map
	tex t1	// detail map
	tex t2	// multipurpose map
	tex t3	// reflection map
	
	ComputeChangeColorMacro
	ComputeDetailMacro
	ComputeTintedReflectionMacro
	ComputeDetailAfterReflectionBiasedAdd
	ComputeFog
};
*/	

Technique ReflectionMaskInverseDetailBeforeReflectionBiasedMultiply_ps_1_1
{
	Pass P0
	{
// SetState
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
		
//		PixelShader	= (PS_ReflectionMaskInverseDetailBeforeReflectionBiasedMultiply_ps_1_1);
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
			MOV_SAT r0.a, t2.b;

			# ComputeInverseDetailMacro					
			LRP r1, r0.a, c7, t1;

			# ComputeTintedReflectionMacro				
			MUL t3, t3, v1;

			# ComputeDetailBeforeReflectionBiasedMultiply	
			MUL r0.rgb, r0, v0;
			MUL r0.rgb, t0, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
#DAJ		MUL_X2 r0.rgb, r0, r1;
			MUL r0.rgb, r0, r1;
			MUL r0.rgb, r0, two;
			MUL r0.a, t0.a, c0.a;

			# ComputeFog									
			MAD_SAT r0.rgb, r0, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique ReflectionMaskInverseDetailBeforeReflectionMultiply_ps_1_1
{
	Pass P0
	{
// SetState
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
		
//		PixelShader	= (PS_ReflectionMaskInverseDetailBeforeReflectionMultiply_ps_1_1);
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
			MOV_SAT r0.a, t2.b;

			# ComputeInverseDetailMacro					
			LRP r1, r0.a, c7, t1;

			# ComputeTintedReflectionMacro				
			MUL t3, t3, v1;

			# ComputeDetailBeforeReflectionMultiply		
			MUL r0.rgb, r0, v0;
			MUL r0.rgb, t0, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			MUL r0.rgb, r0, r1;
			MUL r0.a, t0.a, c0.a;

			# ComputeFog									
			MAD_SAT r0.rgb, r0, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique ReflectionMaskInverseDetailBeforeReflectionBiasedAdd_ps_1_1
{
	Pass P0
	{
// SetState
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
		
//		PixelShader	= (PS_ReflectionMaskInverseDetailBeforeReflectionBiasedAdd_ps_1_1);
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
			MOV_SAT r0.a, t2.b;

			# ComputeInverseDetailMacro					
			LRP r1, r0.a, c7, t1;

			# ComputeTintedReflectionMacro				
			MUL t3, t3, v1;

			# ComputeDetailBeforeReflectionBiasedAdd		
			MUL r0.rgb, r0, v0;
			MUL r0.rgb, t0, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			SUB r1_bx2, r1, half;
			MUL r1_bx2, r1_bx2, two;

			MUL r0.rgb, r0, r1_bx2;
			MUL r0.a, t0.a, c0.a;

			# ComputeFog									
			MAD_SAT r0.rgb, r0, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique ReflectionMaskInverseDetailAfterReflectionBiasedMultiply_ps_1_1
{
	Pass P0
	{
// SetState
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

//		PixelShader	= (PS_ReflectionMaskInverseDetailAfterReflectionBiasedMultiply_ps_1_1);
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
			MOV_SAT r0.a, t2.b;

			# ComputeInverseDetailMacro					
			LRP r1, r0.a, c7, t1;

			# ComputeTintedReflectionMacro				
			MUL t3, t3, v1;

			# ComputeDetailAfterReflectionBiasedMultiply	
			MUL r0.rgb, r0, v0;
#DAJ		MUL_X2 r1.rgb, t0, r1;
			MUL r1.rgb, t0, r1;
			MUL r1.rgb, r1, two;
			MUL r0.rgb, r1, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			MUL r0.a, t0.a, c0.a;

			# ComputeFog									
			MAD_SAT r0.rgb, r0, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique ReflectionMaskInverseDetailAfterReflectionMultiply_ps_1_1
{
	Pass P0
	{
// SetState
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
		
//		PixelShader	= (PS_ReflectionMaskInverseDetailAfterReflectionMultiply_ps_1_1);
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
			MOV_SAT r0.a, t2.b;

			# ComputeInverseDetailMacro					
			LRP r1, r0.a, c7, t1;

			# ComputeTintedReflectionMacro				
			MUL t3, t3, v1;

			# ComputeDetailAfterReflectionMultiply		
			MUL r0.rgb, r0, v0;
			MUL r1.rgb, t0, r1;
			MUL r0.rgb, r1, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			MUL r0.a, t0.a, c0.a;

			# ComputeFog									
			MAD_SAT r0.rgb, r0, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique ReflectionMaskInverseDetailAfterReflectionBiasedAdd_ps_1_1
{
	Pass P0
	{
// SetState
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
		
//		PixelShader	= (PS_ReflectionMaskInverseDetailAfterReflectionBiasedAdd_ps_1_1);
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
			MOV_SAT r0.a, t2.b;

			# ComputeInverseDetailMacro					
			LRP r1, r0.a, c7, t1;

			# ComputeTintedReflectionMacro				
			MUL t3, t3, v1;

			# ComputeDetailAfterReflectionBiasedAdd		
			MUL r0.rgb, r0, v0;
			SUB r1_bx2, r1, half;
			MUL r1_bx2, r1_bx2, two;

			MUL r1.rgb, t0, r1_bx2;
			MUL r0.rgb, r1, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			MUL r0.a, t0.a, c0.a;

			# ComputeFog									
			MAD_SAT r0.rgb, r0, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique ReflectionMaskDetailBeforeReflectionBiasedMultiply_ps_1_1
{
	Pass P0
	{
// SetState
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
		
//		PixelShader	= (PS_ReflectionMaskDetailBeforeReflectionBiasedMultiply_ps_1_1);
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
			MOV_SAT r0.a, t2.b;

			# ComputeDetailMacro							
			LRP r1, r0.a, t1, c7;

			# ComputeTintedReflectionMacro				
			MUL t3, t3, v1;

			# ComputeDetailBeforeReflectionBiasedMultiply	
			MUL r0.rgb, r0, v0;
			MUL r0.rgb, t0, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
#DAJ		MUL_X2 r0.rgb, r0, r1;
			MUL r0.rgb, r0, r1;
			MUL r0.rgb, r0, two;
			MUL r0.a, t0.a, c0.a;

			# ComputeFog									
			MAD_SAT r0.rgb, r0, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique ReflectionMaskDetailBeforeReflectionMultiply_ps_1_1
{
	Pass P0
	{
// SetState
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
		
//		PixelShader	= (PS_ReflectionMaskDetailBeforeReflectionMultiply_ps_1_1);
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
			MOV_SAT r0.a, t2.b;

			# ComputeDetailMacro							
			LRP r1, r0.a, t1, c7;

			# ComputeTintedReflectionMacro				
			MUL t3, t3, v1;

			# ComputeDetailBeforeReflectionMultiply		
			MUL r0.rgb, r0, v0;
			MUL r0.rgb, t0, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			MUL r0.rgb, r0, r1;
			MUL r0.a, t0.a, c0.a;

			# ComputeFog									
			MAD_SAT r0.rgb, r0, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique ReflectionMaskDetailBeforeReflectionBiasedAdd_ps_1_1
{
	Pass P0
	{
// SetState
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
		
//		PixelShader	= (PS_ReflectionMaskDetailBeforeReflectionBiasedAdd_ps_1_1);
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
			MOV_SAT r0.a, t2.b;

			# ComputeDetailMacro							
			LRP r1, r0.a, t1, c7;

			# ComputeTintedReflectionMacro				
			MUL t3, t3, v1;

			# ComputeDetailBeforeReflectionBiasedAdd		
			MUL r0.rgb, r0, v0;
			MUL r0.rgb, t0, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			SUB r1_bx2, r1, half;
			MUL r1_bx2, r1_bx2, two;

			MUL r0.rgb, r0, r1_bx2;
			MUL r0.a, t0.a, c0.a;

			# ComputeFog									
			MAD_SAT r0.rgb, r0, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique ReflectionMaskDetailAfterReflectionBiasedMultiply_ps_1_1
{
	Pass P0
	{
// SetState
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
		
//		PixelShader	= (PS_ReflectionMaskDetailAfterReflectionBiasedMultiply_ps_1_1);
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
			MOV_SAT r0.a, t2.b;

			# ComputeDetailMacro							
			LRP r1, r0.a, t1, c7;

			# ComputeTintedReflectionMacro				
			MUL t3, t3, v1;

			# ComputeDetailAfterReflectionBiasedMultiply	
			MUL r0.rgb, r0, v0;
#DAJ		MUL_X2 r1.rgb, t0, r1;
			MUL r1.rgb, t0, r1;
			MUL r1.rgb, r1, two;
			MUL r0.rgb, r1, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			MUL r0.a, t0.a, c0.a;

			# ComputeFog									
			MAD_SAT r0.rgb, r0, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique ReflectionMaskDetailAfterReflectionMultiply_ps_1_1
{
	Pass P0
	{
// SetState
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
		
//		PixelShader = (PS_ReflectionMaskDetailAfterReflectionMultiply_ps_1_1);
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
			MOV_SAT r0.a, t2.b;

			# ComputeDetailMacro							
			LRP r1, r0.a, t1, c7;

			# ComputeTintedReflectionMacro				
			MUL t3, t3, v1;

			# ComputeDetailAfterReflectionMultiply		
			MUL r0.rgb, r0, v0;
			MUL r1.rgb, t0, r1;
			MUL r0.rgb, r1, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			MUL r0.a, t0.a, c0.a;

			# ComputeFog									
			MAD_SAT r0.rgb, r0, c1.a, c3;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique ReflectionMaskDetailAfterReflectionBiasedAdd_ps_1_1
{
	Pass P0
	{
// SetState
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
		
//		PixelShader	= (PS_ReflectionMaskDetailAfterReflectionBiasedAdd_ps_1_1);
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
			MOV_SAT r0.a, t2.b;

			# ComputeDetailMacro							
			LRP r1, r0.a, t1, c7;

			# ComputeTintedReflectionMacro				
			MUL t3, t3, v1;

			# ComputeDetailAfterReflectionBiasedAdd		
			MUL r0.rgb, r0, v0;
			SUB r1_bx2, r1, half;
			MUL r1_bx2, r1_bx2, two;

			MUL r1.rgb, t0, r1_bx2;
			MUL r0.rgb, r1, r0;
			MUL r0.a, t2.b, v1.a;
			MAD r0.rgb, t3, r0.a, r0;
			MUL r0.a, t0.a, c0.a;

			# ComputeFog									
			MAD_SAT r0.rgb, r0, c1.a, c3;

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
Technique ReflectionMaskInverseDetailBeforeReflectionBiasedMultiply_ps_0_0
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

Technique ReflectionMaskInverseDetailBeforeReflectionMultiply_ps_0_0
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

Technique ReflectionMaskInverseDetailBeforeReflectionBiasedAdd_ps_0_0
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

Technique ReflectionMaskInverseDetailAfterReflectionBiasedMultiply_ps_0_0
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

Technique ReflectionMaskInverseDetailAfterReflectionMultiply_ps_0_0
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

Technique ReflectionMaskInverseDetailAfterReflectionBiasedAdd_ps_0_0
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

	Technique ReflectionMaskDetailBeforeReflectionBiasedMultiply_ps_0_0
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

	Technique ReflectionMaskDetailBeforeReflectionMultiply_ps_0_0
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

	Technique ReflectionMaskDetailBeforeReflectionBiasedAdd_ps_0_0
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

	Technique ReflectionMaskDetailAfterReflectionBiasedMultiply_ps_0_0
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

	Technique ReflectionMaskDetailAfterReflectionMultiply_ps_0_0
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

	Technique ReflectionMaskDetailAfterReflectionBiasedAdd_ps_0_0
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
