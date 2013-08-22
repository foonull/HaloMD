Technique ps_1_1
{
    Pass P0  // copy source
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;
#NVIDIA -- switch this to RECT
			TEX t0, f0, texture[0], RECT;
			TEX t1, f1, texture[1], 2D;
			OUTPUT oC0 = result.color;

			PARAM c0 = { 0.0, 0.0, 0.0, 0.75 };
			PARAM four = { 4.0, 4.0, 4.0, 4.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			TEMP cnd;
			
			MOV r0.a, t0.a;
#DAJ		CND r0.a, r0.a, r0.a, c0.b;
			SUB cnd.a, r0.a, half.a;
			CMP r0.a, cnd.a, c0.b, r0.a;
			MOV r0.rgb, r0.a;
#DAJ		MUL_X4 r0.a, t1.a, c0.a;
			MUL r0.a, t1.a, c0.a;
			MUL r0.a, r0.a, four;

			MOV     oC0, r0;	#DAJ save off
		};
 	}

    Pass P1  // convolve
	{
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
			TEX t0, f0, texture[0], 2D;
			TEX t1, f1, texture[1], 2D;
			TEX t2, f2, texture[2], 2D;
			TEX t3, f3, texture[3], 2D;
			OUTPUT oC0 = result.color;

			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM c0 = program.env[0];
			
			ADD r0.rgb, t2, t3;
			MUL r0.rgb, r0, half;
			
			ADD r0.a, t0.b, t1.b;
			MUL r0.a, r0, half;
			
			MUL r0, r0, c0.a;
			ADD r0, r0.a, r0;
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
