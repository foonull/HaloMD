!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[19] = { program.env[0..18] };
PARAM c95 = {0.0, 0.0, 0.0, 1.0};

ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oD1 = result.color.secondary;
ALIAS oT0 = result.texcoord[0];

ATTRIB v0 = vertex.attrib[0];   # position;
ATTRIB v9 = vertex.attrib[1];  	#DAJ swapped texcoord0 & color in 405
ATTRIB v4 = vertex.attrib[2];   

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[13];
DP4 oPos.y, v0, c[13];
DP4 oPos.z, v0, c[15];
DP4 oPos.w, v0, c[16];

#DAJ defaults
MOV oD0, c95.w;
MOV oT0, c95;
MOV oD1, c95.w;

# (1) output texcoords ------------------------------------------------------------------
MOV oT0.xy, v4;

# (2) output tint color -----------------------------------------------------------------
MOV oD0.xyzw, v9;
MOV oD1.w, c[18].x;

END
