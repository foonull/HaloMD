Texture	Texture0;
Texture	Texture1;
Texture	Texture2; 
Texture	Texture3;

Technique ps_1_1
{
    Pass P0 // no specular mask
	{
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);
		Texture[3]	= (Texture3);
		
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t3;
			TEX t0, f0, texture[0], 2D;
			TEX t1, f1, texture[1], CUBE;
			TEX t3, f3, texture[3], CUBE;
			OUTPUT oC0 = result.color;

			PARAM c1 = program.env[12];
			PARAM c2 = program.env[13];
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			
			TEMP t0_bx2, t1_bx2;

			ADD t1_bx2, t1, -half;			
			MUL t1_bx2, t1_bx2, two;
			ADD t0_bx2, t0, -half;			
			MUL t0_bx2, t0_bx2, two;
			
			DP3_SAT r0, t1_bx2, t0_bx2;
			MUL_SAT r1.rgb, t3, t3;
			MOV r1.a, r0.b;
			MUL_SAT r1, r1, r1;
			MUL_SAT r1, r1, r1;
			LRP r0, r1.a, c1, c2;
			LRP r0.rgb, r0, t3, r1;
			MUL_SAT r1.rgb, r0.a, v0.a;
			MUL_SAT r0.rgb, r0, r1;

			MOV oC0, r0;	#DAJ save off
		};
 	}

    Pass P1 // specular mask
	{
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);
		Texture[3]	= (Texture3);
		
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t3;
			TEX t0, f0, texture[0], 2D;
			TEX t1, f1, texture[1], CUBE;
			TEX t3, f3, texture[3], CUBE;
			OUTPUT oC0 = result.color;

			PARAM c1 = program.env[12];
			PARAM c2 = program.env[13];
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			
			TEMP t0_bx2, t1_bx2;

			SUB t1_bx2, t1, half;			
			MUL t1_bx2, t1_bx2, two;
			SUB t0_bx2, t0, half;			
			MUL t0_bx2, t0_bx2, two;
			
			DP3_SAT r0, t1_bx2, t0_bx2;
			MUL_SAT r1.rgb, t3, t3;
			MOV r1.a, r0.b;
			MUL_SAT r1, r1, r1;
			MUL_SAT r1, r1, r1;
			LRP r0, r1.a, c1, c2;
			LRP r0.rgb, r0, t3, r1;
			MUL_SAT r1.rgb, r0.a, t0;
			MUL_SAT r0.rgb, r0, r1;

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
