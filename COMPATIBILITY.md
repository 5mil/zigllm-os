# Compatibility Matrix for Arcis / zigllm Stack

Initial formal matrix (advances 0.1.6). To be expanded with testing.

## Architectures
| Arch     | QEMU | Real HW (verified) | Kernel Config | Notes |
|----------|------|--------------------|---------------|-------|
| x86_64  | Yes (improved targets) | Planned | config.x86_64 | Primary dev target |
| aarch64 | Yes (new target)      | Planned (Pi 5, Jetson) | config.aarch64 | Raspberry Pi 5 / Jetson focus |
| riscv64 | Planned               | Planned | TBD           | Future |

## Tiers (zigllm-ui)
| Tier   | Binary Size Target | Rendering          | Features                  | Status |
|--------|--------------------|--------------------|---------------------------|--------|
| forma  | < 2MB             | PSF2 / fb0 / DRM  | Minimal framebuffer text, basic IPC | Skeleton + build flags |
| figura | 2-8MB             | TTF / DRM-KMS     | Workbench, modular GPU   | Build support |
| visio  | ~25MB+            | WebGPU / mach     | Full node graph, WASM    | Build support |

## Models / Accelerators (arcis)
| Model Format | Inference Backend | Accelerators     | RAG     | OpenAI Compat | Status |
|--------------|-------------------|------------------|---------|---------------|--------|
| GGUF        | Planned (llama.cpp or Zig native) | CPU, planned CUDA/ROCm/Vulkan | Planned | Planned endpoint | Early (no code yet) |
| Others      | TBD               | TBD              | TBD     | TBD           | Open   |

## Hardware Accelerators
| Accelerator | Supported in OS | Driver/Firmware | Verified |
|-------------|-----------------|-----------------|----------|
| CPU (generic) | Yes            | N/A            | Planned |
| GPU (amdgpu/nvidia) | Planned     | firmware/ dir  | Planned |
| Jetson CUDA | Planned        | CUDA + DRM     | Planned |

## Boot / Services
| Item                  | x86_64 QEMU | aarch64 QEMU | Real HW | Notes |
|-----------------------|-------------|--------------|---------|-------|
| Consistent boot      | In progress | In progress | Planned | See QEMU.md and issue #1 |
| s6-rc supervision    | Skeleton   | Skeleton    | Planned | Services/ + assemble.sh |
| Networking           | Basic (lo planned) | Same     | Planned | No full net yet in init |
| zigllm-api readiness | Configured | Same        | Planned | /etc/arcis/env + services |

See also: README.md, QEMU.md, tracking issue #1.
Update with test results.
