Technique ps_1_1
{
    Pass NoModulation
	{
 		PixelShader	= asm
		{
			TEMP r0, r1, r2, r3, r4, r5;
			PARAM c2 = program.env[2];			# c2 - tint color
			PARAM c7 = { 0.5, 0.5, 0.5, 0.5 };

			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
						
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB f4 = fragment.texcoord[4];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t3;		
			TEX t0, f0, texture[0], 2D;			# Bump map
			TEX t3, f3, texture[3], CUBE;		# Reflection cube map
			
			TEMP t0_bx2;
			OUTPUT oC0 = result.color;
			
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
			
			MUL r0, t3, t3;
			MUL r0, r0, r0;
			MUL r0, r0, r0;
			LRP r0, c2, t3, r0;

			MOV oC0, r0;	#DAJ save off
 		};
 	}

    Pass AlphaModulatesReflection
	{
 		PixelShader	= asm
		{
			TEMP r0, r1, r2, r3, r4, r5;
			PARAM c0 = program.env[0];		# c0 - perpendicular tint color
			PARAM c1 = program.env[1];		# c1 - parallel tint color
			PARAM c2 = program.env[2];		# c2 - tint color
			PARAM c7 = { 0.5, 0.5, 0.5, 0.5 };

			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
						
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB f4 = fragment.texcoord[4];
			ATTRIB f5 = fragment.texcoord[5];
			ATTRIB f6 = fragment.texcoord[6];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;		
			TEX t0, f0, texture[0], 2D;		# Bump map
			TEX t1, f5, texture[1], 2D;		# Base map
			TEX t2, f6, texture[2], CUBE;	# Eye vector normalization cube map
			TEX t3, f3, texture[3], CUBE;	# Reflection cube map
			
			TEMP t0_bx2;
			OUTPUT oC0 = result.color;
			
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
			
			MUL r0, t3, t3;
			MUL r0, r0, r0;
			MUL r0, r0, r0;
			LRP r0, c2, t3, r0;

			LRP r2.a, t2.b, c0, c1;			# Alpha modulates reflection
			MUL r0.a, r2.a, t1.a;

			MOV oC0, r0;	#DAJ save off
 		};
 	}

    Pass ColorModulatesReflection
	{
 		PixelShader	= asm
		{
			TEMP r0, r1, r2, r3, r4, r5;
			PARAM c0 = program.env[0];		# c0 - perpendicular tint color
			PARAM c1 = program.env[1];		# c1 - parallel tint color
			PARAM c2 = program.env[2];		# c2 - tint color
			PARAM c7 = { 0.5, 0.5, 0.5, 0.5 };

			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
						
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB f4 = fragment.texcoord[4];
			ATTRIB f5 = fragment.texcoord[5];
			ATTRIB f6 = fragment.texcoord[6];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;		
			TEX t0, f0, texture[0], 2D;		# Bump map
			TEX t1, f5, texture[1], 2D;		# Base map
			TEX t2, f6, texture[2], CUBE;	# Eye vector normalization cube map
			TEX t3, f3, texture[3], CUBE;	# Reflection cube map
			
			TEMP t0_bx2;
			OUTPUT oC0 = result.color;
			
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
			
			MUL r0, t3, t3;
			MUL r0, r0, r0;
			MUL r0, r0, r0;
			LRP r0, c2, t3, r0;

			MUL r0.rgb, r0, t1;				# Color modulates reflection

			MOV oC0, r0;	#DAJ save off
 		};
 	}

    Pass BothModulateReflection
	{
 		PixelShader	= asm
		{
			TEMP r0, r1, r2, r3, r4, r5;
			PARAM c0 = program.env[0];		# c0 - perpendicular tint color
			PARAM c1 = program.env[1];		# c1 - parallel tint color
			PARAM c2 = program.env[2];		# c2 - tint color
			PARAM c7 = { 0.5, 0.5, 0.5, 0.5 };

			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
						
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB f4 = fragment.texcoord[4];
			ATTRIB f5 = fragment.texcoord[5];
			ATTRIB f6 = fragment.texcoord[6];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;		
			TEX t0, f0, texture[0], 2D;		# Bump map
			TEX t1, f5, texture[1], 2D;		# Base map
			TEX t2, f6, texture[2], CUBE;	# Eye vector normalization cube map
			TEX t3, f3, texture[3], CUBE;	# Reflection cube map
			
			TEMP t0_bx2;
			OUTPUT oC0 = result.color;
			
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
			
			MUL r0, t3, t3;
			MUL r0, r0, r0;
			MUL r0, r0, r0;
			LRP r0, c2, t3, r0;

			MUL r0.rgb, r0, t1;				# Color modulates reflection

			LRP r2.a, t2.b, c0, c1;			# Alpha modulates reflection
			MUL r0.a, r2.a, t1.a;

			MOV oC0, r0;	#DAJ save off
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
		AlphaArg1[0]		= Texture;

		ColorOp[1]			= Disable;
		AlphaOp[1]			= Disable;
		
		PixelShader			= NULL;
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
