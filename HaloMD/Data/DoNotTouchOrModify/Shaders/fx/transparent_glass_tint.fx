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
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;
			OUTPUT oC0 = result.color;
			
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM c0 = program.env[0];
			TEMP oneminus;
			
			MUL r0.rgb, t0, c0;
			
#DAJ		MAD r0.rgb, r0, v0.a, 1-v0.a;
			SUB oneminus.a, one.a, v0.a;
			MAD r0.rgb, r0, v0.a, oneminus.a;
			
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
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= TFactor;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Diffuse;

		ColorOp[1]			= Modulate;
		ColorArg1[1]		= Current;
		ColorArg2[1]		= Diffuse;
		AlphaOp[1]			= SelectArg1|AlphaReplicate;
		AlphaArg1[1]		= Current;

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
