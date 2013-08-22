Texture Texture0;
Texture Texture1;
Texture Texture2;
Texture Texture3;

/* DAJ
half4 c_eye_forward;
half4 c_view_perpendicular_color;
half4 c_view_parallel_color;
*/
Technique ps_1_1
{
    Pass P0
	{
		PixelShaderConstant[0] = (c_eye_forward);
		PixelShaderConstant[1] = (c_view_perpendicular_color);
		PixelShaderConstant[2] = (c_view_parallel_color);

		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);
		Texture[2]	= (Texture2);
		Texture[3]	= (Texture3);

		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;

		PixelShader	= asm
		{
			TEMP r0, r1, r2, r3, r4, r5;
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c7 = { 0.5, 0.5, 0.5, 0.5 };

			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			PARAM four = { 4.0, 4.0, 4.0, 4.0 };

			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB f4 = fragment.texcoord[4];
			ATTRIB v0 = fragment.color.primary;
			ATTRIB v1 = fragment.color.secondary;

			TEMP t0, t1, t2, t3;		
			TEX t0, f0, texture[0], 2D;
# NVIDIA -- commented these out, since they shouldn't be here
#			TEX t1, f1, texture[1], CUBE;
#			TEX t2, f2, texture[2], CUBE;
#			TEX t3, f3, texture[3], CUBE;
			
			TEMP t0_bx2;
		
			OUTPUT oC0 = result.color;
			
#DAJ		texm3x3pad t1, t0_bx2
#DAJ		texm3x3pad t2, t0_bx2
#DAJ		texm3x3vspec t3, t0_bx2
			
			SUB t0_bx2, t0, half;			
			MUL t0_bx2, t0_bx2, two;

			DP3 r1.x, f1, t0_bx2;
			DP3 r1.y, f2, t0_bx2;
			DP3 r1.z, f3, t0_bx2;

			DP3 r4, r1, f4;
			MUL r4, r4, two;
			MUL r4, r4, r1;
			
			DP3 r5, r1, r1;
			MUL r5, r5, f4;
			SUB r3, r4, r5;
			
			TEX t3, r3, texture[3], CUBE;

			MUL r1, t3, t3;
			
#DAJ		MUL_D2 r1, r1, r1;
			MUL r1, r1, r1;
			MUL r1, r1, half;
			
			MUL r1.rgb, r1, r1;
			MOV_SAT r1.a, c0.a;
			LRP_SAT r0, r1.a, c1, c2;
			LRP r0.rgb, r0.a, t3, r1;

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
