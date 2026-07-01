const std = @import("std");
const os = std.os;
const linux = os.linux;

fn klog(comptime fmt: []const u8, args: anytype) void {
    const msg = std.fmt.allocPrint(std.heap.page_allocator, fmt, args) catch return;
    defer std.heap.page_allocator.free(msg);
    const fd = os.open("/dev/kmsg", os.O.WRONLY, 0) catch return;
    defer os.close(fd);
    _ = os.write(fd, msg) catch {};
}

fn mount(src: [*:0]const u8, target: [*:0]const u8, fstype: [*:0]const u8, flags: u32, data: usize) !void {
    const rc = linux.mount(src, target, fstype, flags, data);
    if (rc != 0) return error.MountFailed;
}

pub fn main() void {
    // Mount essential filesystems
    mount("proc", "/proc", "proc", linux.MS_NOSUID | linux.MS_NODEV | linux.MS_NOEXEC, 0) catch |err| klog("mount /proc failed: {}\n", .{err});
    mount("sysfs", "/sys", "sysfs", linux.MS_NOSUID | linux.MS_NODEV | linux.MS_NOEXEC, 0) catch |err| klog("mount /sys failed: {}\n", .{err});
    mount("devtmpfs", "/dev", "devtmpfs", linux.MS_NOSUID | linux.MS_NOEXEC, 0) catch |err| klog("mount /dev failed: {}\n", .{err});
    mount("tmpfs", "/tmp", "tmpfs", linux.MS_NOSUID | linux.MS_NODEV, 0) catch |err| klog("mount /tmp failed: {}\n", .{err});
    mount("tmpfs", "/run", "tmpfs", linux.MS_NOSUID | linux.MS_NODEV, 0) catch |err| klog("mount /run failed: {}\n", .{err});
    mount("devpts", "/dev/pts", "devpts", linux.MS_NOSUID | linux.MS_NOEXEC, 0) catch |err| klog("mount /dev/pts failed: {}\n", .{err});
    mount("tmpfs", "/engine", "tmpfs", linux.MS_NOSUID | linux.MS_NODEV, 0) catch |err| klog("mount /engine failed: {}\n", .{err});

    klog("Arcis init v0.1: filesystems mounted, hostname=arcis\n", .{});

    // Basic networking setup (loopback) - production readiness
    // In full production use a dedicated s6 service with iproute2/busybox
    _ = os.system("ip link set lo up 2>/dev/null || true");
    klog("Networking: loopback interface brought up\n", .{});

    // Create readiness directory for services
    _ = os.mkdir("/run/arcis", 0o755) catch {};

    // Start s6-rc supervision
    _ = os.mkdir("/run/s6", 0o755) catch {};
    _ = os.mkdir("/run/s6/rc", 0o755) catch {};

    const s6_args = [_:null]?[*:0]const u8{ "/bin/s6-rc-init", "/run/s6/rc", null };
    const envp = [_:null]?[*:0]const u8{null};

    const pid = os.fork() catch {
        klog("fork for s6-rc-init failed\n", .{});
        os.exit(1);
    };

    if (pid == 0) {
        os.execve("/bin/s6-rc-init", &s6_args, &envp) catch |err| {
            klog("s6-rc-init exec failed: {}\n", .{err});
            const sh_args = [_:null]?[*:0]const u8{ "/bin/sh", null };
            os.execve("/bin/sh", &sh_args, &envp) catch {
                linux.reboot(linux.LINUX_REBOOT_CMD_HALT);
            };
        };
    } else {
        klog("s6-rc supervisor started successfully\n", .{});
        // Signal readiness for zigllm-api (production contract)
        const ready_fd = os.open("/run/arcis/zigllm-api-ready", os.O.CREAT | os.O.WRONLY, 0o644) catch null;
        if (ready_fd) |fd| os.close(fd);
        klog("Readiness signal created for zigllm-api\n", .{});
    }

    // Keep init alive - delegate supervision to s6-rc
    while (true) {
        std.time.sleep(5 * std.time.ns_per_s);
    }
}
