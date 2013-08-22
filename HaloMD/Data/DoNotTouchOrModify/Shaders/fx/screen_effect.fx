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

half4 c_desaturation_tint;
half4 c_light_enhancement;

half3 FilterTextures( half4 t0, half4 t1, half4 t2, half4 t3 )
{
	half4 r0;
	
	r0 = (t2-0.5)+(t1-0.5);
	r0 = r0*0.33333333;
	r0 = ((t3-0.5)*0.33333333)+r0;
	r0 = r0+0.5;
	r0 = lerp( t1, r0, t0.a );

	return (half3)r0;
}

///////////////////////////////////////////////////////////////////////////////
// Pixel Shader 2.0 shaders
///////////////////////////////////////////////////////////////////////////////
half4 VideoOffFilter(
    half4 Diff : COLOR0,
    half2 Tex0  : TEXCOORD0,
    half2 Tex1  : TEXCOORD1,
    half2 Tex2  : TEXCOORD2,
    half2 Tex3  : TEXCOORD3,
    uniform bool bUseConvolutionMask,
    uniform bool bLightUsesConvolution,
    uniform bool bDesaturationUsesConvolution) : COLOR
{
	half4 T0 = tex2D(TexSampler0, Tex0);
	half4 T1 = tex2D(TexSampler1, Tex1);
	half4 T2 = tex2D(TexSampler2, Tex2);
	half4 T3 = tex2D(TexSampler3, Tex3);
	
	half3 R0	= FilterTextures(T0,T1,T2,T3);
	half  R0a	= bLightUsesConvolution ? c_light_enhancement.a * -((2*T0.b)-1) : c_light_enhancement.a;
	half3 R1	= c_light_enhancement.a ? pow(1-R0,4) : R0;
	half  R1a	= bDesaturationUsesConvolution ? c_desaturation_tint.a * -((2*T0.b)-1) : c_desaturation_tint.a;

	// Boy this hurts.
	R0	= c_desaturation_tint.a ? (c_light_enhancement.a ? lerp( R0, 1-R1, R0a) : R0) : R0;
	
	R1	= dot( R0, 0.33333333 );
	
	half3	SRCCOLOR = ((c_desaturation_tint * R1) * R1a) + R0;
	half	SRCALPHA = bLightUsesConvolution ? T0.b : 0.0;
	
	return half4( SRCCOLOR, SRCALPHA );
}

Technique VideoOffConvolvedMaskFilterLightAndDesaturation_ps_2_0
{
    Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = compile PS_2_0_TARGET VideoOffFilter( true, true, true );
 	}
}

Technique VideoOffConvolvedMaskFilterLight_ps_2_0
{
    Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = compile PS_2_0_TARGET VideoOffFilter( true, true, false );
 	}
}

Technique VideoOffConvolvedMaskFilterDesaturation_ps_2_0
{
    Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = compile PS_2_0_TARGET VideoOffFilter( true, true, true );
 	}
}

Technique VideoOffConvolvedFilterLightAndDesaturation_ps_2_0
{
    Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = compile PS_2_0_TARGET VideoOffFilter( false, false, true );
 	}
}

Technique VideoOffConvolvedFilterLight_ps_2_0
{
    Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = compile PS_2_0_TARGET VideoOffFilter( false, false, false );
 	}
}

Technique VideoOffConvolvedFilterDesaturation_ps_2_0
{
    Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = compile PS_2_0_TARGET VideoOffFilter( false, false, true );
 	}
}
*/
///////////////////////////////////////////////////////////////////////////////
// Pixel Shader 1.1 shaders
///////////////////////////////////////////////////////////////////////////////
/* DAJ
PixelShader PixelShaderNonConvolved_ps_1_1 = asm
{
	ps_1_1
	
	tex t0
	
	mov r0.rgb, t0
	+ mov r0.a, c0.a
};

PixelShader PixelShaderNonConvolvedPassThrough_ps_1_1 = asm
{
	ps_1_1
	
	tex t0
	
	mov r0.rgb, t0
	+ mov r0.a, t0.b
};

PixelShader PixelShaderNonConvolvedMask_ps_1_1 = asm
{
	ps_1_1
	
	tex t0
	tex t1
	
	mov r0.rgb, t1
	+ mov r0.a, t0.b
};
*/
//DAJ FIXME //ееееее do the rest of these need to be changed to be RECT instead of 2D textures?
Technique VideoOn_ps_1_1
{
	Pass P0
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);

		Texture[0]	= (Texture0);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], RECT;
			OUTPUT oC0 = result.color;
			
			MOV oC0, t0;	#DAJ save off
		};
	}
	
    Pass P1
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);

		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);
		Texture[2]	= (Texture2);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2;
			TEX t0, f0, texture[0], RECT;	# screen
			TEX t1, f1, texture[1], 2D;	# scanline
			TEX t2, f2, texture[2], 2D;	# noise
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];
			PARAM c2 = { 1.0, 1.0, 1.0, 1.0 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			
			LRP r1, c0.a, t2, c2;
			MUL_SAT t1, r1, t1;
			MUL r0, t0, t0;
			MUL r0, r0, r0;
			MUL r0, r0, c0;
			MUL r1, t0, c0;
			LRP r0.rgb, t1, r1, r0;
			MUL r0.rgb, r0, two;

			MOV oC0, r0;	#DAJ save off
		};
 	}
}

