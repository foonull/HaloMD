Texture	Texture0;
Texture	Texture1;
Texture	Texture2; 
Texture	Texture3;

Technique ps_1_1
{
    Pass P0
	{
		Texture[0]	= (Texture0);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;

 		PixelShader	= asm
 		{
			TEMP r0;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0;
			TEX t0, f0, texture[0], 2D;
			PARAM c0 = program.env[0];
			OUTPUT oC0 = result.color;

			MUL r0, t0, c0;
			MUL oC0.rgb, r0, v0;
			MUL oC0.a, t0.a, v0.a;
		};
 	}
}

Technique ps_0_0
{
    Pass P0
	{
		Texture[0]			= (Texture0);

		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= TFactor;
		AlphaOp[0]			= Modulate;
		AlphaArg1[0]		= Texture;
		AlphaArg2[0]		= TFactor;

		ColorOp[1]			= Modulate;
		ColorArg1[1]		= Current;
		ColorArg2[1]		= Diffuse;
		AlphaOp[1]			= Modulate;
		AlphaArg1[1]		= Current;
		AlphaArg2[1]		= Diffuse;
		
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
