#!/bin/sh
# Assemble the zigllm-os rootfs.
# Requires: Alpine Linux minirootfs tarball, busybox static binary,
#           s6 + s6-rc static binaries, musl libc.
#
# Usage: ./rootfs/assemble.sh [output_dir]

set -e

OUT=${1:-rootfs/out}
SKEL="rootfs/skeleton"
ALPINE_MINIROOTFS=${ALPINE_MINIROOTFS:-"rootfs/alpine-minirootfs.tar.gz"}

echo "==> Creating rootfs at $OUT"
rm -rf "$OUT"
mkdir -p "$OUT"

# 1. Extract Alpine minirootfs as base
if [ -f "$ALPINE_MINIROOTFS" ]; then
    echo "==> Extracting Alpine minirootfs"
    tar -xzf "$ALPINE_MINIROOTFS" -C "$OUT"
else
    echo "==> No Alpine minirootfs found — building minimal skeleton only"
    mkdir -p "$OUT"/{bin,sbin,lib,lib64,usr/bin,usr/lib,dev,proc,sys,tmp,run,root,etc,var/log,engine}
fi

# 2. Overlay our skeleton
echo "==> Overlaying zigllm-os skeleton"
cp -r "$SKEL/" "$OUT/"

# 3. Install Zig init as PID 1
if [ -f zig-out/bin/init ]; then
    echo "==> Installing Zig init"
    cp zig-out/bin/init "$OUT/sbin/init"
    chmod 755 "$OUT/sbin/init"
else
    echo "WARNING: zig-out/bin/init not found — run 'zig build' first"
fi

# 4. Install zigllm engine binaries
for bin in zigllm-api zigllm-ui zigllm-core; do
    if [ -f "../zigllm-api/zig-out/bin/$bin" ] || [ -f "../zigllm-ui/zig-out/bin/$bin" ] || [ -f "../zigllm-core/zig-out/bin/$bin" ]; then
        echo "==> Installing $bin"
        cp "../*/zig-out/bin/$bin" "$OUT/engine/" 2>/dev/null || true
    fi
done

# 5. Set permissions
chown -R root:root "$OUT" 2>/dev/null || true
chmod 755 "$OUT/sbin/init"

echo "==> rootfs assembled at $OUT"
du -sh "$OUT"
