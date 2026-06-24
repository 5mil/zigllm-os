# zigllm-os

Custom Linux backbone for the zigllm AI engine stack.
A minimal, purpose-built OS that boots directly into the zigllm runtime.

## Goals

- Boot in < 3 seconds to a running zigllm-api endpoint
- No display server, no desktop environment, no package manager at runtime
- Single flashable image: kernel + initramfs + rootfs + zigllm binaries
- Runs on x86_64, ARM64 (Raspberry Pi 5, Jetson), and RISC-V

## Stack

```
[ zigllm-ui / zigllm-api / zigllm-core ]   ← application layer
[ s6-rc supervision tree               ]   ← service management  
[ Zig init (PID 1)                     ]   ← init process
[ musl libc + BusyBox                  ]   ← minimal userspace
[ Custom Linux kernel (6.x)            ]   ← stripped kernel
[ Bootloader: GRUB / U-Boot / systemd-boot ] ← target dependent
```

## Build

```sh
# Install deps: gcc, make, flex, bison, libssl-dev, bc, cpio

# 1. Configure and build the kernel
make -C kernel menuconfig
make -C kernel build

# 2. Build the Zig init binary
zig build -Dtarget=x86_64-linux-musl -Doptimize=ReleaseFast

# 3. Assemble rootfs
make -C rootfs build

# 4. Pack bootable image
make image
```

## Directory Structure

```
zigllm-os/
├── kernel/          # kernel config + build wrapper
├── init/            # Zig PID 1 init process
├── rootfs/          # rootfs skeleton + assembly scripts
├── services/        # s6-rc service definitions
├── image/           # image packing scripts
├── firmware/        # GPU firmware blobs (amdgpu, nvidia, etc)
└── build.zig        # Zig init build file
```

## Target Hardware

| Target | Arch | Bootloader | Display |
|---|---|---|---|
| Generic PC | x86_64 | GRUB2 | DRM/KMS |
| Raspberry Pi 5 | ARM64 | U-Boot | DRM/KMS |
| Jetson Orin | ARM64 | U-Boot | CUDA + DRM |
| RISC-V board | riscv64 | OpenSBI + U-Boot | fb0 |
