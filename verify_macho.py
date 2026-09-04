#!/usr/bin/env python3
"""Quick Mach-O dump — checks load commands and finds LC_LOAD_DYLIB entries."""
import struct, sys

with open(sys.argv[1], "rb") as f:
    buf = f.read()

assert struct.unpack_from("<I", buf, 0)[0] == 0xFEEDFACF, "Not a 64-bit Mach-O"
ncmds = struct.unpack_from("<I", buf, 16)[0]
sizeofcmds = struct.unpack_from("<I", buf, 20)[0]

print(f"ncmds={ncmds}, sizeofcmds={sizeofcmds}")
off = 32
found = []
for i in range(ncmds):
    cmd, size = struct.unpack_from("<II", buf, off)
    if cmd in (0x0C, 0x80000018):  # LC_LOAD_DYLIB, LC_LOAD_WEAK_DYLIB
        name_off = struct.unpack_from("<I", buf, off + 8)[0]
        name = buf[off + name_off:].split(b"\x00", 1)[0].decode()
        kind = "LC_LOAD_WEAK_DYLIB" if cmd == 0x80000018 else "LC_LOAD_DYLIB"
        print(f"  [{i}] {kind} -> {name}")
        found.append(name)
    else:
        pass  # print(f"  [{i}] cmd=0x{cmd:08X} size={size}")
    off += size

print(f"\nFound {len(found)} LC_LOAD_DYLIB command(s).")
sys.exit(0 if found else 1)
