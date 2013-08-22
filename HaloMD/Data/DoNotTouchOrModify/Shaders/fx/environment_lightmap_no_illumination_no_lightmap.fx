Texture	Texture0;
Texture	Texture1;
Texture	Texture2;
Texture	Texture3;

/* DAJ
sampler TexSampler0 = sampler_state
{
    Texture		= (Texture0);
};

sampler TexSampler1 = sampler_state
{
    Texture		= (Texture1);
};

sampler TexSampler2 = sampler_state
{
    Texture		= (Texture2);
};

sampler TexSampler3 = sampler_state
{
    Texture		= (Texture3);
};

half4 c_material_color;

half4 LightmapNoIlluminationNoLightmap(
    half4 Diff : COLOR0,
    half2 Tex0  : TEXCOORD0,
    half2 Tex1  : TEXCOORD1,
    half2 Tex2  : TEXCOORD2,
    half3 Tex3  : TEXCOORD3) : COLOR
{
	half4 bump_color = tex2D(TexSampler0,Tex0);
	half4 normal_color = texCUBE(TexSampler3, Tex3);

	////////////////////////////////////////////////////////////
	// calculate bump attenuation
	////////////////////////////////////////////////////////////
	half bump_attenuation = dot((2*bump_color)-1, (2*normal_color)-1);
	bump_attenuation = (bump_attenuation * Diff.a) + 1-Diff.a;
	
	half3 lightmap_color = c_material_color + ( bump_attenuation * c_material_color );
	
	half4 final_color = half4( lightmap_color, bump_color.a );
	
    return final_color;
}

Technique ps_2_0
{
    Pass P0
	{
		ColorOp[0]	= Disable;
		AlphaOp[0]	= Disable;
		
		PixelShader = compile PS_2_0_TARGET LightmapNoIlluminationNoLightmap();
 	}
}

PixelShader PS_LightmapNoIlluminationNoLightmap_ps_1_4 = asm
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
*/

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
		
		PixelShader = asm
		{
			TEMP t0, t1, t2, t3, t4, t5, t6, t7, tmp0, tmp1, tmp2, r0, r1, r2;
			PARAM const = {0.0, 0.5, 1.0, 2.0};
			PARAM mulConst = {2.0, 4.0, 8.0, 0.0};
			PARAM divConst = {0.5, 0.25, 0.125, 0.0};
			PARAM c0 = program.env[0];
			ATTRIB tc0 = fragment.texcoord[0];
			ATTRIB tc3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color;
			OUTPUT oC0 = result.color;
			TEX r1, tc0, texture[0], 2D;
			TEX r0, tc3, texture[3], CUBE;
			MAD tmp0, r0, mulConst.r, -const.b;
			MAD tmp1, r1, mulConst.r, -const.b;
			DP3_SAT r2, tmp0, tmp1;
			SUB tmp1, const.b, v0;
			MAD r2, r2, v0.a, tmp1.a;
			MAD r0.rgb, r2, c0, c0;
			MOV r0.a, r0.a;
			MOV oC0, r0;
		};
		//PixelShader = (PS_LightmapNoIlluminationNoLightmap_ps_1_4);
 	}
}


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
		
		PixelShader	= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color.primary;

			PARAM c0 = program.env[0];
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };

			OUTPUT oC0 = result.color;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;
			TEX t1, f1, texture[1], 2D;
			TEX t2, f2, texture[2], 2D;
			TEX t3, f3, texture[3], CUBE;
			
			TEMP t0_bx2, t3_bx2;
			SUB t0_bx2, t0, half;			
			MUL t0_bx2, t0_bx2, two;

			SUB t3_bx2, t3, half;			
			MUL t3_bx2, t3_bx2, two;
			DP3_SAT r1, t0_bx2, t3_bx2;
			
#DAJ		MAD_SAT r0.a, v0.a, r1.b, 1-v0.a;
			TEMP oneminus;
			SUB oneminus.x, one.a, v0.a;
			MAD_SAT r0.a, v0.a, r1.b, oneminus.x;
			
			MUL_SAT r1, r0.a, c0;
			MAD r0.rgb, t2, r1, c0;
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
