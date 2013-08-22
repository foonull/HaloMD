!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[32] = { program.env[0..31] };
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
MOV oT1, c95;
MOV oT2, c95;
MOV oT3, c95;
MOV oD1, c95.w;
MOV oFog, c95; 

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

# (0) compute eye vector ----------------------------------------------------------------
# (0) compute reflection vector ---------------------------------------------------------
# (0) compute point light 0 attenuation -------------------------------------------------
# (0) compute point light 1 attenuation -------------------------------------------------


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

# (1) planar fog density ----------------------------------------------------------------
MOV oD0.w, v4.z;

# (4) output texcoords ------------------------------------------------------------------
DP4 r10.x, v4, c[11]; # base map
DP4 r10.y, v4, c[12];
MOV oT0.xy, r10;                           # diffuse map
MUL oT1.xy, r10, c[10].xyyy;   # detail map
MOV oT2.xy, v4.z;
MOV oT3.xyz, v4.z;

#KLC - commenting out tint and fog

# (1) output reflection tint color ------------------------------------------------------
MOV oD1, v4.z;

# (2) atmospheric fog  ( for fixed function and ps 1.x)----------------------------------------------------------------
DP4 r8.z, r0, c[6];
SUB oFog.x, v4.w, r8.z;

END
