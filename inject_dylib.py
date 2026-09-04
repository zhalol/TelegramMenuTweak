#!/usr/bin/env python3
"""
inject_dylib.py — adds a LC_LOAD_DYLIB command to a Mach-O binary.
Works on arm64 / x86_64. No external dependencies.

Usage:
    inject_dylib.py "@executable_path/TelegramMenuTweak.dylib" "Soccer Champs"
"""
import struct
import sys
import os
import shutil

MH_MAGIC_64 = 0xFEEDFACF
MH_CIGAM_64 = 0xCFFAEDFE  # swapped

LC_LOAD_DYLIB = 0x0C
LC_LOAD_WEAK_DYLIB = 0x80000018

CPU_TYPE_ARM64 = 0x0100000C
CPU_TYPE_X86_64 = 0x01000007


def read_u32(buf, off):
    return struct.unpack_from("<I", buf, off)[0]


def read_u64(buf, off):
    return struct.unpack_from("<Q", buf, off)[0]


def write_u32(buf, off, v):
    struct.pack_into("<I", buf, off, v)


def write_u64(buf, off, v):
    struct.pack_into("<Q", buf, off, v)


def align4(n):
    return (n + 3) & ~3


def inject(path, dylib_path, weak=False):
    with open(path, "rb") as f:
        buf = bytearray(f.read())

    magic = read_u32(buf, 0)
    if magic == MH_CIGAM_64:
        # Big-endian (PowerPC) - swap fields. We only support LE for arm64/x86_64.
        print("Error: big-endian Mach-O is not supported.", file=sys.stderr)
        return False

    if magic != MH_MAGIC_64:
        print(f"Error: not a 64-bit Mach-O (magic=0x{magic:08X}).", file=sys.stderr)
        return False

    cputype = read_u32(buf, 4)
    if cputype not in (CPU_TYPE_ARM64, CPU_TYPE_X86_64):
        print(f"Error: unsupported CPU type 0x{cputype:08X}.", file=sys.stderr)
        return False

    # Header is 32 bytes, then ncmds load commands
    ncmds = read_u32(buf, 16)
    sizeofcmds = read_u32(buf, 20)
    # Sanity: total header size for MH_MAGIC_64 is 32

    # Build new LC_LOAD_DYLIB
    name_bytes = dylib_path.encode("utf-8") + b"\x00"
    # cmdsize: header(8) + union(16) + name, aligned to 4 bytes
    cmdsize = align4(8 + 16 + len(name_bytes))
    pad = cmdsize - (8 + 16 + len(name_bytes))

    # name.offset points to where the name string starts in the command buffer
    name_offset = 24  # 8 (cmd+cmdsize) + 16 (union)

    new_cmd = struct.pack("<IIIIII",
                          LC_LOAD_WEAK_DYLIB if weak else LC_LOAD_DYLIB,
                          cmdsize,
                          name_offset,
                          0,  # timestamp
                          0,  # current version
                          0)  # compat version (24 bytes total)
    new_cmd_full = new_cmd + name_bytes + (b"\x00" * pad)

    if len(new_cmd_full) != cmdsize:
        print(f"Internal error: cmdsize mismatch {len(new_cmd_full)} vs {cmdsize}", file=sys.stderr)
        return False

    # We need to insert new_cmd_full into the load commands region.
    # Strategy: increase sizeofcmds by cmdsize, ncmds by 1, and append our command at the end of
    # the existing load commands (right after the last one).

    # Find end of load commands: walk from offset 32 through ncmds
    off = 32
    last_end = 32
    for _ in range(ncmds):
        if off + 8 > len(buf):
            print("Error: truncated load commands.", file=sys.stderr)
            return False
        cmd, size = struct.unpack_from("<II", buf, off)
        if size == 0 or size % 4 != 0:
            print(f"Error: invalid load command size {size} at offset {off}.", file=sys.stderr)
            return False
        last_end = off + size
        off = last_end

    if last_end + len(new_cmd_full) > len(buf):
        print("Error: not enough space to append load command.", file=sys.stderr)
        return False

    # Update header
    write_u32(buf, 16, ncmds + 1)
    write_u32(buf, 20, sizeofcmds + cmdsize)

    # Insert at last_end
    new_buf = buf[:last_end] + new_cmd_full + buf[last_end:]

    with open(path, "wb") as f:
        f.write(new_buf)

    return True


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    weak = "--weak" in flags

    if len(args) < 2:
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    dylib_path = args[0]
    target = args[1]

    if not os.path.isfile(target):
        print(f"Error: target not found: {target}", file=sys.stderr)
        sys.exit(1)

    # Back up target
    backup = target + ".backup"
    if not os.path.exists(backup):
        shutil.copy2(target, backup)
        print(f"Backup created: {backup}")

    if inject(target, dylib_path, weak=weak):
        print(f"✓ Injected '{dylib_path}' into '{target}'" + (" (weak)" if weak else ""))
    else:
        # Restore from backup on failure
        shutil.copy2(backup, target)
        print("✗ Injection failed; restored from backup.", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
