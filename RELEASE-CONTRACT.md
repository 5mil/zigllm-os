# Stable Release Contract for Arcis / zigllm Stack

Draft for item 0.1.5. This defines expected behavior for boot, serve, infer, search, media, workflow, and knowledge operations.

## Boot Contract
- Target: < 3 seconds from kernel start to zigllm-api listening on :8080.
- Init (PID 1) mounts essential FS, starts s6-rc, ensures core services up.
- Consistent QEMU x86_64 / aarch64 boots; graceful shutdown/reboot.
- Panic capture via serial/kmsg; recovery mode with maintenance shell.

## Serve / API Contract
- OpenAI-compatible endpoints (/v1/chat/completions, /v1/models, etc.).
- zigllm-api starts before zigllm-ui; reports readiness (e.g., health endpoint or s6 notification).
- Streaming support for inference responses.

## Infer Contract
- GGUF model loading and inference (CPU baseline, accelerators planned).
- Resource checks before model load (memory, GPU).
- Tier-aware (forma minimal, visio full).

## Search / RAG Contract
- Ingest documents into vector store.
- Retrieval augmented generation with configurable top-k, rerank.
- Persistent knowledge base.

## Media / Workflow / Knowledge
- Media: Image/video handling pipeline (planned).
- Workflow: Agent orchestration, tool use.
- Knowledge: Ontology, naming system, ancient text library (per arcis description).
- Dashboard for monitoring.

## Compatibility & Versioning
- See COMPATIBILITY.md for arch/tier/model matrix.
- Semantic versioning for binaries and image.
- Backward compat for API where possible.

## Operations
- Log rotation and persistent /var/log.
- Firmware auto-install for GPUs.
- Single flashable image containing everything.

This contract will be refined with implementation and testing. Update as features land.
