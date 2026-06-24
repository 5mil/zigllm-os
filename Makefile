# Makefile — Arcis OS convenience targets
# All real build logic lives in build.zig and rootfs/assemble.sh.

ARCH       ?= x86_64
OPTIMIZE   ?= ReleaseFast
TIER       ?= visio
TARGET      = $(ARCH)-linux-musl

.PHONY: all init rootfs image clean check-size

all: init rootfs

init:
	zig build -Dtarget=$(TARGET) -Doptimize=$(OPTIMIZE)

check-size: init
	zig build check-size -Dtarget=$(TARGET) -Doptimize=$(OPTIMIZE)

rootfs: init
	zig build rootfs -Dtarget=$(TARGET) -Doptimize=$(OPTIMIZE) -Dtier=$(TIER)

image: rootfs
	zig build image -Dtarget=$(TARGET) -Doptimize=$(OPTIMIZE) -Dtier=$(TIER)

clean:
	rm -rf zig-out zig-cache rootfs/out arcis-os.img arcis-os.iso arcis-os.tar.gz

# Quick QEMU test boot (requires qemu-system-x86_64)
qemu: rootfs
	qemu-system-x86_64 -kernel rootfs/out/boot/vmlinuz \
	    -initrd rootfs/out/boot/initrd \
	    -append "root=/dev/sda1 rw quiet" \
	    -drive file=arcis-os.img,format=raw \
	    -m 512M -nographic
