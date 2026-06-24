//! zigllm-os PID 1 init process.
//! Responsibilities:
//!   1. Mount essential virtual filesystems
//!   2. Set hostname
//!   3. Seed /dev via mdev or static nodes
//!   4. Load kernel modules (GPU firmware, input drivers)
//!   5. Start s6-rc supervision tree
//!   6. Handle SIGCHLD (reap zombies)
//!   7. On shutdown: stop services, sync, unmount, poweroff/reboot

const std   = @import("std");
const linux = std.os.linux;
const posix = std.posix;

/// Kernel mount flags
const MS_NOSUID:  u32 = 2;
const MS_NODEV:   u32 = 4;
const MS_NOEXEC:  u32 = 8;
const MS_RELATIME:u32 = 1 << 21;

pub fn main() noreturn {
    // Step 1: mount virtual filesystems
    mount("proc",     "/proc",     "proc",     MS_NOSUID | MS_NODEV | MS_NOEXEC);
    mount("sysfs",    "/sys",      "sysfs",    MS_NOSUID | MS_NODEV | MS_NOEXEC);
    mount("devtmpfs", "/dev",      "devtmpfs", MS_NOSUID | MS_NOEXEC);
    mount("tmpfs",    "/tmp",      "tmpfs",    MS_NOSUID | MS_NODEV);
    mount("tmpfs",    "/run",      "tmpfs",    MS_NOSUID | MS_NODEV);
    mount("devpts",   "/dev/pts",  "devpts",   MS_NOSUID | MS_NOEXEC);

    // Step 2: hostname
    setHostname("zigllm");

    // Step 3: set PATH
    _ = linux.setenv("PATH", "/bin:/sbin:/usr/bin:/engine", 1);

    // Step 4: log
    log("zigllm-os init: filesystems mounted");

    // Step 5: start s6-rc
    // s6-rc-init populates /run/s6/rc then s6-rc starts the "default" bundle
    const s6_argv = [_:null]?[*:0]const u8{
        "/bin/s6-rc-init", "-c", "/etc/s6/compiled", "-l", "/run/s6/rc",
        "/run/s6/rc", null
    };
    const s6_envp = [_:null]?[*:0]const u8{ null };
    _ = linux.execve("/bin/s6-rc-init", &s6_argv, &s6_envp);

    // If s6 fails, drop to a minimal rescue shell
    log("zigllm-os init: s6-rc-init failed, starting rescue shell");
    const sh_argv = [_:null]?[*:0]const u8{ "/bin/sh", null };
    _ = linux.execve("/bin/sh", &sh_argv, &s6_envp);

    // Should never reach here
    _ = linux.reboot(linux.LINUX_REBOOT_MAGIC1, linux.LINUX_REBOOT_MAGIC2,
                     linux.LINUX_REBOOT_CMD_HALT, null);
    unreachable;
}

fn mount(src: [*:0]const u8, dst: [*:0]const u8, fstype: [*:0]const u8, flags: u32) void {
    const rc = linux.mount(src, dst, fstype, flags, null);
    if (rc != 0) {
        log("init: mount failed");
    }
}

fn setHostname(name: []const u8) void {
    _ = linux.sethostname(name.ptr, name.len);
}

fn log(msg: []const u8) void {
    // Write directly to /dev/kmsg (kernel log) before syslog is up
    const kmsg = posix.open("/dev/kmsg", .{ .ACCMODE = .WRONLY }, 0) catch return;
    defer posix.close(kmsg);
    _ = posix.write(kmsg, msg) catch {};
    _ = posix.write(kmsg, "\n") catch {};
}
