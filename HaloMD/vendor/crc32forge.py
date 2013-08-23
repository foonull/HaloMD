#!/usr/bin/env python
#-*- coding:utf-8 -*-

# -----------------------------------------------------------------------------
# crc32 forge by StalkR
# cmdline wrapper by hellman
# specific HaloMD modifications by nil
#   original from comments in http://blog.stalkr.net/2011/03/crc-32-forging.html
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Usage: %s [-p pos] [-f filename | -s string] wanted_src
# opts:
#   -p=len(s)  position to insert 4 bytes
#   -f=STDIN   file to read data from
#   -s         pass string directly
# wanted_crc forms:
#   0xdeadbeef
#   efbeadde - like it lays in memory
#   $'\xef\xbe\xad\xde' - four byte string
# -----------------------------------------------------------------------------


import sys
import getopt
from struct import pack, unpack


def main():
    r = open(sys.argv[1], 'rb')
    s = r.read(0x1FFC)
    r.close()
    pos = None
    wanted_crc = 0xFFFFFFFF
    f = open(sys.argv[1], 'wb')
    f.write(forge(wanted_crc, s, pos))
    f.close()
    return

# -----------------------------------------------------------------------------
# CRC32 FORGE by StalkR
# -----------------------------------------------------------------------------

crc32_table, crc32_reverse = [0] * 256, [0] * 256


def _build_crc_tables():
    global crc32_table, crc32_reverse
    for i in range(256):
        fwd = i
        rev = i << 24
        for j in range(8, 0, -1):
            # build normal table
            if (fwd & 1) == 1:
                fwd = (fwd >> 1) ^ 0xedb88320
            else:
                fwd >>= 1
            crc32_table[i] = fwd
            # build reverse table =)
            if rev & 0x80000000 == 0x80000000:
                rev = ((rev ^ 0xedb88320) << 1) | 1
            else:
                rev <<= 1
            crc32_reverse[i] = rev


def crc32(s):  # same crc32 as in (binascii.crc32)&0xffffffff
    crc = 0xffffffff
    for c in s:
        crc = (crc >> 8) ^ crc32_table[crc & 0xff ^ ord(c)]
    return crc ^ 0xffffffff


def forge(wanted_crc, str, pos=None):
    if pos is None:
        pos = len(str)

    # forward calculation of CRC up to pos, sets current forward CRC state
    fwd_crc = 0xffffffff
    for c in str[:pos]:
        fwd_crc = (fwd_crc >> 8) ^ crc32_table[fwd_crc & 0xff ^ ord(c)]

    # backward calculation of CRC up to pos, sets wanted backward CRC state
    bkd_crc = wanted_crc ^ 0xffffffff
    for c in str[pos:][::-1]:
        bkd_crc = ((bkd_crc << 8) & 0xffffffff) ^ crc32_reverse[bkd_crc >> 24]
        bkd_crc ^= ord(c)

    # deduce the 4 bytes we need to insert
    for c in pack('<L', fwd_crc)[::-1]:
        bkd_crc = ((bkd_crc << 8) & 0xffffffff) ^ crc32_reverse[bkd_crc >> 24]
        bkd_crc ^= ord(c)

    res = str[:pos] + pack('<L', bkd_crc) + str[pos:]

    assert(crc32(res) == wanted_crc)
    return res


_build_crc_tables()

if __name__ == "__main__":
    main()
