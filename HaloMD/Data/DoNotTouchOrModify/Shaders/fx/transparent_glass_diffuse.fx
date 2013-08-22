Technique ps_1_1
{
    Pass P0 // model
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
			TEX t0, f0, texture[0], 2D;
			TEX t1, f1, texture[1], 2D;
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			
			OUTPUT oC0 = result.color;

#DAJ		MUL_X2_SAT r0.rgb, t0, t1;
			MUL_SAT r0.rgb, t0, t1;
			MUL_SAT r0.rgb, r0, two;
			
			MUL_SAT r0.a, t0, t1;
			MUL_SAT r0.rgb, r0, v0;
			MUL_SAT r0.a, r0.a, v0.a;
			
			MOV oC0, r0;	#DAJ save off
		};
 	}

    Pass P1 // environment
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
			TEX t0, f0, texture[0], 2D;
			TEX t1, f1, texture[1], 2D;
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			
			OUTPUT oC0 = result.color;

#DAJ		MUL_X2_SAT r0.rgb, t0, t1;
			MUL_SAT r0.rgb, t0, t1;
			MUL_SAT r0.rgb, r0, two;
			
			MUL_SAT r0.a, t0, t1;
			ADD_SAT r1, t2, v0;
			MUL_SAT r0.rgb, r0, r1;
			MUL_SAT r0.a, r0.a, v0.a;
			
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
		AlphaOp[0]			= Modulate;
		AlphaArg1[0]		= Texture;
		AlphaArg2[0]		= Diffuse;

		ColorOp[1]			= Modulate;
		ColorArg1[1]		= Texture;
		ColorArg2[1]		= Current;
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
