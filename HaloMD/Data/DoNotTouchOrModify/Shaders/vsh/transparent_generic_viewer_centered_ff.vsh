!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[96] = { program.env[0..95] };
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oD1 = result.color.secondary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];
ALIAS oT2 = result.texcoord[2];
ALIAS oT3 = result.texcoord[3];

ATTRIB v0 = vertex.attrib[0];
ATTRIB v1 = vertex.attrib[1];
ATTRIB v2 = vertex.attrib[2];
ATTRIB v3 = vertex.attrib[3];
ATTRIB v4 = vertex.attrib[4];

#DAJ defaults
MOV oD0, c[95].w;
MOV oT0, c[95];
MOV oT1, c[95];
MOV oT2, c[95];
MOV oT3, c[95];
MOV oD1, c[95].w;

# (1) eye vector ------------------------------------------------------------------------
ADD r5.xyz, -v0, c[4];

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[0];
DP4 oPos.y, v0, c[1];
DP4 oPos.z, v0, c[2];
DP4 oPos.w, v0, c[3];

# (12) output texcoords -----------------------------------------------------------------
# we have to compute the z- axis by the cross product of the x- and y- axes
MOV r11, c[14];
MUL r10, c[13].yzxw, r11.zxyw;
MAD r10,-r11.yzxw, c[13].zxyw, r10;
DP3 oT0.x, v1, c[13];
DP3 oT0.y, v1, c[14];
DP3 oT0.z, v1, r10;
DP4 oT1.x, v4, c[15];
DP4 oT1.y, v4, c[16];
DP4 oT2.x, v4, c[17];
DP4 oT2.y, v4, c[18];
DP4 oT3.x, v4, c[19];
DP4 oT3.y, v4, c[20];

# (3) atmospheric fog -------------------------------------------------------------------
DP4 r8.z, v0, c[6]
MUL r8.z, r8.z, c[9].x;
SUB r8.z, v2.w, r8.z;

# (6) fade ------------------------------------------------------------------------------

DP3 r10.x, v1, -c[5];
MAX r10.x, r10.x, -r10.x;
ADD r10.y, v4.w, -r10.x;
MUL r10.xy, r10, r8.w;
MUL oD0.w, r8.w, c[12].z; 		#no fade
MUL oD1.xyzw, r10.xxxy, c[12].z; # fade-when-perpendicular(w), parallel(xyz)

END

