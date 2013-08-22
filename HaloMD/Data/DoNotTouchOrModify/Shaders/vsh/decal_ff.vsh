!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[96] = { program.env[0..95] };
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];

ATTRIB v0 = vertex.attrib[0];
ATTRIB v4 = vertex.attrib[1];

#DAJ defaults
MOV oT0, c[95];

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[0];
DP4 oPos.y, v0, c[1];
DP4 oPos.z, v0, c[2];
DP4 oPos.w, v0, c[3];

# (1) output texcoords ------------------------------------------------------------------
MOV oT0.xy, v4;

# (1) output color ----------------------------------------------------------------------
MOV oD0.xyzw, c[10];

END
