Technique ps_1_1
{
    Pass AlphaModulatesReflection
	{
		ColorOp[0]			= Disable;
		AlphaOp[0]			= Disable;
		
		PixelShader			= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];	#DAJ was missing
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1;
			TEX t0, f0, texture[0], 2D;
			TEX t1, f1, texture[1], 2D;		#DAJ this too
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];	# c0 - perpendicular tint color
			PARAM c1 = program.env[1];	# c1 - parallel tint color
			
			LRP r0.a, t1.b, c0, c1;
			MUL r0, r0.a, t0.a;

			MOV oC0, r0;	#DAJ save off
		};
 	}

    Pass ColorModulatesBackground
	{
		ColorOp[0]			= Disable;
		AlphaOp[0]			= Disable;
		
		PixelShader			= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];

			TEMP t0;
			TEX t0, f0, texture[0], 2D;
			OUTPUT oC0 = result.color;

			MOV oC0, t0;	#DAJ save off
		};
 	}
}

Technique ps_0_0
{
    Pass AlphaModulatesReflection
	{
		ColorOp[0]			= SelectArg1;
		ColorArg1[0]		= Texture|AlphaReplicate;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;

		ColorOp[1]			= Disable;
		AlphaOp[1]			= Disable;

		PixelShader			= Null;
 	}

    Pass ColorModulatesBackground
	{
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
