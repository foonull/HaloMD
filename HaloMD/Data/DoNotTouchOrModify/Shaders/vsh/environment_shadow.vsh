!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[18] = { program.env[0..17] };
PARAM c95 = {0.0, 0.0, 0.0, 1.0};
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];

ATTRIB v0 = vertex.attrib[0];
ATTRIB v1 = vertex.attrib[1];
ATTRIB v2 = vertex.attrib[2];
ATTRIB v3 = vertex.attrib[3];
ATTRIB v4 = vertex.attrib[4];

#DAJ defaults
MOV oD0, c95.w;
MOV oT0, c95;
MOV oT1, c95;

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[0];
DP4 oPos.y, v0, c[1];
DP4 oPos.z, v0, c[2];
DP4 oPos.w, v0, c[3];

# (4) output texcoords ------------------------------------------------------------------
DP4 oT0.x, v0, c[13];
DP4 oT0.y, v0, c[14];
DP4 oT1.x, v0, c[15];
DP4 oT1.y, v0, c[16];

# (1) smooth shadows --------------------------------------------------------------------
DP3 oD0.w, -c[17], v1;

END
