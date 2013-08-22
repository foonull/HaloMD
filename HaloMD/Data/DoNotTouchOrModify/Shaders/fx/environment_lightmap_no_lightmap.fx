Texture	Texture0;
Texture	Texture1;
Texture	Texture2;
Texture	Texture3;

/* DAJ
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

half4 c_material_color;

half4 LightmapNoLightmap(
    half4 Diff : COLOR0,
    half2 Tex0  : TEXCOORD0,
    half2 Tex1  : TEXCOORD1,
    half2 Tex2  : TEXCOORD2,
    half3 Tex3  : TEXCOORD3) : COLOR
{
	half4 bump_color = tex2D(TexSampler0,Tex0);
	half3 lightmap_color = tex2D(TexSampler2, Tex2);
	half4 normal_color = texCUBE(TexSampler3, Tex3);

	////////////////////////////////////////////////////////////
	// calculate bump attenuation
	////////////////////////////////////////////////////////////
	half bump_attenuation = dot((2*bump_color)-1, (2*normal_color)-1);
	bump_attenuation = (bump_attenuation * Diff.a) + 1-Diff.a;

	lightmap_color = c_material_color + ( bump_attenuation * c_material_color );
	
	half4 final_color = half4( lightmap_color, bump_color.a);
	
    return final_color;
}

Technique ps_2_0
{
    Pass P0
	{
		ColorOp[0]			= Disable;
		AlphaOp[0]			= Disable;
		
		PixelShader = compile PS_2_0_TARGET LightmapNoLightmap();
 	}
}

PixelShader PS_LightmapNoLightmap_ps_1_4 = asm
{
    #define bump_color r0
    #define bump_color_bx2 r0_bx2
    #define normal_color r1
    #define normal_color_bx2 r1_bx2
    #define bump_attenuation r2
    #define Diff v0
    #define material_color c0

    ps_1_4

    texld normal_color, t0
    texld bump_color, t3

    dp3_sat bump_attenuation, bump_color_bx2, normal_color_bx2
    mad bump_attenuation, bump_attenuation, Diff.a, 1-Diff.a
    mad r0.rgb, bump_attenuation, material_color, material_color
    + mov r0.a, bump_color.a

//    #undef bump_color
//    #undef bump_color_bx2
//    #undef normal_color
//    #undef normal_color_bx2
//    #undef bump_attenuation
//    #undef Diff
//    #undef material_color
};

Technique ps_1_4
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
		
		PixelShader = (PS_LightmapNoLightmap_ps_1_4);
 	}
}
*/
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
			TEMP r0, r1, r2;
		
			PARAM c0 = program.env[0];	# c0 - material color
			PARAM c1 = program.env[1];	# c1 - plasma animation
			PARAM c2 = program.env[2];	# c2 - primary color
			PARAM c3 = program.env[3];	# c3 - secondary color
			PARAM c4 = program.env[4];	# c4 - plasma on color
			PARAM c5 = program.env[5];	# c5 - plasma off color
			
			PARAM c6 = { 1.0, 0.0, 0.0, 0.0	};	# c6 - primary mask
			PARAM c7 = { 0.0, 1.0, 0.0, 1.0	};	# c7 - secondary mask
			
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color.primary;
			ATTRIB v1 = fragment.color.secondary;
			
			TEMP t0, t1, t2, t3;
			TEMP t0_bx2, t3_bx2;
			TEX t0, f0, texture[0], 2D;
			TEX t1, f1, texture[1], 2D;
			TEX t2, f2, texture[2], 2D;
			TEX t3, f3, texture[3], CUBE;

			OUTPUT oC0 = result.color;
			
			SUB t0_bx2, t0, half;			
			MUL t0_bx2, t0_bx2, two;

			SUB t3_bx2, t3, half;			
			MUL t3_bx2, t3_bx2, two;
			DP3_SAT r0, t0_bx2, t3_bx2;
			
			MOV r0.a, r0.b;
#DAJ		MAD r0, r0.a, v0.a, 1-v0.a;
			TEMP oneminus;
			SUB oneminus.a, c7.a, v0.a;
			MAD r0, r0.a, v0.a, oneminus.a;
			
			MAD r0.rgb, r0, c0, c0;
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