Technique VideoOffNonConvolved_ps_1_1
{
	Pass P0
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);
		PixelShaderConstant[1]	= (c_light_enhancement);
		
		Texture[0]	= (Texture0);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
//		PixelShader	= (PixelShaderNonConvolvedPassThrough_ps_1_1);
		PixelShader			= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], RECT;
			OUTPUT oC0 = result.color;
			
			MOV r0.rgb, t0;
			MOV r0.a, t0.b;

			MOV oC0, r0;	#DAJ save off
		};
	}

	Pass P1
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);
		PixelShaderConstant[1]	= (c_light_enhancement);
		
		Texture[0]	= (Texture0);
		
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
//		PixelShader	= (PixelShaderNonConvolved_ps_1_1);
		PixelShader			= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], RECT;
			OUTPUT oC0 = result.color;
			
			MOV r0.rgb, t0;
			MOV r0.a, t0.a;

			MOV oC0, r0;	#DAJ save off
		};
	}

	Pass P2
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);
		PixelShaderConstant[1]	= (c_light_enhancement);
		
		Texture[0]	= (Texture0);
		
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
//		PixelShader	= (PixelShaderNonConvolvedMask_ps_1_1);
		PixelShader			= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], RECT;
			TEX t1, f1, texture[1], RECT;
			OUTPUT oC0 = result.color;
			
			MOV r0.rgb, t1;
			MOV r0.a, t0.b;

			MOV oC0, r0;	#DAJ save off
		};
	}
}


Technique VideoOffConvolvedMaskThreeStage_ps_1_1
{
    Pass P0
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);
		PixelShaderConstant[1]	= (c_light_enhancement);
		
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D; # convolution mask
			TEX t1, f1, texture[1], RECT; # backbuffer on even passes, offscreen surface on odd passes
			TEX t3, f3, texture[1], RECT; # backbuffer on even passes, offscreen surface on odd passes
			OUTPUT oC0 = result.color;

			PARAM c0 = { 0.3333333333333333, 0.3333333333333333, 0.3333333333333333, 0.5 };
			PARAM c1 = { 0.1, 0.1, 0.1, 0.1	};
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			TEMP  t1_bias, t3_bias;
			
			# even passes render to offscreen surface
			# odd passes render to backbuffer
			
			SUB t1_bias, t1, half;
			SUB t3_bias, t3, half;
			
			ADD r0.rgb, t1_bias, t1_bias;		# (T1+T2-1)
			MUL r0.rgb, r0, c0;					# (T1+T2-1)/3
			MAD r0.rgb, t3_bias, c0, r0;		# (T1+T2-1)/3 + (T3-1/2)/3 == (T1+T2+T3)/3 - 1/2
			ADD r0.rgb, r0, c0.a;				# (T1+T2+T3)/3
			LRP r0.rgb, t0.a, r0, t1;			# (1-T0a)*T1 + T0a*(T1+T2+T3)/3
			MOV r0.a, t0.b;

			MOV oC0, r0;	#DAJ save off
		};
 	}
}

