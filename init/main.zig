//! init/main.zig — Arcis OS PID 1
//! Mounts virtual filesystems, sets hostname to "arcis",
//! launches s6-rc supervisor, falls back to rescue shell.

const std   = @import("std");
const linux = std.os.linux;

const MS_NOSUID: u32 = 2;
const MS_NODEV:  u32 = 4;
const MS_NOEXEC: u32 = 8;

const REBOOT_MAGIC1:      u32 = 0xfee1dead;
const REBOOT_MAGIC2:      u32 = 672274793;
const REBOOT_CMD_HALT:    u32 = 0xcdef0123;
const REBOOT_CMD_POWER:   u32 = 0x4321fedc;
const REBOOT_CMD_RESTART: u32 = 0x01234567;

pub fn main() noreturn {
    mount("proc",     "/proc",    "proc",     MS_NOSUID | MS_NODEV | MS_NOEXEC);
    mount("sysfs",    "/sys",     "sysfs",    MS_NOSUID | MS_NODEV | MS_NOEXEC);
    mount("devtmpfs", "/dev",     "devtmpfs", MS_NOSUID | MS_NOEXEC);
    mount("tmpfs",    "/tmp",     "tmpfs",    MS_NOSUID | MS_NODEV);
    mount("tmpfs",    "/run",     "tmpfs",    MS_NOSUID | MS_NODEV);
    mount("devpts",   "/dev/pts", "devpts",   MS_NOSUID | MS_NOEXEC);

    // Mount /engine as tmpfs scratch space for Arcis binaries at runtime.
    mount("tmpfs",    "/engine",  "tmpfs",    MS_NOSUID | MS_NODEV);

    setHostname("arcis");
    log("arcis-os init: filesystems mounted");
    log("arcis-os init: hostname=arcis");

    // Populate /run/s6 directories expected by s6-rc-init.
    mkdirLog("/run/s6");
    mkdirLog("/run/s6/rc");

    log("arcis-os init: starting s6-rc supervisor");
    const s6_argv = [_:null]?[*:0]const u8{
        "/bin/s6-rc-init",
        "-c", "/etc/s6/compiled",
        "-l", "/run/s6/rc",
        "/run/s6/rc",
        null,
    };
    const empty_envp = [_:null]?[*:0]const u8{null};
    _ = linux.execve("/bin/s6-rc-init", &s6_argv, &empty_envp);

    log("arcis-os init: s6-rc-init failed — starting rescue shell");
    const sh_argv = [_:null]?[*:0]const u8{ "/bin/sh", null };
    _ = linux.execve("/bin/sh", &sh_argv, &empty_envp);

    log("arcis-os init: rescue shell failed — halting");
    _ = linux.syscall4(.reboot, REBOOT_MAGIC1, REBOOT_MAGIC2, REBOOT_CMD_HALT, 0);
    unreachable;
}

fn mount(src: [*:0]const u8, dst: [*:0]const u8, fstype: [*:0]const u8, flags: u32) void {
    const rc = linux.mount(src, dst, fstype, flags, 0);
    if (rc != 0) log("init: mount failed");
}

fn setHostname(name: []const u8) void {
    _ = linux.syscall2(.sethostname, @intFromPtr(name.ptr), name.len);
}

fn mkdirLog(path: [*:0]const u8) void {
    _ = linux.syscall2(.mkdir, @intFromPtr(path), 0o755);
}

fn log(msg: []const u8) void {
    const O_WRONLY: u32 = 1;
    const fd = linux.syscall2(.open, @intFromPtr("/dev/kmsg"), O_WRONLY);
    if (fd > std.math.maxInt(i32)) return;
    const ifd: i32 = @intCast(fd);
    _ = linux.syscall3(.write, @intCast(ifd), @intFromPtr(msg.ptr), msg.len);
    const nl = "\n";
    _ = linux.syscall3(.write, @intCast(ifd), @intFromPtr(nl.ptr), nl.len);
    _ = linux.syscall1(.close, @intCast(ifd));
}
