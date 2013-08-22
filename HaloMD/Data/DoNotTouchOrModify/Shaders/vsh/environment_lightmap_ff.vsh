!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[96] = { program.env[0..95] };
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];
ALIAS oFog = result.fogcoord;

ATTRIB v0 = vertex.attrib[0];  # position
ATTRIB v1 = vertex.attrib[1];  # normal
ATTRIB v4 = vertex.attrib[2];  # texcoord0
ATTRIB v8 = vertex.attrib[3];  # texcoord0, channel 1

#DAJ defaults
MOV oD0, c[95].w;
MOV oT0, c[95];
MOV oT1, c[95];
MOV oFog, c[95];

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[0];
DP4 oPos.y, v0, c[1];
DP4 oPos.z, v0, c[2];
DP4 oPos.w, v0, c[3];

# (7) output texcoords ------------------------------------------------------------------
DP4 r10.x, v4, c[11];         # base map
DP4 r10.y, v4, c[12];
MUL oT0.xy, r10, c[10].xyyy;  # bump map
MOV oT1.xy, v8;               # KLC - lightmap now in T1

# (3) atmospheric fog ----------------------------------------------------------------
DP4 r8.z, v0, c[6];
MUL r8.z, r8.z, c[9].x;
MUL oFog.x, r8.z, state.fog.params.z;

END