Technique VideoOffConvolvedMask_ps_1_1
{
    Pass P0
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);
		PixelShaderConstant[1]	= (c_light_enhancement);
		
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);

		AddressU[1]	= Clamp;
		AddressV[1]	= Clamp;

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

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D; # convolution mask
			TEX t1, f1, texture[1], RECT; # backbuffer on even passes, offscreen surface on odd passes
			TEX t2, f2, texture[1], RECT; # backbuffer on even passes, offscreen surface on odd passes
			TEX t3, f3, texture[1], RECT; # backbuffer on even passes, offscreen surface on odd passes

			OUTPUT oC0 = result.color;

			PARAM c0 = { 0.3333333333333333, 0.3333333333333333, 0.3333333333333333, 0.5 };
			PARAM c1 = { 0.1, 0.1, 0.1, 0.1	};
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			TEMP  t1_bias, t2_bias, t3_bias;
			
			# even passes render to offscreen surface
			# odd passes render to backbuffer
			
			SUB t1_bias, t1, half;
			SUB t2_bias, t2, half;
			SUB t3_bias, t3, half;
			
			ADD r0.rgb, t1_bias, t2_bias;		# (T1+T2-1)
			MUL r0.rgb, r0, c0;					# (T1+T2-1)/3
			MAD r0.rgb, t3_bias, c0, r0;		# (T1+T2-1)/3 + (T3-1/2)/3 == (T1+T2+T3)/3 - 1/2
			ADD r0.rgb, r0, c0.a;				# (T1+T2+T3)/3
			LRP r0.rgb, t0.a, r0, t1;			# (1-T0a)*T1 + T0a*(T1+T2+T3)/3
			MOV r0.a, t0.b;

			MOV oC0, r0;	#DAJ save off
		};
 	}
}

Technique VideoOffConvolvedMaskFilterLightAndDesaturation_ps_1_1
{
    Pass P0
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);
		PixelShaderConstant[1]	= (c_light_enhancement);
		
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1;
			TEX t0, f0, texture[0], RECT;
			TEX t1, f1, texture[1], RECT;
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c7 = { 0.33333333, 0.33333333, 0.33333333, 0.5 };
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			PARAM four = { 4.0, 4.0, 4.0, 4.0 };

			TEMP t0_bx2, t1_bx2, oneminus, cnd;
			SUB t0_bx2, t0, half;			
MUL t0_bx2, t0_bx2, two;


			# calculate light enhancement
			MUL_SAT r0.rgb, t0, t1;
			ADD_SAT r0.a, c1.a, c7;
			
			MUL_SAT r1.rgb, r0, r0;
			MUL_SAT r1.a, c1.a, -t0_bx2.b;
			
#DAJ		CND_SAT r0.rgb, r0.a, 1-r1, r0;
			SUB oneminus, one, r1;
			SUB cnd.a, r0.a, half.a;
			CMP_SAT r0.rgb, cnd.a, r0, oneminus;
			ADD_SAT r0.a, c0.a, c7;	
			
#DAJ		LRP_SAT r1.rgb, r1.a, t1, 1-r0;
			SUB oneminus, one, r0;
			LRP_SAT r1.rgb, r1.a, t1, oneminus;
			MUL_SAT r1.a, c0.a, -t0_bx2.b;

#DAJ		CND_SAT r1.rgb, r0.a, r1, t1;
			SUB cnd.a, r0.a, half.a;
			CMP_SAT r1.rgb, cnd.a, t1, r1;

			DP3_SAT r0.rgb, c7, r1;

			MUL_SAT r0.rgb, c0, r0;
			MUL_SAT r0.rgb, r0, four;
			
			MAD_SAT r0.rgb, r0, r1.a, r1;
			MOV_SAT r0.a, t0.b;

			MOV oC0, r0;	#DAJ save off
		};
	}
}

Technique VideoOffConvolvedMaskFilterLightAndDesaturation_ps_1_4
{
	Pass P0
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);
		PixelShaderConstant[1]	= (c_light_enhancement);
		
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP t0, t1, t2, t3, t4, t5, t6, t7, tmp0, tmp1, tmp2, r0, r1, r2, r3;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			ATTRIB tc0 = fragment.texcoord[0];
			ATTRIB tc1 = fragment.texcoord[1];
			OUTPUT oC0 = result.color;
			PARAM c6 = {1.000000, 1.000000, 1.000000, 1.000000};
			PARAM c7 = {0.333333, 0.333333, 0.333333, 0.500000};
			PARAM color = {1.0, 0.0, 0.0, 1.0};
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			MUL_SAT r2.rgb, r0, r1;
			ADD_SAT r2.a, c1.a, c7;
			MUL_SAT r3.rgb, r2, r2;
			MAD tmp1, r0, mulConst.r, -const.b;
			MUL_SAT r3.a, c1.a, -tmp1;
			SUB tmp1, const.b, r3;
			SUB tmp2, r2.a, const.g;
			
			#CND_SAT r2.rgb, -tmp2.a, tmp1, r2;
			SUB t0.a, -tmp2.a, const.g;
			CMP_SAT r2.rgb, t0.a, r2, tmp1;
			
			ADD_SAT r2.a, c0.a, c7;
			SUB tmp1, const.b, r2;
			LRP_SAT r3.rgb, r3.a, r1, tmp1;
			MAD tmp1, r0, mulConst.r, -const.b;
			MUL_SAT r3.a, c0.a, -tmp1;
			SUB tmp2, r2.a, const.g;
			CMP_SAT r3.rgb, tmp2.a, r3, r1;
			DP3_SAT r2.rgb, c7, r3;
			MUL r2.rgb, c0, r2;
			MUL r2.rgb, r2, mulConst.g;
			MAD_SAT r2.rgb, r2, r3.a, r3;
			MOV_SAT r0.a, r0.b;
			MOV r0.rgb, r2;
			
			#MOV r0, color;
			
			MOV oC0, r0;
		};
	}
}

