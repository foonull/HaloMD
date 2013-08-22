Texture Texture0;
Texture Texture1;
Texture Texture2;
Texture Texture3;

Technique ps_1_1
{
    Pass P0
	{
		Texture[0]			= (Texture0);

		ColorOp[0]			= Disable;
		AlphaOp[0]			= Disable;
		
 		PixelShader			= asm
 		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];	# c0 - meter gradient min color
			PARAM c1 = program.env[1];	# c1 - meter gradient max color / meter gradient color
			PARAM c2 = program.env[2];	# c2 - meter gradient max color
			PARAM c3 = program.env[3];	# c3 - meter flash color
			PARAM c4 = program.env[4];	# c4 - meter background color
			PARAM c5 = program.env[5];	# c5 - meter tint color
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			PARAM four = { 4.0, 4.0, 4.0, 4.0 };
 			TEMP r0_bx2, cnd;
 			
			MOV t0.rgb, t0.a;
			MOV t0.a, t0.b;
			
			ADD r0.rgb, c0.a, -t0;
			MUL r0.rgb, r0, four;
			
			MUL r0.a, c1.a, t0.b;
			
			ADD_SAT r1.a, r0.a, r0.a;
			MUL_SAT r1.a, r1, four;
			
			LRP r0.rgb, r1.a, c2, c0;
			SUB r0_bx2, r0, half;
			MUL r0_bx2, r0_bx2, two;

			MOV r0.a, -r0_bx2.b;
			MAD r0.rgb, r0.a, c3, r0;
			ADD r0.a, t0.b, c3.a;
			
			SUB cnd.a, r0.a, half.a;
#DAJ		CND r0.rgb, r0.a, c4, r0;
			CMP r0.rgb, cnd.a, r0, c4;
			
#DAJ		CND r0.a, r0.a, c4.a, c5.a;
			CMP r0.a, cnd.a, c5.a, c4.a;
			
			MUL r0, r0, t0.a;
			MUL r0, r0, two;

			MOV oC0, r0;	#DAJ save off
 		};
 	}
}

Technique ps_0_0
{
	Pass P0
	{
		ColorOp[0]		= Disable;
		AlphaOp[0]		= Disable;
		
		VertexShader	= Null;
		PixelShader		= Null;
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
