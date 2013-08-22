!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[96] = { program.env[0..95] };
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];
ALIAS oT2 = result.texcoord[2];

ADDRESS a0;

ATTRIB v0 = vertex.attrib[0];
ATTRIB v1 = vertex.attrib[1];
ATTRIB v2 = vertex.attrib[2];
ATTRIB v3 = vertex.attrib[3];
ATTRIB v4 = vertex.attrib[4];
ATTRIB v5 = vertex.attrib[5];
ATTRIB v6 = vertex.attrib[6];

#DAJ defaults

# NVIDIA changed, due to vertex shader scaling of EMBM constant...
MOV oD0, c[95].w;
MOV oT0, c[95];
MOV oT1, c[95];     # set up w (xyz are overwritten)
MOV oT2, c[95];     # set up w (xyz are overwritten)

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

# (8) eye vector (incidence) ------------------------------------------------------------
ADD r5.xyz, -r0, c[4];
DP3 r5.w, r5, c[5];
MUL r5.w, r5.w, r5.w;        # squared distance
RCP r5.w, r5.w;
MUL r5.w, r5.w, c[10].y; # refraction scale
MIN r5.w, r5.w, v4.w;                 # clamp to one
MAX r5.w, r5.w, v4.z;                # clamp to zero
MOV oD0.w, r5.w;                                 # distance also affects edge-density

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, r0, c[0];
DP4 oPos.y, r0, c[1];
DP4 oPos.z, r0, c[2];
DP4 oPos.w, r0, c[3];

# output texcoords ----------------------------------------------------------------------
# (3) refraction map --------------------------------------------------------------------
DP3 oT0.x, r1, c[27];
DP3 oT0.y, r1, c[28];
DP3 oT0.z, r1, c[5];

# (4) refraction ------------------------------------------------------------------------
#  NVIDIA changed...
MUL r11.x, r5.w, c[10].x;  # x displace
MOV r11.y, v4.z;
MUL r11.w, r5.w, c[10].x;  # y displace

# (8) projection ------------------------------------------------------------------------
DP4 r10.x, r0, c[0];
DP4 r10.y, -r0, c[1];
DP4 r10.zw,r0, c[3];
ADD r10, r10.xyww, r10.wwww; # range-compress texcoords
RCP r10.w, r10.w;
MUL r10.xy, r10, r10.w;      # do the divide here

#  NVIDIA changed...
MUL r11.z, c[10].z, r10.x;
MUL oT1.xyz, r11.xyzx, c[95].x;   # scale by screen width

MUL r11.z, c[10].w, r10.y;
MUL oT2.xyz, r11.ywzx, c[95].y;   # scale by screen height

# (1) output tint color -----------------------------------------------------------------
MOV oD0.xyz, c[12];

END
