Texture Texture0;
Texture Texture1;
Texture Texture2;
Texture Texture3;

Technique ps_0_0
{
    Pass P0
	{
		Texture[0]			= (Texture0);
		Texture[1]			= (Texture1);

		TextureFactor		= 0xFFFFFFFF;
		ColorOp[0]			= SelectArg1;
		ColorArg1[0]		= Texture;
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
