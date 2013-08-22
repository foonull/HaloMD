Texture	Texture0;
Texture	Texture1;
Texture	Texture2; 
Texture	Texture3;
/* //DAJ
sampler TexSampler0 = sampler_state
{
    Texture = (Texture0);
};

sampler TexSampler1 = sampler_state
{
    Texture = (Texture1);
};

sampler TexSampler2 = sampler_state
{
    Texture = (Texture2);
};

sampler TexSampler3 = sampler_state
{
    Texture = (Texture3);
};

half4 c_specular_brightness;
half4 c_view_perpendicular_color;
half4 c_view_parallel_color;
half4 c_multiplier;

PixelShader PS_SpecularLightmapFlat_ps_1_4 = asm
{
    #define T0 r0
    #define T0_bx2 r0_bx2
    #define T1 r1
    #define T1_bx2 r1_bx2
    #define T2 r2
    #define T2_bx2 r2_bx2
    #define T2_bias r2_bias
    #define T3 r3
    #define T3_bx2 r3_bx2
    #define D0a r1.a
    #define R0 r5
    #define R0a r5.a
    #define D1 r2
    #define R1 r4
    #define R1_x2 r4_x2
    #define R1a r4.a
    #define c_specular_brightness c0
    #define c_view_perpendicular_color c1
    #define c_view_parallel_color c2
    #define c_multiplier c3
    #define c_scale c4

    ps_1_4

    def c_scale, 0.5019607843137254, 0.5019607843137254, 0.5019607843137254, 0.5019607843137254

    texld T0, t0
    texld T1, t1
    texld T2, t2
    texld T3, t3

	//combiner 0
    mov_x8_sat D0a, T3_bx2.b													// self-shadow mask (L.z*8)
    +dp3_sat R0.rgb, T0_bx2, T2_bx2								                // N.E

	//combiner 1
    mov_x8_sat D1.a, T2_bx2.b													// self-shadow mask (E.z*8)
    +mad_x2_sat R1.rgb, T0_bx2, R0, -T2_bias									// 2N(N.E)-E

  	//combiner 2
    dp3_sat R1.rgb, R1, T3_bx2													// s = 2(N.E)(N.L)-E.L
//  mul T1.rgb, T0, T1															// gel, specular mask (optionally used)

    //combiner 3
    lrp R0.rgb, R0.b, c_view_perpendicular_color, c_view_parallel_color		    // brightness
    +mul D1.a, D0a, D1.a														// self-shadow

    //combiner 4
    mul D1.rgb, D1.a, c_specular_brightness
    dp3_sat T0.rgb, T1, c_specular_brightness

    phase

    texld T1, t1

    //combiner 3
    mul R1a, R1.b, R1.b														    // s^2

    //combiner 4
    +mul R0.rgb, R0, T1													        // color
    mul R1a, R1a, R1a															// s^4
    +mul R0.rgb, R0, c_multiplier.z											    // gel ( active pixel mask )

	//combiner 5
	mul R1a, R1a, R1a															// s^8
	+mul R0.rgb, R0, D1														    // color, gel, self-shadow, brightness
	dp3_sat R1, R1, R1a         												// brightness, gel, s^8, active pixel mask

	//final combiner
    mul R0.rgb, R0, R1a
    mul r0.rgb, R0, c_scale
    + mov r0.a, R1.b

//    #undef T0
//    #undef T1
//    #undef T1_bx2
//    #undef T2
//    #undef T3
//    #undef R0
//    #undef R1
//    #undef c_specular_brightness
//    #undef c_view_perpendicular_color
//    #undef c_view_parallel_color
//    #undef c_multiplier
//    #undef c_scale
};

RAV */

Technique ps_1_4
{
    Pass P0
	{
		PixelShaderConstant[0] = (c_specular_brightness);
		PixelShaderConstant[1] = (c_view_perpendicular_color);
		PixelShaderConstant[2] = (c_view_parallel_color);
		PixelShaderConstant[3] = (c_multiplier);
		
        Texture[0]	= (Texture0);
        Texture[1]	= (Texture1);
        Texture[2]	= (Texture2);
        Texture[3]	= (Texture3);
        
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = asm
		{
			TEMP t0, t1, t2, t3, t4, t5, t6, t7, tmp0, tmp1, tmp2, r0, r1, r2, r3, r4, r5;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM color = {0.0, 0.0, 1.0, 1.0};
			PARAM c0 = program.env[0];
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			ATTRIB tc0 = fragment.texcoord[0];
			ATTRIB tc1 = fragment.texcoord[1];
			ATTRIB tc2 = fragment.texcoord[2];
			ATTRIB tc3 = fragment.texcoord[3];
			OUTPUT oC0 = result.color;
			PARAM c4 = {0.501961, 0.501961, 0.501961, 0.501961};
			TEX r0, tc0, texture[0], 2D;
			TEX r1, tc1, texture[1], 2D;
			TEX r2, tc2, texture[2], CUBE;
			TEX r3, tc3, texture[3], CUBE;
			MAD tmp0, r3, mulConst.r, -const.b;
			MOV r1.a, tmp0.b;
			MUL_SAT r1.a, r1, mulConst.b;
			MAD tmp0, r0, mulConst.r, -const.b;
			MAD tmp1, r2, mulConst.r, -const.b;
			DP3_SAT r5.rgb, tmp0, tmp1;
			MAD tmp0, r2, mulConst.r, -const.b;
			MOV r2.a, tmp0.b;
			MUL_SAT r2.a, r2, mulConst.b;
			MAD tmp0, r0, mulConst.r, -const.b;
			SUB tmp1, r2, const.g;
			MAD r4.rgb, tmp0, r5, -tmp1;
			MUL_SAT r4.rgb, r4, mulConst.r;
			MAD tmp1, r3, mulConst.r, -const.b;
			DP3_SAT r4.rgb, r4, tmp1;
			LRP r5.rgb, r5.b, c1, c2;
			MUL r2.a, r1.a, r2.a;
			MUL r2.rgb, r2.a, c0;
			DP3_SAT r0.rgb, r1, c0;
			TEX r1, tc1, texture[1], 2D;
			MUL r4.a, r4.b, r4.b;
			MUL r5.rgb, r5, r1;
			MUL r4.a, r4.a, r4.a;
			MUL r5.rgb, r5, c3.z;
			MUL r4.a, r4.a, r4.a;
			MUL r5.rgb, r5, r2;
			DP3_SAT r4, r4, r4.a;
			MUL r5.rgb, r5, r4.a;
			MUL r0.rgb, r5, c4;
			MOV r0.a, r4.b;
			
			#MOV r0, color;
			
			MOV oC0, r0;
		};
		//PixelShader = (PS_SpecularLightmapFlat_ps_1_4);
 	}
}

Technique ps_1_1
{
    Pass P0
	{
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
