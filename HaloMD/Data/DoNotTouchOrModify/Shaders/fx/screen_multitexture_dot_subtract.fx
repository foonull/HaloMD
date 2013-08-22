Texture	Texture0;
Texture	Texture1;
Texture	Texture2; 
Texture	Texture3;

Technique ps_1_1
{
    Pass P0
	{
		Texture[0]			= (Texture0);
		Texture[1]			= (Texture1);
		Texture[2]			= (Texture2);

		ColorOp[0]			= Disable;
		AlphaOp[0]			= Disable;
		
 		PixelShader			= asm
 		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB v0 = fragment.color.primary;
			
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;
			TEX t1, f1, texture[1], 2D;
			TEX t2, f2, texture[2], 2D;
			
			OUTPUT oC0 = result.color;
 			
			MUL t0, t0, c0;
			MUL t1, t1, c1;
			MUL t2, t2, c2;
			MUL r0.rgb, t0, v0;
			MOV r0.a, t0.a;
			DP3_SAT r0, r0, t1;
			MUL r0.a, r0.a, t1.a;			
			SUB r0, r0, t2;

			MOV     oC0, r0;	#DAJ save off
#DAJ WEAPON STRIPS
#PARAM red = { 1, 0, 0, 1 };
#MOV oC0, t2;
 		};
 	}
}

Technique ps_0_0
{
    Pass P0
	{
		Texture[0]			= (Texture0);
		Texture[1]			= (Texture1);

		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= TFactor;
		AlphaOp[0]			= Modulate;
		AlphaArg1[0]		= Texture;
		AlphaArg2[0]		= TFactor;

		ColorOp[1]			= Modulate;
		ColorArg1[1]		= Texture;
		ColorArg2[1]		= Current;
		AlphaOp[1]			= Modulate;
		AlphaArg1[1]		= Texture;
		AlphaArg2[1]		= Current;

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
