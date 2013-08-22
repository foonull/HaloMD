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
ATTRIB v3 = vertex.attrib[3];
ATTRIB v4 = vertex.attrib[4];

#DAJ defaults
MOV oD0, c[95].w;
MOV oT0, c[95];
MOV oT1, c[95];
MOV oFog, c[95];

# (1) eye vector ------------------------------------------------------------------------
ADD r5.xyz, -v0, c[4];

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[0];
DP4 oPos.y, v0, c[1];
DP4 oPos.z, v0, c[2];
DP4 oPos.w, v0, c[3];

# (4) output texcoords ------------------------------------------------------------------
MOV oT0.xy, v4; # opacity map
# KLC - commenting out for now
DP3 oT1.x, r5, v3; # eye vector in bump map pace
DP3 oT1.y, r5, v2;
DP3 oT1.z, r5, v1;

# (2) atmospheric fog ----------------------------------------------------------------
DP4 oFog.x, v0, c[6];
END
