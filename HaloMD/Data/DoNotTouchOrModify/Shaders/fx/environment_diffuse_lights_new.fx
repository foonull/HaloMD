Texture Texture0;
Texture Texture1;
Texture Texture2;
Texture Texture3;

Technique ps_1_1
{
    Pass P0
	{
		Texture[0]			= (Texture0);
		Texture[1]			= (Texture1);
		Texture[2]			= (Texture2);
		Texture[3]			= (Texture3);

		ColorOp[0]			= Disable;
		AlphaOp[0]			= Disable;
		
		PixelShader			= asm
		{
			TEMP r0, r1;
			TEMP t0_bx2, t3_bx2;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB v0 = fragment.color.primary;
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;
			TEX t1, f1, texture[1], CUBE;	# gel
			TEX t2, f2, texture[2], 3D;	# distance attenuation
			TEX t3, f3, texture[3], CUBE;
			
			OUTPUT oC0 = result.color;
			
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];

			PARAM c7 = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			PARAM four = { 4.0, 4.0, 4.0, 4.0 };
			
			MUL_SAT r0.rgb, t1, t2;				# gel color and spherical attenuation
			
#DAJ 		ADD_X4 r0.a, t3_bx2.b, t3_bx2.b;	# self shadow mask
			SUB t3_bx2, t3, half;			
			MUL t3_bx2, t3_bx2, two;
			ADD r0.a, t3_bx2.b, t3_bx2.b;	
			MUL r0.a, r0.a, four.a;			
			
			SUB t0_bx2, t0, half;			
			MUL t0_bx2, t0_bx2, two;
			DP3_SAT r1, t0_bx2, t3_bx2;			# bump attenuation
			
			MUL_SAT r0, r1, r0;					# light with gel, distance and bump
			MUL_SAT r0, r0.a, r0;				# light with self shadow
			MUL_SAT r0, r0, c0;					# light with color
			DP3_SAT r1, r0, c0;					# active pixel mask
			MUL_SAT r0.rgb, c1, r0;				# final light
			MOV_SAT r0.a, r1.b;				# active pixel mask

			MOV     oC0, r0;	#DAJ save off
		};
 	}
}

Technique ps_0_0
{
    Pass P0
	{
		Texture[0]			= (Texture1);
		Texture[1]			= (Texture2);

		ColorOp[0]			= Modulate;
		ColorArg1[0]		= Texture;
		ColorArg2[0]		= TFactor;
		AlphaOp[0]			= Modulate;
		AlphaArg1[0]		= Texture;
		AlphaArg2[0]		= TFactor;

		ColorOp[1]			= Modulate;
		ColorArg1[1]		= Texture;
		ColorArg2[1]		= Current;
		AlphaOp[1]			= Modulate;
		AlphaArg1[1]		= Texture;
		AlphaArg2[1]		= Current;

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
