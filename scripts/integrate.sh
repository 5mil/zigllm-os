#!/usr/bin/env bash
# Cross-repo integration script for Arcis stack
# Builds zigllm-os, pulls arcis + zigllm-ui artifacts, assembles final image

set -euo pipefail

ARCH="${ARCH:-x86_64}"
TIER="${TIER:-visio}"
OPTIMIZE="${OPTIMIZE:-ReleaseFast}"

echo "=== Arcis Stack Integration Build ==="
echo "Arch: $ARCH | Tier: $TIER"

# 1. Build zigllm-os (this repo)
echo "[1/5] Building zigllm-os..."
make clean
make ARCH="$ARCH" OPTIMIZE="$OPTIMIZE" TIER="$TIER" image

echo "[2/5] zigllm-os image built: arcis-os.img"

# 2. Build arcis (assumes sibling repo or git submodule/workspace)
if [ -d "../arcis" ]; then
  echo "[3/5] Building arcis from ../arcis..."
  (cd ../arcis && zig build -Dtarget="${ARCH}-linux-musl" -Doptimize="$OPTIMIZE")
  cp ../arcis/zig-out/bin/arcis rootfs/out/engine/arcis 2>/dev/null || true
else
  echo "[3/5] arcis repo not found at ../arcis — using pre-built or skipping"
fi

# 3. Build zigllm-ui
if [ -d "../zigllm-ui" ]; then
  echo "[4/5] Building zigllm-ui from ../zigllm-ui..."
  (cd ../zigllm-ui && zig build -Dui="$TIER" -Dtarget="${ARCH}-linux-musl" -Doptimize="$OPTIMIZE")
  cp ../zigllm-ui/zig-out/bin/arcis-ui rootfs/out/engine/arcis-ui 2>/dev/null || true
else
  echo "[4/5] zigllm-ui repo not found — using pre-built or skipping"
fi

# 4. Re-assemble rootfs with fresh binaries
echo "[5/5] Re-assembling rootfs with latest binaries..."
zig build rootfs -Dtarget="${ARCH}-linux-musl" -Doptimize="$OPTIMIZE" -Dtier="$TIER"

# 5. Final image
zig build image -Dtarget="${ARCH}-linux-musl" -Doptimize="$OPTIMIZE" -Dtier="$TIER"

echo "=== Integration complete ==="
echo "Final image: arcis-os.img"
ls -lh arcis-os.img
