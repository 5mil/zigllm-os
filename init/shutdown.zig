//! shutdown.zig — Arcis OS clean shutdown sequence
//! Sends SIGTERM to all processes, waits, then issues reboot syscall.

const std   = @import("std");
const linux = std.os.linux;

const REBOOT_MAGIC1:    u32 = 0xfee1dead;
const REBOOT_MAGIC2:    u32 = 672274793;
const REBOOT_CMD_HALT:  u32 = 0xcdef0123;
const REBOOT_CMD_POWER: u32 = 0x4321fedc;
const REBOOT_CMD_RESTART: u32 = 0x01234567;

pub const ShutdownCmd = enum { halt, poweroff, restart };

pub fn shutdown(cmd: ShutdownCmd) noreturn {
    // 1. Broadcast SIGTERM to all processes.
    _ = linux.syscall2(.kill, @bitCast(@as(i64, -1)), std.os.linux.SIG.TERM);
    // 2. Wait 2 seconds for graceful exit.
    var ts = linux.timespec{ .tv_sec = 2, .tv_nsec = 0 };
    _ = linux.syscall2(.nanosleep, @intFromPtr(&ts), 0);
    // 3. Broadcast SIGKILL.
    _ = linux.syscall2(.kill, @bitCast(@as(i64, -1)), std.os.linux.SIG.KILL);
    // 4. Sync filesystems.
    _ = linux.syscall0(.sync);
    // 5. Reboot syscall.
    const reboot_cmd: u32 = switch (cmd) {
        .halt    => REBOOT_CMD_HALT,
        .poweroff => REBOOT_CMD_POWER,
        .restart => REBOOT_CMD_RESTART,
    };
    _ = linux.syscall4(.reboot, REBOOT_MAGIC1, REBOOT_MAGIC2, reboot_cmd, 0);
    unreachable;
}
