!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;

PARAM c[21] = { program.env[0..20] };
PARAM c95 = {0.0, 0.0, 0.0, 1.0};

ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];
ALIAS oT2 = result.texcoord[2];
ALIAS oT3 = result.texcoord[3];

ATTRIB v0 = vertex.attrib[0];
ATTRIB v9 = vertex.attrib[1];	#DAJ swap texcoord & diffuse in 405
ATTRIB v4 = vertex.attrib[2];

#DAJ defaults
MOV oT0, c95; 
MOV oT1, c95; 
MOV oT2, c95; 
MOV oT3, c95; 

# (1) output homogeneous point ----------------------------------------------------------
MOV oPos, v0;

# (1) output color ----------------------------------------------------------------------
# MOV oD0, v9; #DAJ not in original

# (8) output texcoords ------------------------------------------------------------------
DP4 oT0.x, v4, c[13];
DP4 oT0.y, v4, c[14];
DP4 oT1.x, v4, c[15];
DP4 oT1.y, v4, c[16];
DP4 oT2.x, v4, c[17];
DP4 oT2.y, v4, c[18];
DP4 oT3.x, v4, c[19];
DP4 oT3.y, v4, c[20];
END