Technique VideoOffConvolvedMaskFilterLight_ps_1_1
{
    Pass P0
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);
		PixelShaderConstant[1]	= (c_light_enhancement);
		
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1;
			TEX t0, f0, texture[0], RECT;
			TEX t1, f1, texture[1], RECT;
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c7 = { 0.33333333, 0.33333333, 0.33333333, 0.5 };
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			PARAM four = { 4.0, 4.0, 4.0, 4.0 };

			TEMP t0_bx2, t1_bx2, oneminus, cnd;
			SUB t0_bx2, t0, half;			
MUL t0_bx2, t0_bx2, two;


			# calculate light enhancement
			MUL_SAT r0.rgb, t0, t1;
			ADD_SAT r0.a, c1.a, c7;
			MUL_SAT r1.rgb, r0, r0;
			MUL_SAT r1.a, c1.a, -t0_bx2.b;

#DAJ		CND_SAT r0.rgb, r0.a, 1-r1, r0;
			SUB oneminus, one, r1;
			SUB cnd.a, r0.a, half.a;
			CMP_SAT r0.rgb, cnd.a, r0, oneminus;
			ADD_SAT r0.a, c0.a, c7;

#DAJ		LRP_SAT r1.rgb, r1.a, t1, 1-r0;
			SUB oneminus, one, r0;
			LRP_SAT r1.rgb, r1.a, t1, oneminus;
			MOV_SAT r1.a, c0.a;
