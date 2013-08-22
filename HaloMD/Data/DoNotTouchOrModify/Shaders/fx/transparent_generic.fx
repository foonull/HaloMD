Texture	Texture0;
Texture	Texture1;
Texture	Texture2; 
Texture	Texture3;

Technique ps_1_1
{
    Pass P0
	{
		Texture[0]			= (Texture0);

		ColorOp[0]			= Disable;
		AlphaOp[0]			= Disable;
		
		PixelShader			= asm
		{
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB v0 = fragment.color.primary;
			TEMP t0;
			TEX t0, f0, texture[0], 2D;
			OUTPUT oC0 = result.color;
			
			MOV oC0, t0;
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
