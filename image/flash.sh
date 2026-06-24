#!/bin/sh
# Flash zigllm-os.img to a target device.
# Usage: ./image/flash.sh /dev/sdX
# WARNING: this WILL erase the target device.

set -e

IMG=image/zigllm-os.img
DEV=${1:-}

if [ -z "$DEV" ]; then
    echo "Usage: $0 /dev/sdX"
    exit 1
fi

if [ ! -b "$DEV" ]; then
    echo "ERROR: $DEV is not a block device"
    exit 1
fi

echo "WARNING: This will erase ALL data on $DEV"
echo "Press Ctrl+C within 5 seconds to abort..."
sleep 5

echo "==> Flashing $IMG to $DEV"
dd if="$IMG" of="$DEV" bs=4M status=progress conv=fsync
sync

echo "==> Done. You can now boot from $DEV"