#DAJ		CND_SAT r1.rgb, r0.a, r1, t1;
			SUB cnd.a, r0.a, half.a;
			CMP_SAT r1.rgb, cnd.a, t1, r1;

			DP3_SAT r0.rgb, c7, r1;

			MUL_SAT r0.rgb, c0, r0;
			MUL_SAT r0.rgb, r0, four;
			
			MAD_SAT r0.rgb, r0, r1.a, r1;
			MOV_SAT r0.a, t0.b;

			MOV oC0, r0;	#DAJ save off
		};
	}
}
/*
Technique VideoOffConvolvedMaskFilterLight_ps_1_4
{
	Pass P0
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);
		PixelShaderConstant[1]	= (c_light_enhancement);
		
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);
		Texture[2]	= (Texture1);
		Texture[3]	= (Texture1);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			ps_1_4

			def c6, 1.0, 1.0, 1.0, 1.0
			def c7, 0.33333333, 0.33333333, 0.33333333, 0.5

			texld r0, t0
			texld r1, t1
//			texld r4, t2
//			texld r5, t3

			// calculate light enhancement
			mul_sat r2.rgb, r0, r1			// pow(1-filter_color_base,4), part 1
			+ add_sat r2.a, c1.a, c7		// add 0.5 so we can perform nonzero check "c_light_enhancement.a ? pow(1-filter_color_base,4) : filter_color_base"

			mul_sat r3.rgb, r2, r2			// pow(1-filter_color_base,4), part 2
			+ mul_sat r3.a, c1.a, -r0_bx2	// half light_enhancement_intensity = bLightUsesConvolution ? c_light_enhancement.a * -((2*t0.b)-1) : c_light_enhancement.a;

			cnd_sat r2.rgb, r2.a, 1-r3, r2	// half3 filter_color_enhanced = c_light_enhancement.a ? pow(1-filter_color_base,4) : filter_color_base;
			+ add_sat r2.a, c0.a, c7		// add 0.5 so we can perform nonzero check "c_desaturation_tint.a ? lerp( filter_color_base, 1-filter_color_enhanced, light_enhancement_intensity) : filter_color_base;"

			// filter_color_base = c_desaturation_tint.a ? lerp( filter_color_base, 1-filter_color_enhanced, light_enhancement_intensity) : filter_color_base;
			lrp_sat r3.rgb, r3.a, r1, 1-r2
			+ mov_sat r3.a, c0.a			//half desaturation_intensity = bDesaturationUsesConvolution ? c_desaturation_tint.a * -((2*t0.b)-1) : c_desaturation_tint.a;

			cnd_sat r3.rgb, r2.a, r3, r1

			dp3_sat r2.rgb, c7, r3

			mul_x4_sat r2.rgb, c0, r2
			
			mad_sat r2.rgb, r2, r3.a, r3

			phase

			mov_sat r0.a, r0.b
			mov r0.rgb, r2
		};
	}
}
*/
Technique VideoOffConvolvedMaskFilterLight_ps_1_4
{
	Pass P0
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);
		PixelShaderConstant[1]	= (c_light_enhancement);
		
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP t0, t1, t2, t3, t4, t5, t6, t7, tmp0, tmp1, tmp2, r0, r1, r2, r3;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			ATTRIB tc0 = fragment.texcoord[0];
			ATTRIB tc1 = fragment.texcoord[1];
			OUTPUT oC0 = result.color;
			PARAM c6 = {1.000000, 1.000000, 1.000000, 1.000000};
			PARAM c7 = {0.333333, 0.333333, 0.333333, 0.500000};
			PARAM color = {1.0, 0.0, 0.0, 1.0};
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			MUL_SAT r2.rgb, r0, r1;
			ADD_SAT r2.a, c1.a, c7;
			MUL_SAT r3.rgb, r2, r2;
			MAD tmp1, r0, mulConst.r, -const.b;
			MUL_SAT r3.a, c1.a, -tmp1;
			SUB tmp1, const.b, r3;
			SUB tmp2, r2.a, const.g;
			CMP_SAT r2.rgb, tmp2.a, tmp1, r2;
			ADD_SAT r2.a, c0.a, c7;
			SUB tmp1, const.b, r2;
			LRP_SAT r3.rgb, r3.a, r1, tmp1;
			MOV_SAT r3.a, c0.a;
			SUB tmp1, r2.a, const.g;
			CMP_SAT r3.rgb, tmp1.a, r3, r1;
			DP3_SAT r2.rgb, c7, r3;
			MUL r2.rgb, c0, r2;
			MUL r2.rgb, r2, mulConst.g;
			MAD_SAT r2.rgb, r2, r3.a, r3;
			MOV_SAT r0.a, r0.b;
			MOV r0.rgb, r2;
			MOV oC0, r0;
		};
	}
}
Technique VideoOffConvolvedMaskFilterDesaturation_ps_1_1
{
    Pass P0
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);
		PixelShaderConstant[1]	= (c_light_enhancement);
		
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1;
			TEX t0, f0, texture[0], 2D; #NOT RECT;
			TEX t1, f1, texture[1], RECT;
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c7 = { 0.33333333, 0.33333333, 0.33333333, 0.5 };
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			PARAM four = { 4.0, 4.0, 4.0, 4.0 };

			TEMP t0_bx2, t1_bx2, oneminus, cnd;

#			MOV r0.rgb, t1;
#			MOV r0.a, t0.b;
#TEST
			# calculate light enhancement
			MUL_SAT r0.rgb, t0, t1;
			ADD_SAT r0.a, c1.a, c7;

			MUL_SAT r1.rgb, r0, r0;
			MOV_SAT r1.a, c1.a;

#DAJ		CND_SAT r0.rgb, r0.a, 1-r1, r0;
			SUB oneminus, one, r1;
			SUB cnd.a, r0.a, half.a;
			CMP_SAT r0.rgb, cnd.a, r0, oneminus;
			ADD_SAT r0.a, c0.a, c7;	

#DAJ		LRP_SAT r1.rgb, r1.a, t1, 1-r0;
			SUB oneminus, one, r0;
			LRP_SAT r1.rgb, r1.a, t1, oneminus;
			
			SUB t0_bx2, t0, half;			
			MUL t0_bx2, t0_bx2, two;
			MUL_SAT r1.a, c0.a, -t0_bx2.b;

#DAJ		CND_SAT r1.rgb, r0.a, r1, t1;
			SUB cnd.a, r0.a, half.a;
			CMP_SAT r1.rgb, cnd.a, t1, r1;

			DP3_SAT r0.rgb, c7, r1;

