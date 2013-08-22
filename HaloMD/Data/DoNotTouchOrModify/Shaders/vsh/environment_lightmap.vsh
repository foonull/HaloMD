!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[17] = { program.env[0..16] };
PARAM c95 = {0.0, 0.0, 0.0, 1.0};

ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];
ALIAS oT2 = result.texcoord[2];
ALIAS oT3 = result.texcoord[3];

ATTRIB v0 = vertex.attrib[0];  # position
ATTRIB v1 = vertex.attrib[1];  # normal
ATTRIB v2 = vertex.attrib[2];  # binormal
ATTRIB v3 = vertex.attrib[3];  # tangent
ATTRIB v4 = vertex.attrib[4];  # texcoord0
ATTRIB v7 = vertex.attrib[5];  # normal, channel 1 (lightmap)
ATTRIB v8 = vertex.attrib[6];  # texcoord0, channel 1

#DAJ defaults
MOV oD0, c95.w;
MOV oT0, c95;
MOV oT1, c95;
MOV oT2, c95;
MOV oT3, c95;

# (5) transform incident radiosity ------------------------------------------------------
MOV r10, v7; # we can't read two v[] regs in one instruction
DP3 r7.x, r10, v3;
DP3 r7.y, r10, v2;
DP3 r7.z, r10, v1;
DP3 r7.w, r10, r10;

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[0];
DP4 oPos.y, v0, c[1];
DP4 oPos.z, v0, c[2];
DP4 oPos.w, v0, c[3];

# (1) output radiosity accuracy ---------------------------------------------------------
MOV oD0.w, r7.w;

# (7) output texcoords ------------------------------------------------------------------
DP4 r10.x, v4, c[11];         # base map
DP4 r10.y, v4, c[12];
MUL oT0.xy, r10, c[10].xyyy;  # bump map
#DAJ MOV oT1.xy, v8;               # KLC - lightmap now in T1
MUL oT1.xy, r10, c[10].z;
MOV oT2.xy, v8;
RSQ r7.w, r7.w;
MUL oT3.xyz, r7.w, r7;

# (9) ouput fake lighting ---------------------------------------------------------------
#DAJ BUGFIX not used & causes flash
# MOV r7.xyz, c[16];
# DP3 r7.w, v1, c[13];
# MUL r7.w, r7.w, c[13].w;
# MAX r7.w, r7.w, v4.z;
# MAD r7.xyz, r7.w, c[15], r7;
# DP3 r7.w, v1, c[14];
# MUL r7.w, r7.w, c[14].w;
# MAX r7.w, r7.w, v4.z;
# MAD oD0.xyz, r7.w, c[15], r7;

END
