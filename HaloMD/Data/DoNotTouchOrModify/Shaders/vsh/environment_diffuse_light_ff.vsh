!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[96] = { program.env[0..95] };
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];
ALIAS oFog = result.fogcoord;

ATTRIB v0 = vertex.attrib[0];
ATTRIB v1 = vertex.attrib[1];
ATTRIB v2 = vertex.attrib[2];

#DAJ defaults
MOV oD0, c[95].w;
MOV oT0, c[95];
MOV oT1, c[95];
MOV oFog, c[95];

# (2) light vector ----------------------------------------------------------------------
ADD r4.xyz, c[13], -v0;
MOV r4.w, c[5].w;

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[0];
DP4 oPos.y, v0, c[1];
DP4 oPos.z, v0, c[2];
DP4 oPos.w, v0, c[3];

# (10) output texcoords -----------------------------------------------------------------
DP3 oT0.x, r4, c[14];
DP3 oT0.y, r4, c[15];
DP3 oT0.z, r4, c[16];
MAD oT1.xyz, r4, -c[13].w, r4.w;

# (3) atmospheric fog ----------------------------------------------------------------
DP4 r8.z, v0, c[6];
MUL r8.z, r8.z, c[9].x;
MUL oFog.x, r8.z, state.fog.params.z;

END