#DAJ		mul_x4_sat r0.rgb, c0, r0
			MUL_SAT r0.rgb, c0, r0;
			MUL_SAT r0.rgb, r0, four;
			
			MAD_SAT r0.rgb, r0, r1.a, r1;
			MOV_SAT r0.a, t0.b;

			MOV oC0, r0;	#DAJ save off
		};
	}
}
/*
Technique VideoOffConvolvedMaskFilterDesaturation_ps_1_4
{
	Pass P0
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);
		PixelShaderConstant[1]	= (c_light_enhancement);
		
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);
		Texture[2]	= (Texture1);
		Texture[3]	= (Texture1);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			ps_1_4

			def c6, 1.0, 1.0, 1.0, 1.0
			def c7, 0.33333333, 0.33333333, 0.33333333, 0.5

			texld r0, t0
			texld r1, t1
//			texld r4, t2
//			texld r5, t3

			// calculate light enhancement
			mul_sat r2.rgb, r0, r1			// pow(1-filter_color_base,4), part 1
			+ add_sat r2.a, c1.a, c7		// add 0.5 so we can perform nonzero check "c_light_enhancement.a ? pow(1-filter_color_base,4) : filter_color_base"

			mul_sat r3.rgb, r2, r2			// pow(1-filter_color_base,4), part 2
			+ mov_sat r3.a, c1.a			// half light_enhancement_intensity = bLightUsesConvolution ? c_light_enhancement.a * -((2*t0.b)-1) : c_light_enhancement.a;

			cnd_sat r2.rgb, r2.a, 1-r3, r2	// half3 filter_color_enhanced = c_light_enhancement.a ? pow(1-filter_color_base,4) : filter_color_base;
			+ add_sat r2.a, c0.a, c7		// add 0.5 so we can perform nonzero check "c_desaturation_tint.a ? lerp( filter_color_base, 1-filter_color_enhanced, light_enhancement_intensity) : filter_color_base;"

			// filter_color_base = c_desaturation_tint.a ? lerp( filter_color_base, 1-filter_color_enhanced, light_enhancement_intensity) : filter_color_base;
			lrp_sat r3.rgb, r3.a, r1, 1-r2
			+ mul_sat r3.a, c0.a, -r0_bx2.b	//half desaturation_intensity = bDesaturationUsesConvolution ? c_desaturation_tint.a * -((2*t0.b)-1) : c_desaturation_tint.a;

			cnd_sat r3.rgb, r2.a, r3, r1

			dp3_sat r2.rgb, c7, r3

			mul_x4_sat r2.rgb, c0, r2
			
			mad_sat r2.rgb, r2, r3.a, r3

			phase

			mov_sat r0.a, r0.b
			mov r0.rgb, r2
		};
	}
}
*/
Technique VideoOffConvolvedMaskFilterDesaturation_ps_1_4
{
	Pass P0
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);
		PixelShaderConstant[1]	= (c_light_enhancement);
		
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP t0, t1, t2, t3, t4, t5, t6, t7, tmp0, tmp1, tmp2, r0, r1, r2, r3;

			PARAM c6 = {1.000000, 1.000000, 1.000000, 1.000000};
			PARAM c7 = {0.333333, 0.333333, 0.333333, 0.500000};

			ATTRIB tc0 = fragment.texcoord[0];
			ATTRIB tc1 = fragment.texcoord[1];
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], RECT;

			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			OUTPUT oC0 = result.color;

			# calculate light enhancement
			MUL_SAT r2.rgb, r0, r1;
			ADD_SAT r2.a, c1.a, c7;

			MUL_SAT r3.rgb, r2, r2;
			MOV_SAT r3.a, c1.a;

			SUB tmp1, const.b, r3;
			SUB tmp2, r2.a, const.g;
			CMP_SAT r2.rgb, tmp2.a, tmp1, r2;
			ADD_SAT r2.a, c0.a, c7;
			
			# filter_color_base = c_desaturation_tint.a ? 
			# lerp( filter_color_base, 1-filter_color_enhanced, light_enhancement_intensity) : filter_color_base
			SUB tmp1, const.b, r2;
			LRP_SAT r3.rgb, r3.a, r1, tmp1;
			MAD tmp1, r0, mulConst.r, -const.b;
			MUL_SAT r3.a, c0.a, -tmp1.b;

			SUB tmp1, r2.a, const.g;
			CMP_SAT r3.rgb, tmp1.a, r3, r1;

			DP3_SAT r2.rgb, c7, r3;
			MUL r2.rgb, c0, r2;
			MUL r2.rgb, r2, mulConst.g;

			MAD_SAT r2.rgb, r2, r3.a, r3;

			MOV_SAT r0.a, r0.b;

			MOV r0.rgb, r2;			
			MOV oC0, r0;
		};
	}
}

Technique VideoOffConvolved_ps_1_1
{
    Pass P0
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);
		PixelShaderConstant[1]	= (c_light_enhancement);
		
		Texture[0]	= (Texture0);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], RECT;
			TEX t1, f1, texture[0], RECT;
			TEX t2, f2, texture[0], RECT;
			TEX t3, f3, texture[0], RECT;
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];
			PARAM c7 = { 0.0, 0.0, 0.0, 0.5 };
			
