Texture Texture0;
Texture Texture1;
Texture Texture2;
Texture Texture3;

Technique ps_1_1
{
    Pass P0
	{
		Texture[0]	= (Texture0);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, oneminus;
			TEX t0, f0, texture[0], 2D;	# lightmap

			PARAM c0 = { 0.5019607843137254, 0.6901960784313725, 0.3137254901960784, 0.0 };
			PARAM c1 = program.env[1];	# c1 - lightmap brightness
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			
			OUTPUT oC0 = result.color;

			DP3_SAT	r0, t0, c0;
			
#DAJ		MAD r0.a, 1-r0.b, c1.a, r0.b;
			SUB oneminus.b, one.b, r0.b;
			MAD r0.a, oneminus.b, c1.a, r0.b;

			MOV     oC0, r0;	#DAJ save off
		};
 	}
}

Technique ps_0_0
{
    Pass P0
	{
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
