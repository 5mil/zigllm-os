#!/bin/sh
# Build the zigllm-os kernel for a given arch.
# Usage: ./kernel/build.sh x86_64 [cross-prefix]
#        ./kernel/build.sh aarch64 aarch64-linux-musl-

set -e

ARCH=${1:-x86_64}
CROSS=${2:-""}
KERNEL_SRC=${KERNEL_SRC:-"../linux"}
CONFIG_FILE="$(dirname "$0")/config.${ARCH}"
JOBS=$(nproc)

if [ ! -d "$KERNEL_SRC" ]; then
    echo "Kernel source not found at $KERNEL_SRC"
    echo "Clone with: git clone --depth=1 https://github.com/torvalds/linux ../linux"
    exit 1
fi

echo "==> Configuring kernel for $ARCH"
cp "$CONFIG_FILE" "$KERNEL_SRC/.config"
make -C "$KERNEL_SRC" ARCH=$ARCH CROSS_COMPILE=$CROSS olddefconfig

echo "==> Building kernel ($JOBS jobs)"
make -C "$KERNEL_SRC" ARCH=$ARCH CROSS_COMPILE=$CROSS -j$JOBS

echo "==> Copying artifacts"
mkdir -p image/boot
if [ "$ARCH" = "x86_64" ]; then
    cp "$KERNEL_SRC/arch/x86/boot/bzImage" image/boot/vmlinuz
elif [ "$ARCH" = "aarch64" ]; then
    cp "$KERNEL_SRC/arch/arm64/boot/Image.gz" image/boot/vmlinuz
fi
cp "$KERNEL_SRC/System.map" image/boot/System.map

echo "==> Kernel build complete: image/boot/vmlinuz"