#			ADD_D2 r0, t0_bias, t1_bias;			# (T0+T1-1)/2
#			ADD_D2 r1, t2_bias, t3_bias;			# (T2+T3-1)/2			
#			ADD_D2 r0, r0, r1;						# (T0+T1+T2+T3)/4

# KLC - Since all they want to do is average the four texels, then do it
#       simply without all the bias and dividing junk.

			PARAM divByFour = { 0.25, 0.25, 0.25, 0.25 };
			ADD r0, t0, t1;
			ADD r0, r0, t2;
			ADD r0, r0, t3;
			MUL oC0.rgb, r0, divByFour;
			MUL oC0.a, c0.a, c7.b;
		};
 	}
}

Technique VideoOffConvolvedFilterLightAndDesaturation_ps_1_1
{
    Pass P0
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);
		PixelShaderConstant[1]	= (c_light_enhancement);
		
		Texture[0]	= (Texture0);

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

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], RECT;
			TEX t1, f1, texture[0], RECT;
			TEX t2, f2, texture[0], RECT;
			TEX t3, f3, texture[0], RECT;
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];
			PARAM c7 = { 0.0, 0.0, 0.0, 0.5 };

#			ADD_D2 r0, t0_bias, t1_bias;			# (T0+T1-1)/2
#			ADD_D2 r1, t2_bias, t3_bias;			# (T2+T3-1)/2			
#			ADD_D2 r0, r0, r1;						# (T0+T1+T2+T3)/4

# KLC - Since all they want to do is average the four texels, then do it
#       simply without all the bias and dividing junk.

			PARAM divByFour = { 0.25, 0.25, 0.25, 0.25 };
			ADD r0, t0, t1;
			ADD r0, r0, t2;
			ADD r0, r0, t3;
			MUL oC0.rgb, r0, divByFour;
			MUL oC0.a, c0.a, c7.b;
		};
 	}
}

Technique VideoOffConvolvedFilterLight_ps_1_1
{
    Pass P0
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);
		PixelShaderConstant[1]	= (c_light_enhancement);
		
		Texture[0]	= (Texture0);

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

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], RECT;
			TEX t1, f1, texture[0], RECT;
			TEX t2, f2, texture[0], RECT;
			TEX t3, f3, texture[0], RECT;
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];
			PARAM c7 = { 0.0, 0.0, 0.0, 0.5 };

#			ADD_D2 r0, t0_bias, t1_bias;			# (T0+T1-1)/2
#			ADD_D2 r1, t2_bias, t3_bias;			# (T2+T3-1)/2			
#			ADD_D2 r0, r0, r1;						# (T0+T1+T2+T3)/4

# KLC - Since all they want to do is average the four texels, then do it
#       simply without all the bias and dividing junk.

			PARAM divByFour = { 0.25, 0.25, 0.25, 0.25 };
			ADD r0, t0, t1;
			ADD r0, r0, t2;
			ADD r0, r0, t3;
			MUL oC0.rgb, r0, divByFour;
			MUL oC0.a, c0.a, c7.b;
		};
 	}
}

Technique VideoOffConvolvedFilterDesaturation_ps_1_1
{
    Pass P0
	{
		PixelShaderConstant[0]	= (c_desaturation_tint);
		PixelShaderConstant[1]	= (c_light_enhancement);
		
		Texture[0]	= (Texture0);

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

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], RECT;
			TEX t1, f1, texture[0], RECT;
			TEX t2, f2, texture[0], RECT;
			TEX t3, f3, texture[0], RECT;
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];
			PARAM c7 = { 0.0, 0.0, 0.0, 0.5 };

#			ADD_D2 r0, t0_bias, t1_bias;			# (T0+T1-1)/2
#			ADD_D2 r1, t2_bias, t3_bias;			# (T2+T3-1)/2			
#			ADD_D2 r0, r0, r1;						# (T0+T1+T2+T3)/4

# KLC - Since all they want to do is average the four texels, then do it
#       simply without all the bias and dividing junk.

			PARAM divByFour = { 0.25, 0.25, 0.25, 0.25 };
			ADD r0, t0, t1;
			ADD r0, r0, t2;
			ADD r0, r0, t3;
			MUL oC0.rgb, r0, divByFour;
			MUL oC0.a, c0.a, c7.b;
		};
 	}
}

///////////////////////////////////////////////////////////////////////////////
// Fixed Function shaders
///////////////////////////////////////////////////////////////////////////////
Technique VideoOn_ps_0_0
{
	Pass P0
	{
	}
}

