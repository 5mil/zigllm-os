//! zigllm-os PID 1 init process.
//! Responsibilities:
//!   1. Mount essential virtual filesystems
//!   2. Set hostname
//!   3. Start s6-rc supervision tree
//!   4. Rescue shell fallback

const std   = @import("std");
const linux = std.os.linux;
const posix = std.posix;

/// Kernel mount flags
const MS_NOSUID:   u32 = 2;
const MS_NODEV:    u32 = 4;
const MS_NOEXEC:   u32 = 8;

pub fn main() noreturn {
    // Step 1: mount virtual filesystems
    mount("proc",     "/proc",    "proc",     MS_NOSUID | MS_NODEV | MS_NOEXEC);
    mount("sysfs",    "/sys",     "sysfs",    MS_NOSUID | MS_NODEV | MS_NOEXEC);
    mount("devtmpfs", "/dev",     "devtmpfs", MS_NOSUID | MS_NOEXEC);
    mount("tmpfs",    "/tmp",     "tmpfs",    MS_NOSUID | MS_NODEV);
    mount("tmpfs",    "/run",     "tmpfs",    MS_NOSUID | MS_NODEV);
    mount("devpts",   "/dev/pts", "devpts",   MS_NOSUID | MS_NOEXEC);

    // Step 2: hostname
    setHostname("zigllm");

    // Step 3: log
    log("zigllm-os init: filesystems mounted");

    // Step 4: start s6-rc
    const s6_argv = [_:null]?[*:0]const u8{
        "/bin/s6-rc-init", "-c", "/etc/s6/compiled",
        "-l", "/run/s6/rc", "/run/s6/rc", null,
    };
    const empty_envp = [_:null]?[*:0]const u8{null};
    _ = linux.execve("/bin/s6-rc-init", &s6_argv, &empty_envp);

    // s6 failed — drop to rescue shell
    log("zigllm-os init: s6-rc-init failed, starting rescue shell");
    const sh_argv = [_:null]?[*:0]const u8{ "/bin/sh", null };
    _ = linux.execve("/bin/sh", &sh_argv, &empty_envp);

    // Halt if shell also fails
    _ = linux.reboot(
        linux.LINUX_REBOOT_MAGIC1,
        linux.LINUX_REBOOT_MAGIC2,
        linux.LINUX_REBOOT_CMD_HALT,
        null,
    );
    unreachable;
}

/// Mount a filesystem.
/// data param is usize in Zig 0.13 — pass 0 for no mount options.
fn mount(
    src:    [*:0]const u8,
    dst:    [*:0]const u8,
    fstype: [*:0]const u8,
    flags:  u32,
) void {
    const rc = linux.mount(src, dst, fstype, flags, 0);
    if (rc != 0) log("init: mount failed");
}

/// Set hostname via raw syscall.
/// linux.sethostname was removed from std.os.linux in Zig 0.13 —
/// use syscall2 directly instead.
fn setHostname(name: []const u8) void {
    _ = linux.syscall2(
        .sethostname,
        @intFromPtr(name.ptr),
        name.len,
    );
}

/// Write a message to /dev/kmsg (kernel log buffer).
/// Works before syslog is running.
fn log(msg: []const u8) void {
    const kmsg = posix.open("/dev/kmsg", .{ .ACCMODE = .WRONLY }, 0) catch return;
    defer posix.close(kmsg);
    _ = posix.write(kmsg, msg) catch {};
    _ = posix.write(kmsg, "\n") catch {};
}
