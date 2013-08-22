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
			TEMP  t2_bias, t0_bias, t3_bias;
			
			SUB t0_bias, t0, half;
			SUB t2_bias, t2, half;
			SUB t3_bias, t3, half;
			
#DAJ		ADD_D2 r0, t0_bias, t0_bias;	# (T0+T1-1)/2
			ADD r0, t0_bias, t0_bias;
			MUL r0, r0, half;
			
#DAJ		ADD_D2 r1, t2_bias, t3_bias;	# (T2+T3-1)/2
			ADD r1, t2_bias, t3_bias;
			MUL r1, r1, half;
			
#DAJ		ADD_D2 r0, r0, r1;			# (T0+T1+T2+T3)/4
			ADD r0, r0, r1;
			MUL r0, r0, half;
			ADD r0, r0, c7.a;
			
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
