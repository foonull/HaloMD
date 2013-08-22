!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[96] = { program.env[0..95] };
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oD1 = result.color.secondary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];
ALIAS oT2 = result.texcoord[2];
ALIAS oT3 = result.texcoord[3];

ADDRESS a0;

ATTRIB v0 = vertex.attrib[0];
ATTRIB v1 = vertex.attrib[1];
ATTRIB v2 = vertex.attrib[2];
ATTRIB v3 = vertex.attrib[3];
ATTRIB v4 = vertex.attrib[4];
ATTRIB v5 = vertex.attrib[5];
ATTRIB v6 = vertex.attrib[6];

#DAJ defaults
MOV oD0, c[95].w;
MOV oT0, c[95];
MOV oT1, c[95];
MOV oT2, c[95];
MOV oT3, c[95];
# MOV oD1, c[95].w;

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

# (4) transform normal ------------------------------------------------------------------
DP3 r1.x, v1, r4;
DP3 r1.y, v1, r5;
DP3 r1.z ,v1, r6;

MUL r1.xyz, r1, c[10].w; # this goes away if we handle double-sided materials during import

# (1) eye vector ------------------------------------------------------------------------
ADD r5.xyz, -r0, c[4];

# (3) compute reflection vector ---------------------------------------------------------
DP3 r6.x, r5, r1;
MUL r6.xyz, r6.x, r1;
MAD r6.xyz, r6.xyzz, c[4].w, -r5;

# (9) compute point light 0 attenuation -------------------------------------------------
ADD r4.xyz, c[15], -r0;
DP3 r4.w, r4, r4;
RSQ r10.w, r4.w;
MUL r4.xyz, r4, r10.w;
MAD r8.x, r4.w, -c[15].w, v4.w;
DP3 r9.x, r4, r1;
DP3 r10.w, r4, -c[16];
MUL r10.w, r10.w, c[16].w;
ADD r8.z, r10.w, c[17].w;

# (9) compute point light 1 attenuation -------------------------------------------------
ADD r4.xyz, c[18], -r0;
DP3 r4.w, r4, r4;
RSQ r10.w, r4.w;
MUL r4.xyz, r4, r10.w;
MAD r8.y, r4.w, -c[18].w, v4.w;
DP3 r9.y, r4, r1 ;
DP3 r10.w, r4, -c[19];
MUL r10.w, r10.w, c[19].w;
ADD r9.z, r10.w, c[20].w;


# (3) compute distant light 2 attenuation -----------------------------------------------
DP3 r8.w, r1,-c[21]; 
MUL r11.w, -r8.w, c[12].z ;
MAX r8.w, r8.w, r11.w;

# (1) compute distant light 3 attenuation -----------------------------------------------
DP3 r9.w, r1,-c[23]; 

# (3) clamp all light attenuations ------------------------------------------------------

MAX r8, r8, v4.z;
MAX r9, r9, v4.z;
MIN r9, r9, v4.w;

# (8) output light contributions --------------------------------------------------------
MOV r7.xyz, c[25];
MUL r10.xy, r8, r9;
MUL r10.x, r10.x, r8.z;
MUL r10.y, r10.y, r9.z;
MAD r7.xyz, r10.x, c[17], r7;
MAD r7.xyz, r10.y, c[20], r7;
MAD r7.xyz, r8.w, c[22], r7;
MAD oD0.xyz, r9.w, c[24], r7;

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, r0, c[0];
DP4 oPos.y, r0, c[1];
DP4 oPos.z, r0, c[2];
DP4 oPos.w, r0, c[3];

# (1) planar fog density ----------------------------------------------------------------
MOV oD0.w, v4.z;

# (6) output texcoords ------------------------------------------------------------------
DP4 r10.x, v4, c[11]; # base map
DP4 r10.y, v4, c[12];
MOV oT0.xy, r10;                    # diffuse map
MUL oT1.xy, r10, c[10].xyyy;        # detail map 
MOV oT2.xy, r10;                    # MULtipurpose map
MOV oT3.xyz, r6;

# KLC - commenting out tint

# (6) output reflection tint color ------------------------------------------------------
DP3 r5.w, r5, r5;             # E.E
RSQ r5.w, r5.w;                         # 1/|E|
MUL r5, r5, r5.w;             # E'= E/|E|
DP3 r5, r5, r1;                   # N.E'
MUL r7, r5, c[13]; # perpendicular - parallel
ADD oD1.xyzw, r7, c[14];

END
