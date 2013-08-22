!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[18] = { program.env[0..17] };
PARAM c95 = {0.0, 0.0, 0.0, 1.0};
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];

# ATTRIB v0 = vertex.position;
# ATTRIB v4 = vertex.texcoord[0];
# ATTRIB v9 = vertex.color.primary;

ATTRIB v0 = vertex.attrib[0];
ATTRIB v9 = vertex.attrib[1];	# KLC - Color and texcoord swapped in 405.
ATTRIB v4 = vertex.attrib[2];

#DAJ defaults
MOV oD0, c95.w;
MOV oT0, c95;

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[13];
DP4 oPos.y, v0, c[14];
DP4 oPos.z, v0, c[15];
DP4 oPos.w, v0, c[16];

# (1) output color ----------------------------------------------------------------------
MOV oD0.xyzw, v9;

# (1) output texcoord -------------------------------------------------------------------
MUL oT0.xy, v4, c[17];
END
