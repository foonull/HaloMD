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

			PARAM c7 = { 0.5, 0.5, 0.5, 0.5 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM black = { 0, 0, 0, 0 };
			MUL r0.rgb, t2, c7;
			MUL r0.a, t0.b, c7;
			
#DAJ		MAD_D2	r0.rgb, t3, c7, r0;
#BAD		MAD		r0.rgb, t3, c7, r0;
			MAD		r0.rgb, black, c7, r0;
			MUL		r0.rgb, r0, half;
			
#DAJ		MAD_D2	r0.a, t1.b, c7, r0.a;
			MAD 	r0.a, t1.b, c7, r0.a;
			MUL		r0.a, r0.a, half.a;
			
			ADD r0, r0, r0.a;

			MOV     oC0, r0;	#DAJ save off
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
