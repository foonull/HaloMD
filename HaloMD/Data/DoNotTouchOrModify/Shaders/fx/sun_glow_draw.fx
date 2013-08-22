Technique ps_1_1
{
    Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader	= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;
			OUTPUT oC0 = result.color;

			PARAM c0 = { 0.6901960784313725, 0.6901960784313725, 0.5019607843137254, 0.0 };
			PARAM c1 = { 1.0, 1.0, 1.0, 0.0 };
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			
			TEMP t0_bx2, oneminus;
			SUB t0_bx2, t0, half;			
			MUL t0_bx2, t0_bx2, two;

			
			SUB_SAT r0.a, c1.b, t0_bx2.b;
#DAJ		MAD r0.rgb, r0.a, c0, 1-r0.a;
			SUB oneminus.a, one.a, r0.a;
			MAD r0.rgb, r0.a, c0, oneminus.a;
			MUL r0.rgb, r0, t0;
			MOV r0.a, v0.a;

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
