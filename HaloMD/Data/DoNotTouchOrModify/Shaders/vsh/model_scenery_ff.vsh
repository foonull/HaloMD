!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[96] = { program.env[0..95] };
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];
ALIAS oFog = result.fogcoord;

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
MOV oFog, c[95]; 

# (0) build blended transform -----------------------------------------------------------

# (4) transform position ----------------------------------------------------------------
DP4 r0.x, v0, c[29];
DP4 r0.y, v0, c[30];
DP4 r0.z, v0, c[31];
MOV r0.w, v4.w; # necessary because we can't use DPH

# (3) transform normal ------------------------------------------------------------------
DP3 r1.x, v1, c[29];
DP3 r1.y, v1, c[30];
DP3 r1.z, v1, c[31];

# (3) compute distant light 2 attenuation -----------------------------------------------
DP3 r8.x, r1,-c[21]; 
MUL r11.w, -r8.x, c[12].z ;
MAX r8.x, r8.x, r11.w;

# (3) compute distant light 3 attenuation -----------------------------------------------
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

# (4) output texcoords ------------------------------------------------------------------
DP4 r10.x, v4, c[11]; # base map
DP4 r10.y, v4, c[12];
MOV oT0.xy, r10;                   # diffuse map
MOV oT1.xy, r10;                   # MULtipurpose map

# (2) atmospheric fog  ( for fixed function and ps 1.x)----------------------------------------------------------------
DP4 r8.z, r0, c[6];
MUL r8.z, r8.z, c[9].x;
MUL oFog.x, r8.z, state.fog.params.z;

END
