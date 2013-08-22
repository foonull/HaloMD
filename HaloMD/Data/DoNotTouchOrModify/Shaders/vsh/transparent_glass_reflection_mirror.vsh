!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[96] = { program.env[0..95] };
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
MOV oD0, c[95].w;
MOV oT0, c[95];
MOV oT1, c[95];
MOV oT2, c[95];
MOV oT3, c[95];

# (4) output homogeneous point ----------------------------------------------------------
# ATI: make sure we write the position to r0 because we
#      need it for the mirror calculation
DP4 r0.x, v0, c[0];
DP4 r0.y, v0, c[1];
DP4 r0.z, v0, c[2];
DP4 r0.w, v0, c[3];
MOV oPos, r0;

# (4) output texcoords ------------------------------------------------------------------
# (NOTE - since glass is always planar, we could get rid of the normalization cube map.
#  more generally, we could switch to a "planar" version of this vertex shader if the
#  type is FLAT and the geometry is planar, -or- if the type is MIRROR since we assume the
#  geometry is planar)
MUL oT0.xy, v4, c[10].xyyy; 
DP3 oT1.x, -c[5], v3; # non-local viewer eye vector in tangent space
DP3 oT1.y, -c[5], v2; # (dot with T0 to get fresnel term)
DP3 oT1.z, -c[5], v1;
MOV oT2.xyz, v1;                # normal vector in worldspace

# (6) mirror ----------------------------------------------------------------------------
ADD r0, r0.xyww, r0.w; #range-compress texcoords
MOV oT3.xy, r0;
MOV oT3.zw, r0.w; #perspective projection

# (17) fog ------------------------------------------------------------------------------
DP4 r8.x, v0, c[7];     # x
DP4 r8.y,   v0, c[8];     # y
DP4 r8.z,   v0, c[6]; # z
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
MUL oD0.w, r8.z, r8.w;           # (1 - Af)*(1 - Pf)
MOV oD0.xyz, c[12].y;
END
