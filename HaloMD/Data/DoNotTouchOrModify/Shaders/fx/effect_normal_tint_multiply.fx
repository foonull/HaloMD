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
			
			MUL r0.rgb, t0, v0;
			MOV r0.a, t0.a;
#DAJ		MAD r0.rgb, r0, v0.a, 1-v0.a;
			SUB r1.a, one.a, v0.a;
			MAD r0.rgb, r0, v0.a, r1.a;

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
		
		ColorOp[1]			= MultiplyAdd;
		ColorArg1[1]		= Diffuse|AlphaReplicate|Complement;
		ColorArg2[1]		= Diffuse|AlphaReplicate;
		ColorArg0[1]		= Current;
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
