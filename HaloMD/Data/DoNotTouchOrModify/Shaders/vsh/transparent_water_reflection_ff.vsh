!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[96] = { program.env[0..95] };
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oFog = result.fogcoord;

ATTRIB v0 = vertex.attrib[0];  #position
ATTRIB v1 = vertex.attrib[1];  #normal
ATTRIB v2 = vertex.attrib[2];  #texcoord0

#DAJ defaults
MOV oD0, c[95].w;
MOV oT0, c[95];

# KLC - all commented out code mine

# (1) eye vector ------------------------------------------------------------------------
ADD r5.xyz, -v0, c[4];

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[0];
DP4 oPos.y, v0, c[1];
DP4 oPos.z, v0, c[2];
DP4 oPos.w, v0, c[3];

# (13) output texcoords -----------------------------------------------------------------
MAD oT0.xy, v2, c[10].xyyy, c[10].zwww; # reflection map

# (17) fog ------------------------------------------------------------------------------
DP4 oFog.x, v0, c[6];
END
