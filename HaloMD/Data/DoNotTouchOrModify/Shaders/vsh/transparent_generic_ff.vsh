!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[96] = { program.env[0..95] };
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];
ALIAS oT2 = result.texcoord[2];
ALIAS oT3 = result.texcoord[3];
ALIAS oFog = result.fogcoord;

ATTRIB v0 = vertex.attrib[0];
ATTRIB v1 = vertex.attrib[1];
ATTRIB v2 = vertex.attrib[2];
ATTRIB v3 = vertex.attrib[3];
ATTRIB v4 = vertex.attrib[4];

#DAJ defaults
MOV oD0, c[95].w;
MOV oT0, c[95];
MOV oT1, c[95];
MOV oT2, c[95];
MOV oT3, c[95];
MOV oFog, c[95];

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[0];
DP4 oPos.y, v0, c[1];
DP4 oPos.z, v0, c[2];
DP4 oPos.w, v0, c[3];

# (8) output texcoords -----------------------------------------------------------------
DP4 oT0.x, v4, c[13];
DP4 oT0.y, v4, c[14];
DP4 oT1.x, v4, c[15];
DP4 oT1.y, v4, c[16];
DP4 oT2.x, v4, c[17];
DP4 oT2.y, v4, c[18];
DP4 oT3.x, v4, c[19];
DP4 oT3.y, v4, c[20];

# (3) atmospheric fog -------------------------------------------------------------------
DP4 r8.z, v0, c[6];
MUL r8.z, r8.z, c[9].x;
SUB oFog.x, v4.w, r8.z;

END
