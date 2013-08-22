!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;

PARAM c[13] = { program.env[0..12] };
PARAM c95 = {0.0, 0.0, 0.0, 1.0};

ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];
ALIAS oT2 = result.texcoord[2];
ALIAS oT3 = result.texcoord[3];
ALIAS oT4 = result.texcoord[4];

ATTRIB v0 = vertex.attrib[0];
ATTRIB v1 = vertex.attrib[1];
ATTRIB v2 = vertex.attrib[2];
ATTRIB v3 = vertex.attrib[3];
ATTRIB v4 = vertex.attrib[4];

#DAJ defaults
MOV oT0, c95;
MOV oT1, c95;
MOV oT2, c95;
MOV oT3, c95;
MOV oT4, c95;

# (1) eye vector ------------------------------------------------------------------------
ADD r5.xyz, -v0, c[4];

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[0];
DP4 oPos.y, v0, c[1];
DP4 oPos.z, v0, c[2];
DP4 oPos.w, v0, c[3];

# (15) output texcoords -----------------------------------------------------------------
DP4 r10.x, v4, c[11]; # base map
DP4 r10.y, v4, c[12];
MUL oT0.xy, r10, c[10].xyyy; # bump map
MOV oT1.x, v3.x;
MOV oT1.y, v2.x;
MOV oT1.z, v1.x;
MOV oT2.x, v3.y;
MOV oT2.y, v2.y;
MOV oT2.z, v1.y;
MOV oT3.x, v3.z;
MOV oT3.y, v2.z;
MOV oT3.z, v1.z;

#DAJ NEVER comes out right in the pixel shader use T4 instead
#NVIDIA -- these are necessary for nv_register_combiners path
MOV oT1.w, r5.x;
MOV oT2.w, r5.y;
MOV oT3.w, r5.z;
MOV oT4.x, r5.x;
MOV oT4.y, r5.y;
MOV oT4.z, r5.z;

END
