Texture Texture0;
Texture Texture1;
Texture Texture2;
Texture Texture3;

Technique ps_1_1
{
    Pass TintEdgeDensity
	{
		PixelShader			= asm
		{
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];	#DAJ viewport scale up
			PARAM c7 = { 1.0, 1.0, 1.0, 1.0};

			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
PARAM divisor = { 0.0015625, 0.001953, 0.0, 0.0 };
			
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB v0 = fragment.color.primary;

			TEMP r0, r1;
			TEMP t0, t1, t2;
			TEMP t0_bx2, t3_bx2;

			TEX t0, f0, texture[0], CUBE;

			OUTPUT oC0 = result.color;

			SUB t0_bx2, t0, half;			
			MUL t0_bx2, t0_bx2, two;
			
#DAJ		texm3x2pad t1, t0_bx2
#DAJ		texm3x2tex t2, t0_bx2

			DP3 r1.x, f1, t0_bx2;
			DP3 r1.y, f2, t0_bx2;

##############
#  NVIDIA - removed MUL, since this was put in the vertex shader
#			MUL r1, r1, c1;
#MUL r0.rg, r0, divisor;		
			TEX t2, r1, texture[2], RECT; #NOT 2D dummy
			
###			LRP r0.rgb, t0.a, v0, c7;
###			LRP r0.rgb, v0.a, r0, c7;		
###			MUL r0.rgb, r0, t2;
###			MOV r0.a, c0.a;

MOV r0.rgb, t2;
			MOV     oC0, r0;
		};
 	}

    Pass NoEdgeTint
	{
		ColorOp[0]			= Disable;
		AlphaOp[0]			= Disable;
		
		PixelShader			= asm
		{
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];	#DAJ viewport scale up
			PARAM c7 = { 1.0, 1.0, 1.0, 1.0};

			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
						
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB v0 = fragment.color.primary;

			TEMP r0, r1;
			TEMP t0, t1, t2;
			TEMP t0_bx2, t3_bx2;

			TEX t0, f0, texture[0], CUBE;
			
			OUTPUT oC0 = result.color;

			SUB t0_bx2, t0, half;			
			MUL t0_bx2, t0_bx2, two;
			
#DAJ		texm3x2pad t1, t0_bx2
#DAJ		texm3x2tex t2, t0_bx2

			DP3 r1.x, f1, t0_bx2;
			DP3 r1.y, f2, t0_bx2;

###################			
#  NVIDIA - removed MUL, put in vertex shader
#			MUL r1, r1, c1;
			TEX t2, r1, texture[2], RECT; #NOT 2D dummy
			
			MAD r0.rgb, v0.a, v0, c7;
			MUL r0.rgb, r0, t2;
			MOV r0.a, c0.a;

			MOV     oC0, r0;	#DAJ save off
		};
 	}
}

Technique ps_0_0
{
    Pass P0
	{
		ColorOp[0]			= SelectArg1;
		ColorArg1[0]		= Texture;
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
