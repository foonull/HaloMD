!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[95] = { program.env[0..94] };
PARAM c95 = {0.0, 0.0, 0.0, 1.0};
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];

ADDRESS a0;

ATTRIB v0 = vertex.attrib[0];
ATTRIB v1 = vertex.attrib[1];
ATTRIB v2 = vertex.attrib[2];
ATTRIB v3 = vertex.attrib[3];
ATTRIB v4 = vertex.attrib[4];
ATTRIB v5 = vertex.attrib[5];
ATTRIB v6 = vertex.attrib[6];

#DAJ defaults
MOV oD0, c95.w;
MOV oT0, c95;

# (10) build blended transform (2 nodes) ------------------------------------------------
MUL r0.xy, v5, c[9].w;
ADD r0.xy, r0, c[5].w;
ARL a0.x, r0.x;
MUL r4, v6.x, c[a0.x + 29];
MUL r5, v6.x, c[a0.x + 30];
MUL r6, v6.x, c[a0.x + 31];
ARL a0.x, r0.y;
MAD r4, v6.y, c[a0.x + 29], r4;
MAD r5, v6.y, c[a0.x + 30], r5;
MAD r6, v6.y, c[a0.x + 31], r6;

# (4) transform position ----------------------------------------------------------------
DP4 r0.x, v0, r4;
DP4 r0.y, v0, r5;
DP4 r0.z, v0, r6;
MOV r0.w, v4.w; # necessary because we can't use DPH

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, r0, c[13];
DP4 oPos.y, r0, c[14];
DP4 oPos.z, r0, c[15];
DP4 oPos.w, r0, c[16];

# (2) base map --------------------------------------------------------------------------
DP4 oT0.x, v4, c[11]; # base map (used for alpha-testing)
DP4 oT0.y, v4, c[12];


END
