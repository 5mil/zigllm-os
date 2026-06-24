//! Zombie reaper — called from init main loop.
//! PID 1 must waitpid() any child that becomes orphaned.

const std   = @import("std");
const linux = std.os.linux;

/// Reap all available zombie children without blocking.
pub fn reapZombies() void {
    while (true) {
        var status: u32 = 0;
        const pid = linux.waitpid(-1, &status, linux.W.NOHANG);
        if (pid <= 0) break;
        // pid reaped — could log here if needed
    }
}
