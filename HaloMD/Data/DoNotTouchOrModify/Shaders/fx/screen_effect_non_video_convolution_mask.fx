Texture Texture0;
Texture Texture1;
Texture Texture2;
Texture Texture3;

Technique ps_1_1
{
    Pass P0
	{
		Texture[0]			= (Texture0);
		Texture[1]			= (Texture1);
		Texture[2]			= (Texture2);
		Texture[3]			= (Texture3);

		ColorOp[0]			= Disable;
		AlphaOp[0]			= Disable;
		
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
			TEX t3, f3, texture[3], 2D;	# reflection map
			OUTPUT oC0 = result.color;

			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM c0 = program.env[0];	# c0.a - real_alpha_to_pixel32(1.0f/3.0f);
			PARAM c1 = program.env[1];	# c1.a - parameters->filter_light_enhancement_intensity
			PARAM c2 = program.env[2];	# c2.a - parameters->filter_desaturation_intensity
			PARAM c7 = { 0.0, 0.0, 0.0, 0.5 };
			TEMP  t2_bias, t1_bias, t3_bias;
			
			SUB t1_bias, t1, half;
			SUB t2_bias, t2, half;
			SUB t3_bias, t3, half;
			ADD r0.rgb, t2_bias, t1_bias;	# T1+T2-1
			MUL r0.a, t0.b, c1.a;			# light enhancement
			MUL r1.rgb, r0, c0.a;
			MUL r1.a, t0.b, c2.a;			# desaturation enhancement
			MAD r0.rgb, t3_bias, c0.a, r1;	# (T1+T2-1)/3 + (T3-1/2)/3 == (T1+T2+T3)/3 - 1/2
			ADD r0.rgb, r0, c7.a;			# (T1+T2+T3)/3
			LRP	r0.rgb, t0.a, r0, t1;
			MOV r0.a, t0.b;

			MOV oC0, r0;	#DAJ save off
		};
 	}
}

Technique ps_0_0
{
    Pass P0
	{
		Texture[0]			= (Texture0);

		TextureFactor		= 0xFFFF0000;
		
		ColorOp[0]			= SelectArg1;
		ColorArg1[0]		= TFactor;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= TFactor;

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
