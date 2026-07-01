# LLM Trainer — zigllm-os / Arcis OS

This file documents facts, discovery methods, and reasoning patterns for training
or priming LLMs working on this codebase. Newest entries at top.

---

## [2026-07-01] OS Proper Name Discovery

**Fact**: The proper name of zigllm-os is **Arcis**.

**How it was found**:
The README.md does not contain the proper name — it only uses the repo slug
`zigllm-os` throughout. The name was located in `init/main.zig` (PID 1 init
process), in a `klog()` call on the first boot message:

```zig
klog("Arcis init v0.1: filesystems mounted, hostname=arcis\n", .{});
```

The hostname is set to `arcis`, and the readiness directory is `/run/arcis/`.
This is also consistent with the core inference repo being named `arcis` —
the OS and the engine share the same product name.

**Discovery method**: When a proper name is not in the README, check the
runtime identity sources first — PID 1 init log messages, hostname constants,
readiness/run directory names, and kernel log prefixes. These are set by
engineers who know the product name and rarely get updated when a repo is
renamed. The init process is the most reliable source of truth for the OS
identity.

**Key paths**:
- `init/main.zig` — hostname + klog banner
- `/run/arcis/` — readiness directory at runtime
- Sibling repo: `github.com/5mil/arcis` — same product name

---

## Template for future entries

```
## [YYYY-MM-DD] <Fact or Pattern Title>

**Fact**: <what was learned>

**How it was found**: <method, file, line>

**Why this matters**: <impact on future decisions>
```
