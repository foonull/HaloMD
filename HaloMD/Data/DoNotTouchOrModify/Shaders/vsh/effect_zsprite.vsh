!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[96] = { program.env[0..95] };
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];
ALIAS oT2 = result.texcoord[2];
ALIAS oT3 = result.texcoord[3];

ATTRIB v0 = vertex.attrib[0];	# position
ATTRIB v9 = vertex.attrib[1];	# color
ATTRIB v4 = vertex.attrib[2];	# texcoord0
ATTRIB v11 = vertex.attrib[3];	# texcoord1

#DAJ defaults
MOV oD0, c[95].w;
MOV oT0, c[95];
MOV oT1, c[95];
MOV oT2, c[95];
MOV oT3, c[95];

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

# (2) output easy texcoords -------------------------------------------------------------
MOV oT0.xy, v4;
MOV oT1.xy, v11;

DP4 r10.z, r0, c[19];

#----------------------------NOTE: c[18+0]= {q, -q*zn, r, znear}--------------------

# (6) clamp r if necessary to not go through znear --------------------------------------

# r10.y= (z-znear)
MOV r10.y,  r10.z;
ADD r10.y,  r10.y, -c[18].w;

# r11.z= (r >= (z-znear))?1.0:0.0
SGE r11.z,  c[18].z, r10.y;

# r11.w= (r11.z)?0:1
ADD r11.w, v4.w, r11.z;

# r10.w= new radius
MUL r10.w, r11.z,  r10.y;
MAD r10.w, r11.w, c[18].z, r10.w;

# DEBUG
#MOV r10.w, c[18].z;

# (3) T2= {0, -r*q, q*z-q*zn} ---------------------------------------------------------------
MOV oT2.xw, v4.z;
MUL oT2.y, -c[18].x, r10.w;
MAD oT2.z, c[18].x, r10.z, c[18].y;

# (3) T3= {0, -r, z} --------------------------------------------------------------------
MOV oT3.xw, v4.z;
MOV oT3.y, -r10.w;
MOV oT3.z, r10.z;

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
