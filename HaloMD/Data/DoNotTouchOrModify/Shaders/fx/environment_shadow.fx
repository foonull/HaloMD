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
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;	# shadow
			TEX t1, f1, texture[1], 2D;	# fade
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];	# c0 = 1-local_shadow_color
			PARAM c1 = { 1.0, 1.0, 1.0, 0.0 };
			PARAM c2 = { 1.0, 0.0, -1.0, 0.0 };
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			
			TEMP oneminust1, oneminusr0, oneminusr1;
			
#DAJ		MUL_SAT r0.rgb, 1-t1, v0.a;
			SUB oneminust1, one, t1;
			MUL_SAT r0.rgb, oneminust1, v0.a;
			
			MUL_SAT r1.rgb, t0, c0;
			
			SUB oneminusr1, one, r1;
			SUB oneminusr0, one, r0;
#DAJ		MAD_SAT r0.rgb, r0, 1-r1, 1-r0;
			MAD_SAT r0.rgb, r0, oneminusr1, oneminusr0;
			
#DAJ		DP3_SAT r1, 1-r0, c1;
			SUB oneminusr0, one, r0;
			DP3_SAT r1, oneminusr0, c1;
			
			SUB r0.rgb, c1, r0;
			MOV r0.a, r1.b;

			MOV     oC0, r0;	#DAJ save off
		};
 	}
}

Technique ps_0_0
{
    Pass P0
	{
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
