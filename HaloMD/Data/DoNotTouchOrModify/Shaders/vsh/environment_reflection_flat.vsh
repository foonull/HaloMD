!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;

PARAM c[13] = { program.env[0..12] };
PARAM c95 = {0.0, 0.0, 0.0, 1.0};

ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
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
MOV oD0, c95.w;
MOV oT0, c95;
MOV oT1, c95;
MOV oT2, c95;
MOV oT3, c95;

# (1) eye vector ------------------------------------------------------------------------
ADD r5.xyz, -v0, c[4];

# (3) compute reflection vector ---------------------------------------------------------
DP3 r6.x, r5, v1;
MUL r6.xyz, r6.x, v1;
# ORIG MAD r6.xyz, r6.xyz, c[4].w, -r5;
MAD r6.xyz, r6.xyzz, c[4].w, -r5;

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[0];
DP4 oPos.y, v0, c[1];
DP4 oPos.z, v0, c[2];
DP4 oPos.w, v0, c[3];

# (8) output texcoords ------------------------------------------------------------------
DP4 r10.x, v4, c[11]; # base map
DP4 r10.y, v4, c[12];
MUL oT0.xy, r10, c[10].xyyy; # bump map
DP3 oT1.x, -c[5], v3;  # non-local viewer eye vector in tangent space
DP3 oT1.y, -c[5], v2; # (dot with T0 to get fresnel term)
DP3 oT1.z, -c[5], v1;
MOV oT2.xyz, v1;                 # normal in worldspace
MOV oT3.xyz, r6;      # reflection cube map

END
