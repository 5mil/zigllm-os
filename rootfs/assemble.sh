#!/bin/sh
# assemble.sh — Arcis OS rootfs assembler
# Builds a minimal Linux rootfs with:
#   - Alpine minirootfs base (optional)
#   - Arcis init as PID 1 at /sbin/init
#   - Arcis engine binary at /engine/arcis
#   - Arcis UI binary at /engine/arcis-ui
#   - s6/s6-rc service definitions
#   - /etc/arcis/env tier config
#
# Usage: ./rootfs/assemble.sh [output_dir] [tier]
#   tier: forma | figura | visio  (default: visio)

set -e

OUT=${1:-rootfs/out}
TIER=${2:-visio}
SKEL="rootfs/skeleton"
ALPINE_MINIROOTFS=${ALPINE_MINIROOTFS:-"rootfs/alpine-minirootfs.tar.gz"}

echo "==> Arcis OS rootfs assembler  tier=${TIER}"
rm -rf "$OUT"
mkdir -p "$OUT"

# 1. Base: Alpine minirootfs or minimal skeleton
if [ -f "$ALPINE_MINIROOTFS" ]; then
    echo "==> Extracting Alpine minirootfs"
    tar -xzf "$ALPINE_MINIROOTFS" -C "$OUT"
else
    echo "==> No Alpine minirootfs — building minimal skeleton"
    mkdir -p "$OUT"/{bin,sbin,lib,lib64,usr/bin,usr/lib,\
dev,proc,sys,tmp,run,root,etc/arcis,var/log,engine,\
dev/pts,run/s6/rc}
fi

# 2. Overlay our skeleton
if [ -d "$SKEL" ]; then
    echo "==> Overlaying arcis-os skeleton"
    cp -r "$SKEL/." "$OUT/"
fi

# 3. Arcis tier configuration
mkdir -p "$OUT/etc/arcis"
cat > "$OUT/etc/arcis/env" <<EOF
ARCIS_TIER=${TIER}
ARCIS_PORT=8080
ARCIS_HOST=0.0.0.0
EOF
echo "==> Wrote /etc/arcis/env  ARCIS_TIER=${TIER}"

# 4. Install Zig init as PID 1
if [ -f zig-out/bin/init ]; then
    echo "==> Installing Arcis init (PID 1)"
    cp zig-out/bin/init "$OUT/sbin/init"
    chmod 755 "$OUT/sbin/init"
else
    echo "WARNING: zig-out/bin/init not found — run 'zig build' first"
fi

# 5. Install Arcis engine binary
ARCIS_BIN=""
for candidate in \
    "../arcis/zig-out/bin/arcis" \
    "zig-out/bin/arcis"; do
    if [ -f "$candidate" ]; then
        ARCIS_BIN="$candidate"
        break
    fi
done
if [ -n "$ARCIS_BIN" ]; then
    echo "==> Installing Arcis engine: $ARCIS_BIN"
    mkdir -p "$OUT/engine"
    cp "$ARCIS_BIN" "$OUT/engine/arcis"
    chmod 755 "$OUT/engine/arcis"
else
    echo "WARNING: arcis binary not found — build arcis repo first"
fi

# 6. Install Arcis UI binary
UI_BIN=""
for candidate in \
    "../zigllm-ui/zig-out/bin/arcis-ui" \
    "../zigllm-ui/zig-out/bin/zigllm-ui" \
    "zig-out/bin/arcis-ui"; do
    if [ -f "$candidate" ]; then
        UI_BIN="$candidate"
        break
    fi
done
if [ -n "$UI_BIN" ]; then
    echo "==> Installing Arcis UI: $UI_BIN"
    cp "$UI_BIN" "$OUT/engine/arcis-ui"
    chmod 755 "$OUT/engine/arcis-ui"
else
    echo "WARNING: arcis-ui binary not found — build zigllm-ui repo first"
fi

# 7. Install s6 service definitions
echo "==> Installing s6 service definitions"
mkdir -p "$OUT/etc/s6/sv"
for svc in services/arcis services/arcis-ui services/mdev services/syslog; do
    if [ -d "$svc" ]; then
        svc_name=$(basename "$svc")
        cp -r "$svc" "$OUT/etc/s6/sv/$svc_name"
        chmod +x "$OUT/etc/s6/sv/$svc_name/run" 2>/dev/null || true
        chmod +x "$OUT/etc/s6/sv/$svc_name/finish" 2>/dev/null || true
    fi
done

# 8. s6-rc compiled bundle placeholder (requires s6-rc-compile at build time)
if command -v s6-rc-compile > /dev/null 2>&1; then
    echo "==> Compiling s6-rc service database"
    s6-rc-compile "$OUT/etc/s6/compiled" "$OUT/etc/s6/sv"
else
    echo "NOTE: s6-rc-compile not found — copy pre-compiled bundle to $OUT/etc/s6/compiled"
    mkdir -p "$OUT/etc/s6/compiled"
fi

# 9. Permissions
chown -R root:root "$OUT" 2>/dev/null || true
chmod 755 "$OUT/sbin/init"
chmod 755 "$OUT/engine" 2>/dev/null || true

echo ""
echo "==> Arcis OS rootfs assembled at $OUT"
du -sh "$OUT"
echo "    Tier: ${TIER}"
echo "    Init: $OUT/sbin/init"
echo "    Engine: $OUT/engine/arcis"
echo "    UI: $OUT/engine/arcis-ui"
