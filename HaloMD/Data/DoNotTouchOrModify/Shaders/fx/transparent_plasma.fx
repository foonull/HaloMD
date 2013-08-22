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
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 3D;
			TEX t1, f1, texture[1], 3D;
			OUTPUT oC0 = result.color;

			PARAM c6 = { 0.5, 0.5, 0.5, 0.5 };
			PARAM c7 = { 0.0, 0.0, 0.0, 0.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			PARAM four = { 4.0, 4.0, 4.0, 4.0 };

			TEMP r1_bx2, cnd;
			TEMP t0_bias, t1_bias;

			SUB t0_bias, t0, half;
			SUB t1_bias, t1, half;			
			ADD r0.rgb, t1.a, -t0_bias.a;
			ADD r0.a, t0.b, -t1_bias.b;

			MUL r0.rgb, t1, c7;				# r0.b = 0
			SUB cnd.a, r0.a, half.a;
			CMP r0.a, cnd.a, r0.a, r0.b;

			MUL r0.a, r0.a, r0.a;
			MUL r0.a, r0.a, four.a;
			
			MUL r1.rgb, r0.a, r0.a;
			SUB cnd.a, r0.a, half.a;
			CMP r1.a, cnd.a, r0.b, r0.a;

			MUL r1.rgb, r0.a, v0;
			SUB r1_bx2, r1, half;
			MUL r1_bx2, r1_bx2, two;

			MUL r1.a, r1_bx2.a, r1_bx2.a;
			
			MAD r1.rgb, r0.a, c6, r1;
			MUL r0.a, r0.a, r0.a;
			
			MUL r0.rgb, r0.a, r1;
			MOV r0.a, v0.a;

			MOV oC0, r0;	#DAJ save off
		};
 	}
}

Technique ps_0_0
{
    Pass P0
	{
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture|AlphaReplicate|Complement;
		ColorArg2[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;

		ColorOp[1]			= Modulate;
		ColorArg1[1]		= Texture;
		ColorArg2[1]		= Current;
		AlphaOp[1]			= SelectArg1;
		AlphaArg1[1]		= Diffuse;

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
