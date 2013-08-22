!!ARBvp1.0
PARAM c[96] = { program.env[0..95] };
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;

ATTRIB v0 = vertex.attrib[0];
ATTRIB v9 = vertex.attrib[1];

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[0];
DP4 oPos.y, v0, c[1];
DP4 oPos.z, v0, c[2];
DP4 oPos.w, v0, c[3];

# (1) output color ----------------------------------------------------------------------
MOV oD0.xyzw, v9;
END
