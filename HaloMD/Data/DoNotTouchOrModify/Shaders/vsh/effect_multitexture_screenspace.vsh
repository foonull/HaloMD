!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[96] = { program.env[0..95] };
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];

ATTRIB v0 = vertex.attrib[0];
ATTRIB v9 = vertex.attrib[1];	#DAJ swap texcoord & diffuse in 405
ATTRIB v4 = vertex.attrib[2];

#DAJ defaults
MOV oD0, c[95].w;
MOV oT0, c[95];
MOV oT1, c[95];

# (4) transform position ----------------------------------------------------------------
DP4 r0.x, v0, c[26];
DP4 r0.y, v0, c[27];
DP4 r0.z, v0, c[28];
MOV r0.w, v4.w; # necessary because we can't use DPH

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, r0, c[0];
DP4 oPos.y, r0, c[1];
DP4 oPos.z, r0, c[2];
DP4 oPos.w, r0, c[3];

# (7) output texcoords ------------------------------------------------------------------
MOV oT0.xy, v4;
DP4 r10.x, r0, c[0];
DP4 r10.y, r0, c[1];
DP4 r10.zw,r0, c[3];
DP4 oT1.x, r10, c[15];
DP4 oT1.y, r10, c[16];


# (2) output color ----------------------------------------------------------------------
MOV oD0.xyz, v9;
MOV r11.w, v9;

# (17) fog ------------------------------------------------------------------------------
DP4 r8.x, r0, c[7];     # x
DP4 r8.y,   r0, c[8];     # y
DP4 r8.z,   r0, c[6]; # z
ADD r8.xy,  v4.w, -r8;                            # {1 - x, 1 - y}
MAX r8.xyz, r8, v4.z;                            # clamp to zero
MUL r8.xy,  r8, r8;                     # {(1 - x)^2, (1 - y)^2}
MIN r8.xyz, r8, v4.w;                             # clamp to one
ADD r8.x,   r8.x, r8.y;                 # (1 - x)^2 + (1 - y)^2
MIN r8.x,   r8, v4.w;                             # clamp to one
ADD r8.xy,  v4.w, -r8;                            # {1 - (1 - x)^2 - (1 - y)^2, 1 - (1 - y)^2}
MUL r8.xy,  r8, r8;                     # {(1 - (1 - x)^2 - (1 - y)^2)^2, (1 - (1 - y)^2)^2}
ADD r8.y,   r8.y, -r8.x;
MAD r8.w, c[9].y, r8.y, r8.x;
MUL r8.w, r8.w, c[9].z;                # Pf
MUL r8.z, r8.z, c[9].x; # Af
ADD r8.xyzw, -r8, v4.w;                           # (1 - Af),(1 - Pf)
MUL r10.w, r8.z, r8.w;           # (1 - Af)*(1 - Pf)

# (1) output fogged/diffuse alpha ----------------------------------------------------------------------
MUL oD0.w, r10.w, r11.w;

END
