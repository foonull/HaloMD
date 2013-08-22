Technique TDefault_ps
{
    Pass P0
    {
		CullMode			= Ccw;
		ColorWriteEnable	= Red|Green|Blue;
		AlphaBlendEnable	= True;
		SrcBlend			= DestAlpha;
		DestBlend			= One;
		BlendOp				= Add;
		AlphaTestEnable		= False;
		ZEnable				= True;
		ZFunc				= Equal;
		ZWriteEnable		= False;
	
		AddressU[0]			= Clamp;
		AddressV[0]			= Clamp;
		MagFilter[0]		= Linear;
		MinFilter[0]		= Linear;
		MipFilter[0]		= Linear;

		AddressU[1]			= Clamp;
		AddressV[1]			= Clamp;
		AddressW[1]			= Clamp;
		MagFilter[1]		= Linear;
		MinFilter[1]		= Point;
		MipFilter[1]		= Point;
		
		AddressU[2]			= Clamp;
		AddressV[2]			= Clamp;
		AddressW[2]			= Clamp;
		MagFilter[2]		= Linear;
		MinFilter[2]		= Point;
		MipFilter[2]		= Point;
		
		AddressU[3]			= Clamp;
		AddressV[3]			= Clamp;
		MagFilter[3]		= Linear;
		MinFilter[3]		= Linear;
		MipFilter[3]		= Linear;
		
		Texture[0]	= (Texture0);
		Texture[1]	= (Texture1);

		PixelShader			= asm
		{
			TEMP r0, r1;
			ATTRIB f0 = fragment.texcoord[0];
			ATTRIB f1 = fragment.texcoord[1];
			ATTRIB f2 = fragment.texcoord[2];
			ATTRIB f3 = fragment.texcoord[3];
			ATTRIB v0 = fragment.color.primary;
			
			PARAM half = { 0.5, 0.5, 0.5, 0.5 };
			PARAM two = { 2.0, 2.0, 2.0, 2.0 };
			PARAM one = { 1.0, 1.0, 1.0, 1.0 };
			PARAM c1 = program.env[1];
			PARAM c2 = program.env[2];
			PARAM c3 = program.env[3];
			TEMP oneminus;

			TEMP t0, t1, t2, t3;
			TEX t0, f0, texture[0], 2D;		# bump map
			TEX t1, f1, texture[1], 2D;	# dot product (type==bumped), normal vector (type!=bumped)
			TEX t2, f2, texture[2], CUBE;	# diffuse reflection cube map
			TEX t3, f3, texture[3], CUBE;  # specular reflection cube map
			OUTPUT oC0 = result.color;

			
			DP3_SAT	r0.rgb, t0, c0;
			SUB oneminus, one, r0;
			MAD r0.a, oneminus.b, c0.a, r0.b;
			
			MOV     oC0, r0;	#DAJ save off
			
			
		};
    }
}

Technique TDefault_no_ps
{
    Pass P0
    {
		CullMode			= Ccw;
		ColorWriteEnable	= Red|Green|Blue;
		AlphaBlendEnable	= True;
		SrcBlend			= DestAlpha;
		DestBlend			= One;
		BlendOp				= Add;
		AlphaTestEnable		= False;
		ZEnable				= True;
		ZFunc				= Equal;
		ZWriteEnable		= False;
	
		AddressU[0]			= Clamp;
		AddressV[0]			= Clamp;
		MagFilter[0]		= Linear;
		MinFilter[0]		= Linear;
		MipFilter[0]		= Linear;

		AddressU[1]			= Clamp;
		AddressV[1]			= Clamp;
		AddressW[1]			= Clamp;
		MagFilter[1]		= Linear;
		MinFilter[1]		= Point;
		MipFilter[1]		= Point;
		
		AddressU[2]			= Clamp;
		AddressV[2]			= Clamp;
		AddressW[2]			= Clamp;
		MagFilter[2]		= Linear;
		MinFilter[2]		= Point;
		MipFilter[2]		= Point;
		
		AddressU[3]			= Clamp;
		AddressV[3]			= Clamp;
		MagFilter[3]		= Linear;
		MinFilter[3]		= Linear;
		MipFilter[3]		= Linear;
		
		ColorOp[0]			= SelectArg1;
		ColorArg1[0]		= Texture;
		AlphaOp[0]			= SelectArg1;
		AlphaArg1[0]		= Texture;

		ColorOp[1]			= SelectArg1;
		ColorArg1[1]		= Texture;
		ColorArg2[1]		= Current;
		AlphaOp[1]			= SelectArg1;
		AlphaArg1[1]		= Texture;
		AlphaArg2[1]		= Current;

		ColorOp[2]			= SelectArg1;
		ColorArg1[2]		= Texture;
		ColorArg2[2]		= Current;
		AlphaOp[2]			= SelectArg1;
		AlphaArg1[2]		= Texture;
		AlphaArg2[2]		= Current;

		ColorOp[3]			= SelectArg1;
		ColorArg1[3]		= Texture;
		ColorArg2[3]		= Current;
		AlphaOp[3]			= SelectArg1;
		AlphaArg1[3]		= Texture;
		AlphaArg2[3]		= Current;

		ColorOp[4]			= Disable;
		AlphaOp[4]			= Disable;
    }
}