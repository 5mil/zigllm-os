//! Clean shutdown and reboot sequences.
//! Called when init receives SIGTERM (shutdown) or SIGUSR1 (reboot).

const std   = @import("std");
const linux = std.os.linux;
const posix = std.posix;

pub const Action = enum { poweroff, reboot, halt };

pub fn shutdown(action: Action) noreturn {
    // 1. Signal s6 to stop all services
    _ = posix.kill(-1, posix.SIG.TERM) catch {};
    std.time.sleep(2_000_000_000); // 2s grace period

    // 2. Kill remaining processes
    _ = posix.kill(-1, posix.SIG.KILL) catch {};

    // 3. Sync filesystems
    _ = linux.sync();

    // 4. Unmount all
    _ = linux.umount2("/", linux.MNT_DETACH);

    // 5. Final reboot syscall
    const cmd: u32 = switch (action) {
        .poweroff => linux.LINUX_REBOOT_CMD_POWER_OFF,
        .reboot   => linux.LINUX_REBOOT_CMD_RESTART,
        .halt     => linux.LINUX_REBOOT_CMD_HALT,
    };
    _ = linux.reboot(linux.LINUX_REBOOT_MAGIC1, linux.LINUX_REBOOT_MAGIC2, cmd, null);
    unreachable;
}
