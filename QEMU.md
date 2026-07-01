# QEMU Boot Testing for zigllm-os

This document formalizes QEMU boot testing to address checklist items 1.1.6, 1.1.7, 1.1.8, etc.

## Prerequisites
- `qemu-system-x86_64` and/or `qemu-system-aarch64` installed
- Built image: `make image` (produces `arcis-os.img`)

## x86_64 Boot (1.1.6)
```bash
make qemu
# Or manually:
qemu-system-x86_64 \
  -drive file=arcis-os.img,format=raw,if=ide \
  -m 512M \
  -nographic \
  -serial mon:stdio
```

Expected: Boots to init (Zig PID 1), mounts filesystems, starts s6-rc services, zigllm-api ready on port 8080 (from /etc/arcis/env).

## aarch64 Boot (1.1.7)
```bash
make qemu-aarch64
# Or:
qemu-system-aarch64 -machine virt -cpu cortex-a57 \
  -drive file=arcis-os.img,format=raw,if=ide \
  -m 512M -nographic -serial mon:stdio
```

## Measuring Boot Timing (1.1.8)
Use QEMU with timestamp or script:
```bash
time qemu-system-x86_64 ... 
# Or add to kernel cmdline: printk.time=1 and capture serial
```
Target: < 3s to API availability.

## Validation under load (1.1.9)
Run stress in QEMU or multiple reboots.

## Diagnostics (1.1.10)
- Use `-serial stdio` for console
- Kernel panic capture via serial
- Add `panic=10` to cmdline for reboot on panic

## Current Status
- Makefile updated with qemu targets.
- Init, rootfs, image build paths exist.
- Next: Ensure kernel config includes virtio, serial console, ext4, etc. for reliable QEMU boot.
- Verify init.zig mounts /proc, /sys, /dev and execs s6-rc.

See also Makefile for targets and tracking issue #1.
