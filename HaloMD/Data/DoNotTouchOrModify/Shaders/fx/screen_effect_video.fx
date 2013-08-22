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

		ColorOp[0]			= Disable;
		AlphaOp[0]			= Disable;
		
		PixelShader			= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB v0 = fragment.color.primary;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;	# frame
			TEX t1, f1, texture[1], 2D;	# scanline
			TEX t2, f2, texture[2], 2D;	# noise
			OUTPUT oC0 = result.color;

			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			
			TEMP oneminus;
			MAD r0, c0.a, t2, c1.a;		# attenuated noise
			MUL r0.rgb, r0, t1;			# attenuated tint
			MUL r1, t0, t0;				# t0^2
			MUL r1, r1, r1;				# overbright*t0^2
			MUL t0, t0, c0;				# overbright*t0
			SUB oneminus, one, r0;
			MAD r0.rgb, r1, oneminus, t0;

			MOV oC0, r0;	#DAJ save off
		};
 	}
}

Technique ps_0_0
{
    Pass P0
	{
		Texture[0]			= (Texture0);

		TextureFactor		= 0xFFFF0000;
		
		ColorOp[0]			= SelectArg1;
		ColorArg1[0]		= TFactor;
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
