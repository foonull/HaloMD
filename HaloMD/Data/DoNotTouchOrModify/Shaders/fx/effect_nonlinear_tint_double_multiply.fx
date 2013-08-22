Technique ps_1_1
{
    Pass P0
	{
		ColorOp[0]			= Disable;
		AlphaOp[0]			= Disable;
		
		PixelShader			= asm
		{
			TEMP r0;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;

			OUTPUT oC0 = result.color;

			PARAM c0 = { 0.5, 0.5, 0.5, 0.5 };
			
			MUL r0.rgb, t0, t0;
			MOV r0.a, t0.a;
			MUL r0.rgb, r0, r0;
			LRP r0.rgb, v0, t0, r0;
			LRP r0.rgb, v0.a, r0, c0;

			MOV     oC0, r0;	#DAJ save off
		};
 	}
}

Technique ps_0_0
{
    Pass P0
	{
		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;

		TextureFactor		= 0x7F7F7F7F;
		ColorOp[1]			= Lerp;
		ColorArg1[1]		= Diffuse|AlphaReplicate;
		ColorArg2[1]		= Current;
		ColorArg0[1]		= TFactor;
		AlphaOp[1]			= SelectArg1;
		AlphaArg1[1]		= Current;

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
