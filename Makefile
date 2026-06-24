.PHONY: all kernel init rootfs image flash clean

ARCH     ?= x86_64
CROSS    ?=
OPTIMIZE ?= ReleaseFast

all: init rootfs image

kernel:
	@echo "==> Building kernel (ARCH=$(ARCH))"
	@chmod +x kernel/build.sh
	./kernel/build.sh $(ARCH) $(CROSS)

init:
	@echo "==> Building Zig init (ARCH=$(ARCH))"
	zig build -Dtarget=$(ARCH)-linux-musl -Doptimize=$(OPTIMIZE)

rootfs: init
	@echo "==> Assembling rootfs"
	@chmod +x rootfs/assemble.sh
	./rootfs/assemble.sh

image: rootfs kernel
	@echo "==> Packing disk image"
	@chmod +x image/pack.sh
	./image/pack.sh

flash:
	@chmod +x image/flash.sh
	./image/flash.sh $(DEV)

check-size:
	zig build check-size -Dtarget=$(ARCH)-linux-musl -Doptimize=$(OPTIMIZE)

clean:
	rm -rf zig-out .zig-cache rootfs/out image/zigllm-os.img image/boot/vmlinuz
