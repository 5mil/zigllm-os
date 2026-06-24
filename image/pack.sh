#!/bin/sh
# Pack the zigllm-os bootable disk image.
# Output: image/zigllm-os.img (raw disk image, GPT + EFI + rootfs)
#
# Requires: parted, mkfs.fat, mkfs.ext4, grub-install (x86_64)

set -e

IMG=image/zigllm-os.img
ROOTFS=rootfs/out
BOOT=image/boot
SIZE_MB=${SIZE_MB:-2048}  # 2GB default image

echo "==> Creating disk image: $IMG ($SIZE_MB MB)"
dd if=/dev/zero of="$IMG" bs=1M count=$SIZE_MB status=progress

echo "==> Partitioning (GPT: 256MB EFI + rest rootfs)"
parted -s "$IMG" \
    mklabel gpt \
    mkpart EFI fat32 1MiB 257MiB \
    set 1 esp on \
    mkpart ROOT ext4 257MiB 100%

# Mount via loopback
LOOP=$(losetup --find --show --partscan "$IMG")
trap "losetup -d $LOOP" EXIT

echo "==> Formatting partitions"
mkfs.fat -F32 "${LOOP}p1"
mkfs.ext4 -q "${LOOP}p2"

# Mount and copy
mkdir -p /tmp/zigllm-efi /tmp/zigllm-root
mount "${LOOP}p1" /tmp/zigllm-efi
mount "${LOOP}p2" /tmp/zigllm-root

echo "==> Copying rootfs"
cp -a "$ROOTFS/". /tmp/zigllm-root/

echo "==> Installing bootloader"
mkdir -p /tmp/zigllm-root/boot
cp "$BOOT/vmlinuz" /tmp/zigllm-root/boot/

cat > /tmp/zigllm-root/boot/grub/grub.cfg << 'EOF'
set timeout=1
set default=0

menuentry "zigllm-os" {
    linux /boot/vmlinuz root=/dev/sda2 rw quiet loglevel=3 init=/sbin/init
    # For GGUF model preload: add model=llama3 to cmdline
}
EOF

grub-install --target=x86_64-efi \
    --efi-directory=/tmp/zigllm-efi \
    --boot-directory=/tmp/zigllm-root/boot \
    --removable "$LOOP"

umount /tmp/zigllm-efi /tmp/zigllm-root

echo "==> Image ready: $IMG"
ls -lh "$IMG"
