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
			ATTRIB v1 = fragment.color.secondary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;
			OUTPUT oC0 = result.color;
			TEMP oneminus;
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };

			MUL r0, t0, t0;
			MUL r1, r0, r0;
			MUL t0, v0, t0;
			MUL r0, r0, r1;
#DAJ		MUL r1, 1-v0, v1.a;
			SUB oneminus, one, v0;
			MUL r1, oneminus, v1.a;
			MAD r0.rgb, r0, v1, t0;
			MOV r0.a, t0.a;

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
		ColorArg2[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Diffuse;

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
