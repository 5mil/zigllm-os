# Production-Level Readiness & Cross-Repo Integration Plan

**For Arcis + zigllm-os + zigllm-ui Stack**

**Version**: 0.1 (Initial Draft)
**Date**: 2026-07-01
**Status**: Living document — update with progress
**Owners**: Core maintainers (start with zigllm-os as integration hub)
**Related**:
- zigllm-os tracking issue #1 (full checklist)
- arcis tracking issue #1 (core inference)
- New docs: QEMU.md, COMPATIBILITY.md, RELEASE-CONTRACT.md

---

## 1. Executive Summary & Vision

**Goal**: Deliver a production-ready, unified, flashable AI engine stack that boots reliably in < 3 seconds to a fully functional OpenAI-compatible inference + RAG + agent system across x86_64, ARM64 (Pi 5, Jetson), and future RISC-V, with three UI tiers (forma minimal, figura workbench, visio full).

**Key Outcomes**:
- Single reproducible end-to-end build & image.
- Stable release contract enforced.
- Comprehensive compatibility matrix with verified support.
- Production pillars: reliability, security, observability, performance, maintainability.
- Seamless cross-repo integration (OS provides runtime + services; arcis provides core intelligence; zigllm-ui provides presentation).

This plan turns the current skeleton into a shippable product while completing the original remaining build checklist.

---

## 2. Current State Assessment (as of deep analysis)

**Strengths**:
- Strong structural foundation in all three repos (build.zig, tiered UI, s6-rc services, init mounts, image packing, firmware dir).
- Good separation of concerns (OS backbone, core engine, UI tiers).
- Existing cross-wiring in assemble.sh (pulls arcis/ui binaries).
- New foundational docs and tracking issues created.

**Gaps (high-level)**:
- No end-to-end working boot or inference yet.
- Minimal implementation in arcis (no GGUF/RAG/OpenAI code).
- Path inconsistencies (kernel outputs vs rootfs).
- Limited production features (networking, logging, recovery, readiness signaling, security, CI, testing).
- No unified build/CI across repos.
- Early-stage hardware verification.

**Maturity Level**: Pre-alpha / late skeleton. Ready for focused implementation phase.

---

## 3. Goals & Success Criteria

### Must-Have for v0.1 Production-Ready Image
- [ ] Consistent QEMU x86_64 + aarch64 boot to running zigllm-api (< 3s).
- [ ] Basic GGUF inference + simple RAG working via OpenAI-compatible endpoint.
- [ ] All three UI tiers build and connect via IPC.
- [ ] Single flashable image containing everything.
- [ ] Release contract + compatibility matrix documented and partially verified.
- [ ] Basic CI (build + QEMU smoke test).
- [ ] Core production pillars started (logging, error handling, graceful shutdown).

### Stretch for v0.2
- Real hardware verification (Pi 5, Jetson).
- Full streaming + advanced RAG/agents.
- Security hardening + signed images.
- Comprehensive test suite + observability.
- Automated multi-arch builds.

**KPIs**:
- Boot time to API ready
- Inference latency (p50/p99)
- Image size per tier
- Mean time to recovery
- Test coverage %
- CI pass rate

---

## 4. Phased Roadmap (Aligned with 0.2 Delivery Order)

### Phase 0: Foundation & Stabilization (1-2 weeks)
- Complete path integration in zigllm-os (kernel + rootfs).
- Make QEMU boots consistent and documented.
- Add basic networking + readiness signaling in init/services.
- Create unified cross-repo build script / GitHub Actions.
- Flesh out arcis minimal inference stub + OpenAI endpoint prototype.
- Expand COMPATIBILITY.md and RELEASE-CONTRACT.md with initial data.
- Set up basic CI in all repos.

**Deliverable**: First bootable image with stub inference that responds to simple prompts.

### Phase 1: Core Functionality (3-6 weeks)
- Full GGUF loader + basic inference in arcis.
- RAG ingest/retrieve pipeline (minimal).
- Complete forma framebuffer + streaming in zigllm-ui.
- Service dependency graph + ordered startup (api before ui).
- Log rotation, persistent logs, basic recovery mode.
- Firmware automation + initial GPU driver verification.
- Real QEMU timing + load testing.

**Deliverable**: Functional end-to-end stack (boot → infer → UI) in QEMU.

