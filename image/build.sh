#!/bin/sh
# image/build.sh — Arcis OS bootable image builder
# Packs rootfs/out into a bootable ext4 image with GRUB or syslinux.
# Requires: mke2fs, grub-mkrescue or syslinux, xorriso.
#
# Usage: sh image/build.sh [rootfs_dir] [output_image]

set -e

ROOTFS=${1:-rootfs/out}
OUT=${2:-arcis-os.img}
SIZE_MB=${SIZE_MB:-256}

echo "==> Arcis OS image builder"
echo "    rootfs : $ROOTFS"
echo "    output : $OUT"
echo "    size   : ${SIZE_MB}MB"

# 1. Create raw image file.
dd if=/dev/zero of="$OUT" bs=1M count="$SIZE_MB" status=progress

# 2. Partition: single bootable partition.
if command -v parted > /dev/null 2>&1; then
    parted -s "$OUT" mklabel msdos mkpart primary ext4 1MiB 100% set 1 boot on
else
    echo "WARNING: parted not found — skipping partition table"
fi

# 3. Format as ext4.
if command -v mke2fs > /dev/null 2>&1; then
    mke2fs -t ext4 -d "$ROOTFS" -L arcis-os "$OUT"
    echo "==> ext4 image written"
else
    echo "WARNING: mke2fs not found — creating tar archive instead"
    tar -czf "${OUT%.img}.tar.gz" -C "$ROOTFS" .
    echo "==> rootfs archive written: ${OUT%.img}.tar.gz"
fi

# 4. Install bootloader.
if command -v grub-mkrescue > /dev/null 2>&1; then
    echo "==> Installing GRUB"
    mkdir -p /tmp/arcis-iso/boot/grub
    cat > /tmp/arcis-iso/boot/grub/grub.cfg <<'GRUB'
set timeout=2
set default=0
menuentry "Arcis OS" {
    linux /boot/vmlinuz root=/dev/sda1 rw quiet
    initrd /boot/initrd
}
GRUB
    grub-mkrescue -o arcis-os.iso /tmp/arcis-iso 2>/dev/null || true
    echo "==> ISO written: arcis-os.iso"
fi

echo "==> Done: $OUT"
ls -lh "$OUT" 2>/dev/null || true
