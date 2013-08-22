!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[96] = { program.env[0..95] };
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];

ADDRESS a0;

ATTRIB v0 = vertex.attrib[0];
ATTRIB v1 = vertex.attrib[1];
ATTRIB v2 = vertex.attrib[2];
ATTRIB v3 = vertex.attrib[3];
ATTRIB v4 = vertex.attrib[4];
ATTRIB v5 = vertex.attrib[5];
ATTRIB v6 = vertex.attrib[6];

#DAJ defaults
MOV oD0, c[95].w;
MOV oT0, c[95];
MOV oT1, c[95];

# (10) build blended transform (2 nodes) ------------------------------------------------
MUL r0.xy, v5, c[9].w;
ADD r0.xy, r0, c[5].w;
ARL a0.x, r0.x;      
MUL r4, v6.x, c[a0.x + 29];
MUL r5, v6.x, c[a0.x + 30];
MUL r6, v6.x, c[a0.x + 31];
ARL a0.x, r0.y;      
MAD r4, v6.y, c[a0.x + 29], r4;
MAD r5, v6.y, c[a0.x + 30], r5;
MAD r6, v6.y, c[a0.x + 31], r6;

# (4) transform position ----------------------------------------------------------------
DP4 r0.x, v0, r4;
DP4 r0.y, v0, r5;
DP4 r0.z, v0, r6;
MOV r0.w, v4.w; # necessary because we can't use DPH

# (6) transform normal ------------------------------------------------------------------
DP3 r1.x, v1, r4;
DP3 r1.y, v1, r5;
DP3 r1.z ,v1, r6;
DP3 r1.w, r1, r1;
RSQ r1.w, r1.w;
MUL r1.xyz, r1, r1.w;

# (1) eye vector ------------------------------------------------------------------------
ADD r5.xyz, -r0, c[4];

# (1) offset position -------------------------------------------------------------------
MAD r0.xyz, r1, c[13].z, r0;

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, r0, c[0];
DP4 oPos.y, r0, c[1];
DP4 oPos.z, r0, c[2];
DP4 oPos.w, r0, c[3];

# (6) output texcoords ------------------------------------------------------------------
DP4 oT0.x, v0, c[13];
DP4 oT0.y, v0, c[14];
DP4 oT0.z, v0, c[15];
DP4 oT1.x, v0, c[16];
DP4 oT1.y, v0, c[17];
DP4 oT1.z, v0, c[18];

# (6) output reflection tint color ------------------------------------------------------
DP3 r5.w, r5, r5;             # E.E
RSQ r5.w, r5.w;                         # 1/|E|
MUL r5, r5, r5.w;             # E'= E/|E|
DP3 r5, r5, r1;                   # N.E'

MUL r7, r5, c[12];         # perpendicular - parallel
ADD r10, r7, c[11];

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
MUL r11, r8.z, r8.w;           # (1 - Af)*(1 - Pf)

MOV oD0.xyz, r10;
MUL oD0.w, r10, r11;
END