### Phase 2: Production Hardening (6-12 weeks)
- Comprehensive testing (unit, integration, hardware smoke, chaos).
- Security (seccomp, capabilities, signed images, SBOM).
- Observability (structured logs, metrics, health endpoints, tracing).
- Performance optimization (binary sizes, boot time, inference speed).
- Multi-arch CI + release automation.
- Real hardware validation (Pi 5, Jetson, x86_64).
- Documentation, examples, onboarding.

**Deliverable**: Production-ready v0.1 release with verified matrix.

### Phase 3: Advanced Features & Scale (ongoing)
- Advanced agents, workflow, media, ontology, ancient text library.
- WebGPU / full visio tier maturity.
- Distributed / clustered deployments.
- Model quantization, speculative decoding, etc.
- Community contributions & plugin system.

---

## 5. Cross-Repo Integration Architecture

### Recommended Integration Model
- **zigllm-os** = Integration hub and runtime foundation.
  - Owns unified build orchestration (or top-level workflow).
  - Provides PID 1, s6-rc supervision, filesystem layout, networking, logging, recovery.
  - Exposes clear contract: /engine/ binaries, /etc/arcis/env, readiness files, service definitions.

- **arcis** = Intelligence core (submodule or separate build artifact).
  - Consumes tier/env from OS.
  - Exposes OpenAI-compatible HTTP API + internal IPC.
  - Provides model loading, inference, RAG, agents.

- **zigllm-ui** = Presentation layer (built per tier).
  - Connects exclusively via shared IPC to zigllm-api.
  - No direct model or OS dependencies.

### Key Integration Points
1. **Build Time**:
   - Unified GitHub Actions or Makefile that builds all three in dependency order.
   - Shared version tagging and artifact naming.
   - Size guards and compatibility checks enforced in CI.

2. **Runtime Contract** (enforce via RELEASE-CONTRACT.md):
   - Binaries placed in /engine/.
   - Environment via /etc/arcis/env (tier, port, host, model paths).
   - Readiness: s6 notification or file-based signals.
   - Service ordering: zigllm-api (or core) before zigllm-ui.
   - Logging: stdout/stderr to s6-log or /var/log with rotation.

3. **IPC Layer**:
   - Shared zigllm-ui/ipc/ used by all tiers.
   - Define stable API surface (JSON-RPC or HTTP internal).

4. **Configuration & Models**:
   - Centralized config in OS image or mounted volume.
   - Model files bundled or downloaded at first boot (with verification).

5. **Versioning & Compatibility**:
   - Semantic versioning across stack.
   - Compatibility matrix as source of truth.
   - Breaking changes via deprecation policy.

### Proposed Repo Structure Enhancements
- Add `.gitmodules` or build script that references the other repos (or use workspace-style in Zig).
- Top-level `stack/` or `integration/` dir in zigllm-os for orchestration scripts.
- Shared `contracts/` or `specs/` directory (or separate repo) for API contracts, readiness protocol, etc.

---

## 6. Production Readiness Pillars (Detailed)

### 6.1 Build, CI/CD & Reproducibility
- GitHub Actions in all repos + cross-repo workflow in zigllm-os.
- Matrix builds for arch + tier.
- Reproducible builds (pinned deps, hermetic where possible).
- Artifact signing + SBOM generation.
- Automated image publishing (GitHub Releases + OCI registry).

### 6.2 Testing & Validation
- Unit tests (Zig `test`).
- Integration tests (QEMU-based boot + API smoke).
- Hardware-in-the-loop for Pi 5 / Jetson (via self-hosted runners or manual).
- Performance benchmarks (boot time, inference latency).
- Chaos / fault injection for recovery.
- Compatibility matrix as living test oracle.

### 6.3 Runtime Reliability & Resilience
- Robust init with comprehensive error handling and recovery paths.
- s6-rc for supervision + automatic restarts.
- Health checks and readiness probes.
- Graceful shutdown and reboot under load.
- Panic capture, core dumps (where safe), serial diagnostics.
- Watchdog timers.

### 6.4 Security & Compliance
- Minimal attack surface (no package manager, stripped kernel).
- seccomp filters, capabilities dropping, user namespaces.
- Signed images and verified boot (future).
- Input sanitization on all endpoints.
- Dependency scanning + SBOM.
- Audit logging for sensitive operations.

