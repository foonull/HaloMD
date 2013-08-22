!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[11] = { program.env[0..10] };
PARAM c95 = {0.0, 0.0, 0.0, 1.0};
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oD1 = result.color.secondary;
ALIAS oT0 = result.texcoord[0];
ALIAS oFog = result.fogcoord;

ATTRIB v0 = vertex.attrib[0];
ATTRIB v4 = vertex.attrib[1];

#DAJ defaults
MOV oT0, c95;
MOV oFog, c95;
# MOV oD0, c95.w;	#DAJ redundant
# MOV oD1, c95.w;	#DAJ redundant

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[0];
DP4 oPos.y, v0, c[1];
DP4 oPos.z, v0, c[2];
DP4 oPos.w, v0, c[3];

# (1) output texcoords ------------------------------------------------------------------
MOV oT0.xy, v4;

# (1) output color ----------------------------------------------------------------------
MOV oD0.xyzw, c[10];

# (4) fog hack --------------------------------------------------------------------------
DP4 r8.z, v0, c[6];
MIN r8.z, r8.z, v4.w;
MUL r8.z, r8.z, c[9].x;
SLT oD1, r8.z, v4.w;

#DAJ COed by GearBox
# (2) atmospheric fog ----------------------------------------------------------------
#DP4 r8.z, r0, c[6];
#MUL r8.z, r8.z, c[9].x;
#SUB oFog, v4.w, r8.z;

END
