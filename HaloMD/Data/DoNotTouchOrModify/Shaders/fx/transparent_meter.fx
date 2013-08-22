Texture	Texture0;
Texture	Texture1;
Texture	Texture2; 
Texture	Texture3;

Technique ps_1_1
{
    Pass P0
	{
		Texture[0]			= (Texture0);

		ColorOp[0]			= Disable;
		AlphaOp[0]			= Disable;
		
 		PixelShader			= asm
 		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0;
			TEX t0, f0, texture[0], 2D;
			OUTPUT oC0 = result.color;

 			PARAM c0 = program.env[6];	# c0 - meter_flash_color
			PARAM c1 = program.env[7];	# c1 - meter_gradient_max_color
			PARAM c2 = program.env[8];	# c2 - meter_gradient_min_color
			PARAM c3 = program.env[9];	# c3 - meter_background_color
			PARAM c4 = program.env[10];	# c4 - meter_tint_color
			PARAM c5 = program.env[11];	# c5 - meter_flash_color_variable
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two =  { 2.0, 2.0, 2.0, 2.0 };
			PARAM four = { 4.0, 4.0, 4.0, 4.0 };
 			TEMP cnd, r0_bx2, r1_bias;
 			
 			MOV r1.rgb, c2.a;
 			MUL r1.a, c1.a, t0.b;
 			
#DAJ		ADD_X4 r0.rgb, c0, -t0;
 			ADD r0.rgb, c0, -t0;
 			MUL r0.rgb, r0, four;
 			
#DAJ		ADD_X4_SAT r0.a, r1.a, r1.a;
			ADD_SAT r0.a, r1.a, r1.a;
 			MUL r0.a, r0.a, four.a;
 			
			LRP r0.rgb, r0.a, c1, c2;
			SUB r0_bx2, r0, half;
			MUL r0_bx2, r0_bx2, two;
 			MOV r0.a, -r0_bx2.b;
 			
 			MAD r0.rgb, r0.a, c5, r0;
			SUB r1_bias, r1, half;	#DAJ
			ADD r0.a, t0.b, -r1_bias.b;


			SUB cnd, r0, half;			
#DAJ		CND r0.rgb, r0.a, c3, r0;
			CMP r0.rgb, cnd.a, r0, c3;
			
#DAJ		CND r0.a, r0.a, c3.a, c4.a;
			CMP r0.a, cnd.a, c4.a, c3.a;
			
			MUL r0.rgb, r0, t0.a;

			MOV oC0, r0;	#DAJ save off
 		};
 	}
}

Technique ps_0_0
{
    Pass P0
	{
		Texture[0]			= (Texture0);
		
		ColorOp[0]			= SelectArg1;
		ColorArg1[0]		= Texture;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;

		ColorOp[1]			= Disable;

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