### 6.5 Observability
- Structured logging (JSON) with levels and context.
- Metrics endpoint (Prometheus format) for boot time, inference stats, resource usage.
- Distributed tracing (future, OpenTelemetry).
- Health / ready / live endpoints.
- Log aggregation strategy for production deployments.

### 6.6 Performance & Efficiency
- Binary size budgets enforced (forma <2MB hard).
- Boot time optimization (parallel service start, lazy loading).
- Inference optimizations (quantization, batching, speculative decoding).
- Resource-aware startup (model loading only when present).

### 6.7 Packaging, Deployment & Operations
- Single flashable image (raw, ISO, or OCI).
- Support for different deployment targets (embedded, server, edge).
- First-boot setup (model download, config wizard).
- Update mechanism (A/B or delta updates).
- Backup / restore for persistent data (/var, models).

### 6.8 Hardware & Accelerator Support
- Automated firmware installation.
- Verified driver loading (amdgpu, nvidia, Jetson CUDA).
- Tiered acceleration (CPU baseline → GPU → specialized).
- Power management awareness.

### 6.9 Documentation, Onboarding & Contracts
- Living docs: READMEs, QEMU.md, COMPATIBILITY.md, RELEASE-CONTRACT.md, this plan.
- Architecture decision records (ADRs).
- Example deployments and tutorials.
- API reference + OpenAPI spec for endpoints.
- Contributor guide and code of conduct.

---

## 7. Governance, Process & Tooling

- **Issue & PR Management**: Use the two tracking issues as hubs. Label everything (build, inference, ui, integration, security, etc.).
- **Release Process**: Follow semantic versioning. Gate releases on checklist items + matrix verification + contract compliance.
- **Branching**: main = stable; feature/* or phase/* branches.
- **Code Review**: Require reviews for core changes; automated checks via CI.
- **Tooling Recommendations**:
  - Zig build system (already in use) + zig build --release=fast.
  - s6 + s6-rc (supervision).
  - QEMU for CI testing.
  - GitHub Actions (matrix).
  - Optional: Nix or Docker for hermetic builds.
  - Monitoring: Prometheus + Grafana for deployed instances.

---

## 8. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Path/integration bugs | Medium | High | Dedicated integration phase + automated tests |
| Inference performance / correctness | High | High | Start with proven backend (llama.cpp bindings) then optimize |
| Hardware variability | Medium | Medium | Strong QEMU first, then incremental real HW testing |
| Security vulnerabilities in minimal OS | Low-Medium | High | Security review in Phase 2; minimal surface by design |
| Cross-repo coordination | Medium | Medium | Clear contracts + single integration hub (zigllm-os) |
| Scope creep (advanced features) | High | Medium | Strict phase gates; defer to Phase 3 |

---

## 9. Immediate Next Actions (Prioritized)

1. **zigllm-os (this week)**:
   - Fix kernel/rootfs path integration.
   - Make first successful QEMU boot and capture timing.
   - Add basic networking + readiness signaling.
   - Merge new docs (QEMU.md, COMPATIBILITY.md, RELEASE-CONTRACT.md, this plan) into main READMEs.

2. **arcis (parallel)**:
   - Create minimal inference stub + OpenAI-compatible endpoint prototype.
   - Define internal model config format.

3. **Cross-repo (this week)**:
   - Create top-level integration workflow or script in zigllm-os.
   - Align on runtime contract details (env vars, readiness protocol).

4. **All repos**:
   - Add basic GitHub Actions CI (build + size check + QEMU smoke where possible).
   - Update tracking issues with progress.

5. **Governance**:
   - Assign owners for each pillar.
   - Schedule regular syncs (e.g., weekly).

---

## 10. Appendices

- Original Remaining Build Checklist (reference in zigllm-os issue #1).
- Current file structure and key scripts (see previous analysis).
- Glossary: forma/figura/visio tiers, s6-rc, GGUF, RAG, etc.

---

**This plan is the north star.** Update it frequently. Every new feature or fix should map back to a phase and pillar.

**Next step for maintainers**: Review this plan, assign owners to phases/pillars, and start executing Phase 0 tasks. The tracking issues are the execution boards.

Contributions and feedback welcome via issues/PRs.
