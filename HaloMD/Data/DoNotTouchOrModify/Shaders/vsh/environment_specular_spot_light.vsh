!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;

PARAM c[18] = { program.env[0..17] };
PARAM c95 = {0.0, 0.0, 0.0, 1.0};

ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oD1 = result.color.secondary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];
ALIAS oT2 = result.texcoord[2];
ALIAS oT3 = result.texcoord[3];

ATTRIB v0 = vertex.attrib[0];
ATTRIB v1 = vertex.attrib[1];
ATTRIB v2 = vertex.attrib[2];
ATTRIB v3 = vertex.attrib[3];
ATTRIB v4 = vertex.attrib[4];

#DAJ defaults
MOV oD0, c95.w;
MOV oT0, c95;
MOV oT1, c95;
MOV oT2, c95;
MOV oT3, c95;
MOV oD1, c95.w;

# (2) light vector ----------------------------------------------------------------------
ADD r4.xyz, c[13], -v0;
MOV r4.w, v4.z;

# (1) eye vector ------------------------------------------------------------------------
ADD r5.xyz, c[4], -v0;

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[0];
DP4 oPos.y, v0, c[1];
DP4 oPos.z, v0, c[2];
DP4 oPos.w, v0, c[3];

# (12) output texcoords -----------------------------------------------------------------
DP4 r10.x, v4, c[11]; # base map
DP4 r10.y, v4, c[12];
MUL oT0.xy, r10, c[10].xyyy; # bump map
DP3 oT1.x, r4, c[14];
DP3 oT1.y, r4, c[15];
DP3 oT1.z, r4, c[16];
DP3 oT2.x, r5, v3;
DP3 oT2.y, r5, v2;
DP3 oT2.z, r5, v1;
DP3 oT3.x, r4, v3;
DP3 oT3.y, r4, v2;
DP3 oT3.z, r4, v1;

# (1) output fog (distance attenuation) -------------------------------------------------
DP4 oD1.w, -r4, c[17];

# (1) make d3d happy by filling all of D1------------------------------------------------
MOV oD1.xyz, v4.z;

END
