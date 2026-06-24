//! build.zig — Arcis OS build script
//! Builds the Zig PID 1 init binary, statically linked against musl.
//! Cross-compilation targets: x86_64, aarch64, riscv64.
//!
//! Usage:
//!   zig build -Dtarget=x86_64-linux-musl  -Doptimize=ReleaseFast
//!   zig build -Dtarget=aarch64-linux-musl -Doptimize=ReleaseFast
//!   zig build -Dtarget=riscv64-linux-musl -Doptimize=ReleaseFast
//!   zig build check-size
//!   zig build rootfs               # calls rootfs/assemble.sh
//!   zig build rootfs -Dtier=forma  # assemble forma-tier rootfs

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target   = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const tier     = b.option([]const u8, "tier", "Arcis tier: forma|figura|visio") orelse "visio";

    // -----------------------------------------------------------------------
    // Init binary (PID 1)
    // -----------------------------------------------------------------------
    const init_exe = b.addExecutable(.{
        .name        = "init",
        .root_module = b.createModule(.{
            .root_source_file = b.path("init/main.zig"),
            .target           = target,
            .optimize         = optimize,
        }),
    });
    init_exe.pie = false; // static, no PIE needed for PID 1
    b.installArtifact(init_exe);

    // -----------------------------------------------------------------------
    // Size guard: init must stay under 512 KB
    // -----------------------------------------------------------------------
    const check = b.addSystemCommand(&.{ "sh", "-c",
        "SIZE=$(stat -c%s zig-out/bin/init 2>/dev/null || stat -f%z zig-out/bin/init); " ++
        "echo \"Arcis init binary: $SIZE bytes\"; " ++
        "[ $SIZE -le 524288 ] || (echo 'ERROR: init exceeds 512KB' && exit 1)",
    });
    check.step.dependOn(b.getInstallStep());
    const size_step = b.step("check-size", "Verify init stays under 512KB");
    size_step.dependOn(&check.step);

    // -----------------------------------------------------------------------
    // Rootfs assembly step
    // -----------------------------------------------------------------------
    const rootfs_cmd = b.addSystemCommand(&.{
        "sh", "rootfs/assemble.sh", "rootfs/out", tier,
    });
    rootfs_cmd.step.dependOn(b.getInstallStep());
    const rootfs_step = b.step("rootfs", "Assemble Arcis OS rootfs");
    rootfs_step.dependOn(&rootfs_cmd.step);

    // -----------------------------------------------------------------------
    // Image build step (calls image/build.sh if present)
    // -----------------------------------------------------------------------
    const image_cmd = b.addSystemCommand(&.{
        "sh", "-c",
        "[ -f image/build.sh ] && sh image/build.sh rootfs/out || echo 'image/build.sh not found'",
    });
    image_cmd.step.dependOn(&rootfs_cmd.step);
    const image_step = b.step("image", "Build bootable Arcis OS image");
    image_step.dependOn(&image_cmd.step);
}
