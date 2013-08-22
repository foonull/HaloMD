Technique ps_1_1
{
    Pass P0
	{
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

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;
			TEX t1, f1, texture[1], 2D;
			TEX t2, f2, texture[2], 2D;
			TEX t3, f3, texture[3], 2D;
			
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			PARAM c7 = { 0.5, 0.5, 0.5, 0.5 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			
			TEMP t0_bx2, t1_bx2, t2_bx2, t3_bx2;
			
			SUB t0_bx2, t0, half;			
			MUL t0_bx2, t0_bx2, two;

			SUB t1_bx2, t1, half;			
			MUL t1_bx2, t1_bx2, two;
			
			LRP r0, c0.a, t1_bx2, t0_bx2;

			SUB t2_bx2, t2, half;			
			MUL t2_bx2, t2_bx2, two;
			SUB t3_bx2, t3, half;			
			MUL t3_bx2, t3_bx2, two;
			LRP r1, c1.a, t3_bx2, t2_bx2;
			
			LRP r0, c2.a, r1, r0;
			MAD r0, r0, c7, c7;
			LRP r0, c3.a, c3, r0;

			MOV oC0, r0;	#DAJ save off
		};
 	}
}

Technique ps_0_0
{
    Pass P0
	{
		TextureFactor		= 0xFF050505;
		
		ColorOp[0]			= DotProduct3;
		ColorArg1[0]		= Texture;
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
