//! zigllm-os PID 1 init process.

const std   = @import("std");
const linux = std.os.linux;

// Kernel mount flags
const MS_NOSUID: u32 = 2;
const MS_NODEV:  u32 = 4;
const MS_NOEXEC: u32 = 8;

// Reboot magic constants (not exposed in Zig 0.13 std)
const REBOOT_MAGIC1:    u32 = 0xfee1dead;
const REBOOT_MAGIC2:    u32 = 672274793;
const REBOOT_CMD_HALT:  u32 = 0xcdef0123;
const REBOOT_CMD_POWER: u32 = 0x4321fedc;
const REBOOT_CMD_RESTART: u32 = 0x01234567;

pub fn main() noreturn {
    // Mount virtual filesystems
    mount("proc",     "/proc",    "proc",     MS_NOSUID | MS_NODEV | MS_NOEXEC);
    mount("sysfs",    "/sys",     "sysfs",    MS_NOSUID | MS_NODEV | MS_NOEXEC);
    mount("devtmpfs", "/dev",     "devtmpfs", MS_NOSUID | MS_NOEXEC);
    mount("tmpfs",    "/tmp",     "tmpfs",    MS_NOSUID | MS_NODEV);
    mount("tmpfs",    "/run",     "tmpfs",    MS_NOSUID | MS_NODEV);
    mount("devpts",   "/dev/pts", "devpts",   MS_NOSUID | MS_NOEXEC);

    // Set hostname
    setHostname("zigllm");

    // Log to kernel ring buffer
    log("zigllm-os init: filesystems mounted");

    // Start s6-rc
    const s6_argv = [_:null]?[*:0]const u8{
        "/bin/s6-rc-init", "-c", "/etc/s6/compiled",
        "-l", "/run/s6/rc", "/run/s6/rc", null,
    };
    const empty_envp = [_:null]?[*:0]const u8{null};
    _ = linux.execve("/bin/s6-rc-init", &s6_argv, &empty_envp);

    // Fallback: rescue shell
    log("zigllm-os init: s6-rc-init failed, starting rescue shell");
    const sh_argv = [_:null]?[*:0]const u8{ "/bin/sh", null };
    _ = linux.execve("/bin/sh", &sh_argv, &empty_envp);

    // Halt if shell also fails
    _ = linux.syscall4(
        .reboot,
        REBOOT_MAGIC1,
        REBOOT_MAGIC2,
        REBOOT_CMD_HALT,
        0,
    );
    unreachable;
}

fn mount(
    src:    [*:0]const u8,
    dst:    [*:0]const u8,
    fstype: [*:0]const u8,
    flags:  u32,
) void {
    const rc = linux.mount(src, dst, fstype, flags, 0);
    if (rc != 0) log("init: mount failed");
}

fn setHostname(name: []const u8) void {
    _ = linux.syscall2(
        .sethostname,
        @intFromPtr(name.ptr),
        name.len,
    );
}

/// Write to /dev/kmsg via raw syscall — no std.posix.open in 0.13
fn log(msg: []const u8) void {
    // open("/dev/kmsg", O_WRONLY)
    const O_WRONLY: u32 = 1;
    const fd = linux.syscall2(
        .open,
        @intFromPtr("/dev/kmsg"),
        O_WRONLY,
    );
    if (fd > std.math.maxInt(i32)) return; // error
    const ifd: i32 = @intCast(fd);
    // write(fd, msg, len)
    _ = linux.syscall3(
        .write,
        @intCast(ifd),
        @intFromPtr(msg.ptr),
        msg.len,
    );
    const nl = "\n";
    _ = linux.syscall3(
        .write,
        @intCast(ifd),
        @intFromPtr(nl.ptr),
        nl.len,
    );
    // close(fd)
    _ = linux.syscall1(.close, @intCast(ifd));
}
