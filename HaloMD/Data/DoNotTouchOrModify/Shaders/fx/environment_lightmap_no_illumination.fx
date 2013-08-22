Texture	Texture0;
Texture	Texture1;
Texture	Texture2;
Texture	Texture3;

Technique ps_1_1
{
    Pass P0
	{
		PixelShaderConstant[0] = (c_material_color);
		
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);
		Texture[2]	= (Texture2);
		Texture[3]	= (Texture3);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader			= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;
			TEX t1, f1, texture[1], 2D;
			TEX t2, f2, texture[2], 2D;
			TEX t3, f3, texture[3], CUBE;   # NVIDIA -- changed from 2D

			OUTPUT oC0 = result.color;
			
			
			PARAM c0 = program.env[0];	# c0 - material color
			PARAM c7 = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };

			TEMP t0_bx2, t3_bx2;
			SUB t0_bx2, t0, half;			
			MUL t0_bx2, t0_bx2, two;
			SUB t3_bx2, t3, half;			
			MUL t3_bx2, t3_bx2, two;
			DP3_SAT r0, t0_bx2, t3_bx2;
			
			MUL r0.rgb, t2, c0;
			MOV r0.a, t0.b;
			
			TEMP oneminus;
			SUB oneminus.a, c7.a, v0.a;
#DAJ		MAD r0.a, v0.a, r0.a, 1-v0.a;
			MAD r0.a, v0.a, r0.a, oneminus.a;
			
			MUL r1, r0.a, c0;
			MAD r0.rgb, t2, t1, r0;
			MOV r0.a, t0.a;

			MOV     oC0, r0;	#DAJ save off
		};
 	}
}

Technique ps_0_0
{
    Pass P0
	{
		ColorOp[0]			= SelectArg1;
		ColorArg1[0]		= Diffuse;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;

		ColorOp[1]			= Add;
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
