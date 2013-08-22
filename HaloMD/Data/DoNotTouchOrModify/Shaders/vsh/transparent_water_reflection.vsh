!!ARBvp1.0

# KLC --- Changed to combine opacity and reflection in a single pass ---

TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;

PARAM c[11] = { program.env[0..10] };
PARAM c95 = {0.0, 0.0, 0.0, 1.0};

ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];
ALIAS oT2 = result.texcoord[2];
ALIAS oT3 = result.texcoord[3];
ALIAS oT4 = result.texcoord[4];
ALIAS oT5 = result.texcoord[5];
ALIAS oT6 = result.texcoord[6];
ALIAS oFog = result.fogcoord;

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
MOV oT4, c95;
MOV oT5, c95;
MOV oT6, c95;
MOV oFog, c95;

# KLC - all commented out code mine

# (1) eye vector ------------------------------------------------------------------------
ADD r5.xyz, -v0, c[4];

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[0];
DP4 oPos.y, v0, c[1];
DP4 oPos.z, v0, c[2];
DP4 oPos.w, v0, c[3];

# (13) output texcoords -----------------------------------------------------------------
MAD oT0.xy, v4, c[10].xyyy, c[10].zwww; # bump map
MOV oT1.x, v3.x;
MOV oT1.y, v2.x;
MOV oT1.z, v1.x;
MOV oT2.x, v3.y;
MOV oT2.y, v2.y;
MOV oT2.z, v1.y;
MOV oT3.x, v3.z;
MOV oT3.y, v2.z;
MOV oT3.z, v1.z;
# MOV oT1.w, r5.x;
# MOV oT2.w, r5.y;
# MOV oT3.w, r5.z;

MOV oT4, r5;	#DAJ

# (4) output texcoords ------------------------------------------------------------------
MOV oT5.xy, v4; # opacity map

DP3 oT6.x, r5, v3; # eye vector in bump map space
DP3 oT6.y, r5, v2;
DP3 oT6.z, r5, v1;

# (1) atmospheric fog ----------------------------------------------------------------
DP4 oFog.x, v0, c[6];

# (17) fog ------------------------------------------------------------------------------
DP4 r8.x, v0, c[7];					# x
DP4 r8.y,   v0, c[8];					# y
DP4 r8.z,   v0, c[6];					# z
ADD r8.xy,  v4.w, -r8;                # {1 - x, 1 - y}
MAX r8.xyz, r8, v4.z;                 # clamp to zero
MUL r8.xy,  r8, r8;                   # {(1 - x)^2, (1 - y)^2}
MIN r8.xyz, r8, v4.w;                 # clamp to one
ADD r8.x,   r8.x, r8.y;               # (1 - x)^2 + (1 - y)^2
MIN r8.x,   r8, v4.w;                 # clamp to one
ADD r8.xy,  v4.w, -r8;                # {1 - (1 - x)^2 - (1 - y)^2, 1 - (1 - y)^2}
MUL r8.xy,  r8, r8;                   # {(1 - (1 - x)^2 - (1 - y)^2)^2, (1 - (1 - y)^2)^2}
ADD r8.y,   r8.y, -r8.x;
MAD r8.w, c[9].y, r8.y, r8.x;
MUL r8.w, r8.w, c[9].z;               # Pf
MUL r8.z, r8.z, c[9].x;				# Af
ADD r8.xyzw, -r8, v4.w;               # (1 - Af),(1 - Pf)
MUL oD0.w, r8.z, r8.w; 				# (1 - Af)*(1 - Pf)
END
