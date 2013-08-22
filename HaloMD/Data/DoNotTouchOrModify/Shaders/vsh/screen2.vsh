!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[24] = { program.env[0..23] };
PARAM c95 = {0.0, 0.0, 0.0, 1.0};
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];
ALIAS oT2 = result.texcoord[2];

ATTRIB v0 = vertex.attrib[0];
ATTRIB v9 = vertex.attrib[1];	# KLC - Color and texcoords were swapped in 405.
ATTRIB v4 = vertex.attrib[2];

#DAJ defaults
MOV oD0, c95.w;
MOV oT0, c95;
MOV oT1, c95;
MOV oT2, c95;

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[13];
DP4 oPos.y, v0, c[14];
DP4 oPos.z, v0, c[15];
DP4 oPos.w, v0, c[16];

# (1) output color ----------------------------------------------------------------------
MOV oD0.xyzw, v9;

# (5) texture coordinate 0 --------------------------------------------------------------
MUL r10.xy, c[19].xxxx, v0.xyyy;       # generate the texture coordinate
MAD r10.xy, v4, c[19].yyyy, r10.xyyy;   
MUL r10.xy, r10.xyyy, c[22].xyyy;      # multiply by the scale
ADD r10.xy, r10.xyyy, c[20].zwww;      # subtract the offset
MUL oT0.xy, r10.xyyy, c[17].xyyy;      # multiply in the texture scale and store

# (5) texture coordinate 1 --------------------------------------------------------------
MUL r10.xy, c[19].zzzz, v0.xyyy;       # generate the texture coordinate
MAD r10.xy, v4, c[19].wwww, r10.xyyy;
MUL r10.xy, r10.xyyy, c[22].zwww;      # multiply by the scale
ADD r10.xy, r10.xyyy, c[21].xyyy;      # subtract the offset
MUL oT1.xy, r10.xyyy, c[18].xyyy;      # multiply in the scale and store

# (5) texture coordinate 2 --------------------------------------------------------------
MUL r10.xy, c[20].xxxx, v0.xyyy;       # generate the texture coordinate
MAD r10.xy, v4, c[20].yyyy, r10.xyyy;
MUL r10.xy, r10.xyyy, c[23].xyyy;      # multiply by the scale
ADD r10.xy, r10.xyyy, c[21].zwww;      # subtract the offset
MUL oT2.xy, r10.xyyy, c[18].zwww;      # multiply in the scale and store
END
