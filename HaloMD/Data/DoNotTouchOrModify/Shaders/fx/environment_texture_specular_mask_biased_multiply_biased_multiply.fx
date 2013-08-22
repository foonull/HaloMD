Texture	Texture0;
Texture	Texture1;
Texture	Texture2;
Texture	Texture3;

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
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;	# base map
			TEX t1, f1, texture[1], 2D;	# primary detail map
			TEX t2, f2, texture[2], 2D;	# secondary detail map
			TEX t3, f3, texture[3], 2D;	# micro detail map
			OUTPUT oC0 = result.color;

			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			
			TEMP oneminus;
			SUB oneminus.a, one.a, t0.a;
			
			# environment type = specular
			# we could have used lrp here, but you can only read 2 texture registers per instruction
			MUL r0, t0.a, t1;					# detail map part 1
#DAJ		MAD r0.rgb, 1-t0.a, t2, r0;			# detail map part 2
			MAD r0.rgb, oneminus.a, t2, r0;	
			MOV r0.a, t0.a;						# detail specular mask
			
			TEMP r0_bx2;
			SUB r0_bx2, r0, half;
			MUL r0_bx2, r0_bx2, two;

			# detail map function
			MUL r0.rgb, t0, r0;				# biased mulriply
			MUL r0.rgb, r0, two;
			MUL r0.a, t3.a, r0.a;				# Modulate specular mask by micro detail alpha (all methods do this)

			# micro detail map function
			MUL r0.rgb, t3, r0;				# biased multiply
			MUL r0.rgb, r0, two;
			
			MOV     oC0, r0;	#DAJ save off
		};
 	}
}

Technique ps_0_0
{
    Pass P0
	{
		Texture[0]			= (Texture0);
		Texture[1]			= (Texture1);

		ColorOp[0]			= SelectArg1;
		ColorArg1[0]		= Texture;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;

		ColorOp[1]			= Modulate;
		ColorArg1[1]		= Current;
		ColorArg2[1]		= Texture;
		AlphaOp[1]			= SelectArg1;
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