Technique VideoOffNonConvolved_ps_0_0
{
	Pass P0
	{
		TextureFactor	= 0xFFFF0000;
		
		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= TFactor;
		AlphaOp[0]		= SelectArg1;
		AlphaArg1[0]	= TFactor;

		ColorOp[1]	= Disable;
		AlphaOp[1]	= Disable;

		PixelShader	= Null;
	}

	Pass P1
	{
		TextureFactor	= 0xFFFF0000;
		
		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= TFactor;
		AlphaOp[0]		= SelectArg1;
		AlphaArg1[0]	= TFactor;

		ColorOp[1]	= Disable;
		AlphaOp[1]	= Disable;

		PixelShader	= Null;
	}

	Pass P2
	{
		TextureFactor	= 0xFFFF0000;
		
		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= TFactor;
		AlphaOp[0]		= SelectArg1;
		AlphaArg1[0]	= TFactor;

		ColorOp[1]	= Disable;
		AlphaOp[1]	= Disable;

		PixelShader	= Null;
	}
}

Technique VideoOffConvolvedMask_ps_0_0
{
    Pass P0
	{
		Texture[0]	= (Texture0);

		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= Texture;
		AlphaOp[0]		= SelectArg1;
		AlphaArg1[0]	= Texture;

		ColorOp[1]	= Disable;
		AlphaOp[1]	= Disable;

		PixelShader	= Null;
 	}
}

Technique VideoOffConvolvedMaskThreeStage_ps_0_0
{
    Pass P0
	{
		Texture[0]	= (Texture0);

		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= Texture;
		AlphaOp[0]		= SelectArg1;
		AlphaArg1[0]	= Texture;

		ColorOp[1]	= Disable;
		AlphaOp[1]	= Disable;

		PixelShader	= Null;
 	}
}

Technique VideoOffConvolvedMaskFilterLightAndDesaturation_ps_0_0
{
    Pass P0
	{
		Texture[0]	= (Texture0);

		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= Texture;
		AlphaOp[0]		= SelectArg1;
		AlphaArg1[0]	= Texture;

		ColorOp[1]	= Disable;
		AlphaOp[1]	= Disable;

		PixelShader	= Null;
 	}
}

Technique VideoOffConvolvedMaskFilterLight_ps_0_0
{
    Pass P0
	{
		Texture[0]	= (Texture0);

		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= Texture;
		AlphaOp[0]		= SelectArg1;
		AlphaArg1[0]	= Texture;

		ColorOp[1]	= Disable;
		AlphaOp[1]	= Disable;

		PixelShader	= Null;
 	}
}

Technique VideoOffConvolvedMaskFilterDesaturation_ps_0_0
{
    Pass P0
	{
		Texture[0]	= (Texture0);

		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= Texture;
		AlphaOp[0]		= SelectArg1;
		AlphaArg1[0]	= Texture;

		ColorOp[1]	= Disable;
		AlphaOp[1]	= Disable;

		PixelShader	= Null;
 	}
}

Technique VideoOffConvolved_ps_0_0
{
    Pass P0
	{
		Texture[0]	= (Texture0);

		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= Texture;
		AlphaOp[0]		= SelectArg1;
		AlphaArg1[0]	= Texture;

		ColorOp[1]	= Disable;
		AlphaOp[1]	= Disable;

		PixelShader	= Null;
 	}
}

Technique VideoOffConvolvedFilterLightAndDesaturation_ps_0_0
{
    Pass P0
	{
		Texture[0]	= (Texture0);

		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= Texture;
		AlphaOp[0]		= SelectArg1;
		AlphaArg1[0]	= Texture;

		ColorOp[1]	= Disable;
		AlphaOp[1]	= Disable;

		PixelShader	= Null;
 	}
}

Technique VideoOffConvolvedFilterLight_ps_0_0
{
    Pass P0
	{
		Texture[0]	= (Texture0);

		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= Texture;
		AlphaOp[0]		= SelectArg1;
		AlphaArg1[0]	= Texture;

		ColorOp[1]	= Disable;
		AlphaOp[1]	= Disable;

		PixelShader	= Null;
 	}
}

Technique VideoOffConvolvedFilterDesaturation_ps_0_0
{
    Pass P0
	{
		Texture[0]	= (Texture0);

		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= Texture;
		AlphaOp[0]		= SelectArg1;
		AlphaArg1[0]	= Texture;

		ColorOp[1]	= Disable;
		AlphaOp[1]	= Disable;

		PixelShader	= Null;
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
