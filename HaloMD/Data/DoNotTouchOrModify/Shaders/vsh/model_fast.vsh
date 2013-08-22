!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[95] = { program.env[0..94] };
PARAM c95 = {0.0, 0.0, 0.0, 1.0};
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oD1 = result.color.secondary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];
ALIAS oT2 = result.texcoord[2];
ALIAS oT3 = result.texcoord[3];
ALIAS oFog = result.fogcoord;

ADDRESS a0;

ATTRIB v0 = vertex.attrib[0];   # position
ATTRIB v1 = vertex.attrib[1];   # normal
ATTRIB v2 = vertex.attrib[2];   # binormal
ATTRIB v3 = vertex.attrib[3];   # tangent
ATTRIB v4 = vertex.attrib[4];   # texcoord0
ATTRIB v5 = vertex.attrib[5];   # blendindices
ATTRIB v6 = vertex.attrib[6];   # blendweight

#DAJ defaults
MOV oD0, c95.w;
MOV oT0, c95;
MOV oT1, c95;
MOV oT2, c95;
MOV oT3, c95;
MOV oD1, c95.w;
MOV oFog, c95; 

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

# (0) compute point light 0 attenuation -------------------------------------------------
# (0) compute point light 1 attenuation -------------------------------------------------


# (3) compute distant light 2 attenuation -----------------------------------------------
DP3 r8.x, r1,-c[21]; 
MUL r11.w, -r8.x, c[12].z;
MAX r8.x, r8.x, r11.w;

# (1) compute distant light 3 attenuation -----------------------------------------------
DP3 r8.y, r1,-c[23]; 

# (1) clamp all light attenuations ------------------------------------------------------
MAX r8.xy, r8, v4.z;

# (3) output light contributions --------------------------------------------------------
MOV r7.xyz, c[25];
MAD r7.xyz, r8.x, c[22], r7;
MAD oD0.xyz, r8.y, c[24], r7;

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, r0, c[0];
DP4 oPos.y, r0, c[1];
DP4 oPos.z, r0, c[2];
DP4 oPos.w, r0, c[3];

# (1) planar fog density ----------------------------------------------------------------
MOV oD0.w, v4.z;

# (6) output texcoords ------------------------------------------------------------------
DP4 r10.x, v4, c[11];               # base map
DP4 r10.y, v4, c[12];
MOV oT0.xy, r10;                       # diffuse map
MUL oT1.xy, r10, c[10].xyyy;   		# detail map 
MOV oT2.xy, r10;                       # MULtipurpose map
MOV oT3.xyz, r6;

#KLC - commenting out fog and tint

# (6) output reflection tint color ------------------------------------------------------
DP3 r5.w, r5, r5;             		# E.E
RSQ r5.w, r5.w;                     # 1/|E|
MUL r5, r5, r5.w;             		# E'= E/|E|
DP3 r5, r5, r1;                   	# N.E'
MUL r7, r5, c[13]; 					# perpendicular - parallel
ADD oD1.xyzw, r7, c[14];

# (1) atmospheric fog density (the only model shader with per-vertex atmospheric fog) ---
DP3 r8.z, r0, c[6];
ADD r8.z, r8.z, c[6].w;
SUB oFog.x, v4.w, r8.z;

END
