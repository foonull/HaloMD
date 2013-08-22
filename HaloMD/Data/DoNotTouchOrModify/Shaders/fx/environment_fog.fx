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

		ColorOp[0]			= Disable;
		AlphaOp[0]			= Disable;
		
		PixelShader			= asm
		{
#				c0 -	rgb = global_window_parameters.fog.atmospheric_maximum_density
#						a = fog_blend_factor*global_window_parameters.fog.atmospheric_maximum_density
#				c1 -	rgb = global_window_parameters.fog.planar_maximum_density
#						a = planar_eye_density*global_window_parameters.fog.planar_maximum_density
#				c2 -	rgb = global_window_parameters.fog.atmospheric_color
#						a = fog_blend_factor
#				c3 -	rgb = global_window_parameters.fog.planar_color
#						a = 1.0f - fog_blend_factor
			PARAM c0 = program.env[14];	#DAJ moved from 0 to avoid conflict
			PARAM c1 = program.env[15];
			PARAM c2 = program.env[16];
			PARAM c3 = program.env[17];
			PARAM c4 = {1.0, 1.0, 1.0, 1.0};
			
			TEMP r0, r1;
			TEMP oneminus;

			ATTRIB f0 = fragment.texcoord[0];	# atmospheric fog density
			ATTRIB f1 = fragment.texcoord[1];	# planar fog density
			
			OUTPUT oC0 = result.color;
			
			TEMP t0, t1;
			TEX     t0, f0, texture[0], 2D;
			TEX     t1, f1, texture[1], 2D;
									
			MUL 	r0.a, c1.a, t1.b;
			MAD_SAT r0.a, c1.b, t1.a, r0.a;			# r0.a = Pf
			MUL 	t0.rgb, t0.a, c0;				# t0.rgb = Af
			MUL_SAT t0.a, t0.a, c0.b;				# t0.a = blend * Af
			MUL 	r1.rgb, c3, r0.a;				# r1.rgb = Pc*Pf
			MUL_SAT r1.a, c3.a, r0.a;				# r1.a = (1 - blend)*Pf
			MUL_SAT r0.rgb, c2, t0;				# r0.rgb = Ac*Af
			
			#DAJ make the 1- temps
			SUB		oneminus.x, c4.a, t0.a;
			SUB		oneminus.y, c4.a, r0.a;
			SUB		oneminus.z, c4.a, r1.a;
			
#DAJ		MUL_SAT r0.a, 1-t0.a, 1-r0.a;			# r0.a = (1 - Af)*(1 - Pf)
			MUL_SAT r0.a, oneminus.x, oneminus.y;
			
#DAJ		MUL 	r0.rgb, r0, 1-r1.a;				# Ac*Af*(1 - (1 - blend)*Pf)
			MUL 	r0.rgb, r0, oneminus.z;
			
#DAJ		MAD 	r0.rgb, r1, 1-t0.a, r0;			# Ac*Af*(1 - (1 - blend)*Pf) + Pc*Pf*(1 - blend*Af)
			MAD 	r0.rgb, r1, oneminus.x, r0;

			SUB 	r0.a, c4, r0.a;					# 1 - (1 - Af)*(1 - Pf)

			MOV     oC0, r0;	#DAJ save off
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
