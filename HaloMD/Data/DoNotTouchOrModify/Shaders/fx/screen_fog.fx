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

		ColorOp[0]			= Disable;
		AlphaOp[0]			= Disable;
		
		PixelShader			= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;
			TEX t1, f1, texture[1], 2D;
			OUTPUT oC0 = result.color;
						
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM c0 = program.env[0];
			PARAM c7 = { 1.0, 1.0, 1.0, 1.0 };
			
			TEMP oneminus;
			SUB oneminus.b, one.b, t0.b;
			MAD r0.a, c0.a, oneminus.b, t0.b;
			SUB r0, c7, r0.a;

			MOV oC0, r0;	#DAJ save off
		};
	}
	
	Pass P1
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

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;
			TEX t1, f1, texture[1], 2D;
			TEX t2, f2, texture[2], 2D;
			TEX t3, f3, texture[3], 2D;
			
			OUTPUT oC0 = result.color;
			
			PARAM c7 = { 1.0, 0.0, 0.0, 1.0 };
			
			MUL r0, t0, t1;
			MUL r1, t2, t3;
			MUL r0, r0, r1;
			MOV r0, c7;

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
