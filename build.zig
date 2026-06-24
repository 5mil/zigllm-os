//! Builds the Zig PID 1 init binary.
//! Cross-compile for target arch, link against musl statically.
//!
//! Compatible with Zig 0.12, 0.13, and 0.14.
//!
//! Usage:
//!   zig build -Dtarget=x86_64-linux-musl -Doptimize=ReleaseFast
//!   zig build -Dtarget=aarch64-linux-musl -Doptimize=ReleaseFast

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target   = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const init_exe = b.addExecutable(.{
        .name             = "init",
        .root_module      = b.createModule(.{
            .root_source_file = b.path("init/main.zig"),
            .target           = target,
            .optimize         = optimize,
        }),
    });

    // Static binary — no shared libs on the rootfs needed
    init_exe.pie = false;

    b.installArtifact(init_exe);

    // Size check — init binary must stay under 512KB
    const check = b.addSystemCommand(&.{ "sh", "-c",
        "SIZE=$(stat -c%s zig-out/bin/init); " ++
        "echo \"init binary: $SIZE bytes\"; " ++
        "[ $SIZE -le 524288 ] || (echo 'ERROR: init exceeds 512KB' && exit 1)"
    });
    check.step.dependOn(b.getInstallStep());
    const size_step = b.step("check-size", "Verify init stays under 512KB");
    size_step.dependOn(&check.step);
}
