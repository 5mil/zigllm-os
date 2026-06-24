//! reap.zig — Arcis OS zombie reaper
//! PID 1 must reap all orphaned child processes.
//! Call reapChildren() in a loop or from SIGCHLD handler.

const std   = @import("std");
const linux = std.os.linux;

/// Reap all terminated child processes (non-blocking).
/// Safe to call repeatedly; returns when no more zombies exist.
pub fn reapChildren() void {
    while (true) {
        var status: u32 = 0;
        const rc = linux.syscall4(
            .wait4,
            @bitCast(@as(i64, -1)), // WAIT_ANY
            @intFromPtr(&status),
            1,  // WNOHANG
            0,
        );
        // rc == 0 means no more children to reap.
        // rc < 0 means ECHILD (no children at all).
        if (rc == 0 or @as(isize, @bitCast(rc)) < 0) break;
    }
}
