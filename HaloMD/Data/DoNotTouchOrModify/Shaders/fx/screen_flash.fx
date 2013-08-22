///////////////////////////////////////////////////////////////////////////////
// Pixel Shader 1.1 shaders
///////////////////////////////////////////////////////////////////////////////
/*
//DAJ this one is NOT used on the PC the ps_0_0 one is
Technique FlashInvert_ps_1_1
{
	Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = asm
		{
			TEMP r0, r1;

			OUTPUT oC0 = result.color;
			
			TEMP r1_bx2;
			PARAM c0 = program.env[0];
			PARAM c7 = { 1.0, 1.0, 1.0, 0.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };

#DAJ cant get this to work, but there is a much simpler way		
#DAJ its back in	
			MUL r1, c7, c0;			
			SUB r1_bx2, r1, half;
			MUL r1_bx2, r1_bx2, two;

			MAD r0.rgb, c0, r1_bx2, c0.a;
			MOV r0.a, c7;

			MOV oC0, r0;	#DAJ save off
#MOV oC0, c0;
		};
	}
}
*/
///////////////////////////////////////////////////////////////////////////////
// Fixed Function shaders
///////////////////////////////////////////////////////////////////////////////
Technique FlashLighten_ps_0_0
{
	Pass P0
	{
		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= TFactor;
		AlphaOp[0]		= SelectArg1;
		AlphaArg1[0]	= TFactor;

		AlphaOp[1]		= Disable;
		ColorOp[1]		= Disable;
		
		PixelShader		= Null;
	}
}

Technique FlashDarken_ps_0_0
{
	Pass P0
	{
		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= TFactor;
		AlphaOp[0]		= SelectArg1;
		AlphaArg1[0]	= TFactor;

		AlphaOp[1]		= Disable;
		ColorOp[1]		= Disable;
		
		PixelShader		= Null;
	}
}

Technique FlashMax_ps_0_0
{
	Pass P0
	{
		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= TFactor;
		AlphaOp[0]		= Disable;

		ColorOp[1]		= Subtract;
		ColorArg1[1]	= Current;
		ColorArg2[1]	= TFactor|AlphaReplicate;
		AlphaOp[1]		= Disable;

		ColorOp[2]		= Disable;
		AlphaOp[2]		= Disable;
		
		PixelShader		= Null;
	}
}

Technique FlashMin_ps_0_0
{
	Pass P0
	{
		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= TFactor;
		AlphaOp[0]		= Disable;

		ColorOp[1]		= Add;
		ColorArg1[1]	= Current;
		ColorArg2[1]	= TFactor|AlphaReplicate;
		AlphaOp[1]		= Disable;

		ColorOp[2]		= Disable;
		AlphaOp[2]		= Disable;
		
		PixelShader		= Null;
	}
}

Technique FlashInvert_ps_0_0
{
	Pass P0
	{
		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= TFactor;
		AlphaOp[0]		= SelectArg1;
		AlphaArg1[0]	= TFactor;

		AlphaOp[1]		= Disable;
		ColorOp[1]		= Disable;
		
		PixelShader		= Null;
	}
}

Technique FlashTint_ps_0_0
{
	Pass P0
	{
		ColorOp[0]		= SelectArg1;
		ColorArg1[0]	= TFactor|AlphaReplicate;
		AlphaOp[0]		= Disable;

		AlphaOp[1]		= Disable;
		ColorOp[1]		= Disable;
		
		PixelShader		= Null;
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
