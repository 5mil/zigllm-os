# Firmware

GPU and hardware firmware blobs live here.
These are NOT included in the repo (binary blobs, various licenses).

## AMD GPU (amdgpu)

```sh
# Copy from your existing Linux install:
cp -r /lib/firmware/amdgpu firmware/amdgpu
# Or fetch from linux-firmware:
git clone --depth=1 https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
cp -r linux-firmware/amdgpu firmware/
```

## NVIDIA (open kernel module)

```sh
cp -r /lib/firmware/nvidia firmware/nvidia
```

## Raspberry Pi 5

```sh
# Pi firmware is included in the kernel tree for VC4
# Additional blobs from:
git clone --depth=1 https://github.com/raspberrypi/firmware
cp firmware/boot/*.dat firmware/boot/*.elf firmware/rpi/
```

## Intel GPU

```sh
cp -r /lib/firmware/i915 firmware/i915
```

During rootfs assembly, `assemble.sh` copies `firmware/` into `/lib/firmware/` on the rootfs.
