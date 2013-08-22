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

half4 c_eye_forward;
half4 c_view_perpendicular_color;
half4 c_view_parallel_color;

half4 EnvironmentReflectionMirrorFlatSpecular(
    half4 Diff : COLOR0,
    half4 Tex0  : TEXCOORD0,
    half4 Tex1  : TEXCOORD1,
    half4 Tex2  : TEXCOORD2,
    half4 Tex3  : TEXCOORD3) : COLOR
{
	half4 T0 = tex2D(TexSampler0, Tex0);
	half4 T1 = texCUBE(TexSampler1, Tex1);
	half4 T2 = texCUBE(TexSampler2, Tex2);
	half4 T3 = tex2Dproj(TexSampler3, Tex3);
	
	half3 R0;
	half R0a;
	half3 R1;
	half R1a;
	half3 SRCCOLOR;
	half SRCALPHA;
	
	// combiner 0
	R0	= dot(((2*T1)-1),((2*T0)-1));
	R1	= T3*T3;

	saturate(R0);
	
	// combiner 1
	R0	= R0*R0;
	R1	= R1*R1;
	
	// combiner 2
	R1	= R1*R1;
	
	// combiner 3
	R0a	= lerp(c_view_parallel_color.a, c_view_perpendicular_color.a, R0.b);
	R0	= lerp(c_view_parallel_color, c_view_perpendicular_color, R0.b);
	
	// combiner 4
	R0	= lerp( R1, T3, R0 );
	
	// final combiner
	SRCCOLOR = R0*(R0a*T0);
	SRCALPHA = 1.0;
	
	return half4( SRCCOLOR, SRCALPHA );
}

Technique ps_2_0
{
    Pass P0
	{
		ColorOp[0] = Disable;
		AlphaOp[0] = Disable;
		
		PixelShader = compile PS_2_0_TARGET EnvironmentReflectionMirrorFlatSpecular();
 	}
}

PixelShader PS_EnvironmentReflectionMirrorFlatSpecular_ps_1_4 = asm
{
    #define T0 r0
    #define T0_bx2 r0_bx2
    #define T1 r1
    #define T1_bx2 r1_bx2
    #define T2 r2
    #define T3 r3
    #define R0 r4
    #define R1 r5
    #define one c0
    #define c_view_perpendicular_color c1
    #define c_view_parallel_color c2

    ps_1_4

	def one, 1, 1, 1, 1

    texld T0, t0
    texld T1, t1
    texld T2, t2
    texld T3, t3_dw.xyw

    dp3_sat R0, T1_bx2, T0_bx2
    mul R1, T3, T3
    mul_sat R0, R0, R0
    mul R1, R1, R1
    mul R1, R1, R1
    lrp_sat R0, R0.b, c_view_perpendicular_color, c_view_parallel_color
    lrp R0.rgb, R0, T3, R1
    mul r0.rgb, R0.a, R0
    + mov r0.a, one

//    #undef T0
//    #undef T0_bx2
//    #undef T1
//    #undef T1_bx2
//    #undef T2
//    #undef T3
//    #undef R0
//    #undef R1
//    #undef one
//    #undef c_view_perpendicular_color
//    #undef c_view_parallel_color
};

Technique ps_1_4
{
    Pass P0
	{
		PixelShaderConstant[0] = (c_eye_forward);
		PixelShaderConstant[1] = (c_view_perpendicular_color);
		PixelShaderConstant[2] = (c_view_parallel_color);

        Texture[0]	= (Texture0);
        Texture[1]	= (Texture1);
        Texture[2]	= (Texture2);
        Texture[3]	= (Texture3);
        
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = (PS_EnvironmentReflectionMirrorFlatSpecular_ps_1_4);
 	}
}
*/
Technique ps_1_1
{
    Pass P0
	{
		PixelShaderConstant[0] = (c_eye_forward);
		PixelShaderConstant[1] = (c_view_perpendicular_color);
		PixelShaderConstant[2] = (c_view_parallel_color);
		// KLC - Viewport bounds for RECT scaling, actually
		PixelShaderConstant[3] = (c_primary_change_color);

		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);
		
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
			
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;
			TEX t1, f1, texture[1], 2D;
			TEX t2, f2, texture[2], CUBE;
			TEX t3, f3, texture[3], CUBE;
			OUTPUT oC0 = result.color; 

			TEMP t0_bx2, t1_bx2;
			SUB t0_bx2, t0, half;			
			MUL t0_bx2, t0_bx2, two;
			SUB t1_bx2, t1, half;			
			MUL t1_bx2, t1_bx2, two;
			
			# this doesn't actually render the mirror since we cant do the divide by w on the texture coords...			
			DP3_SAT	r0, t1_bx2, t0_bx2;
			MUL r0, r0, r0;
			MOV r0.a, r0.b;
			LRP r0, c1, c2, r0.a;
			
#DAJ trying the 1.4 			
#			DP3_SAT r0, t1_bx2, t0_bx2;
#			MUL r1, t3, t3;
#			MUL_SAT r0, r0, r0;
#			MUL r1, r1, r1;
#			MUL r1, r1, r1;
#			LRP_SAT r0, r0.b, c1, c2;
#			LRP r0.rgb, r0, t3, r1;
#			MUL r0.rgb, r0.a, r0;
#			MOV r0.a, one;

			MOV     oC0, r0;	#DAJ save off
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
