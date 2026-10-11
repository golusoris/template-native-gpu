<!-- markdownlint-disable MD013 -->
# Architecture overview (C4 L1–L2)

## Context

PROJECT is a native (C/C++) compute core plus FFmpeg filters that process frames
on the GPU (zero-copy in VRAM) on their way to a hardware encoder, and a
versioned side-data ABI that lets producers and consumers exchange per-frame
metadata across a filtergraph or an IPC boundary.

## Containers

| Container | Tech | Responsibility |
| --- | --- | --- |
| `libproject` | C11 shared lib | The interop ABI (pack/parse) + the core compute. The single source of truth both filters and tooling link. |
| `vf_project_*` filters | FFmpeg + Vulkan compute | In-VRAM pre-encode passes; attach the interop blob as SEI side data. |
| Full GPU matrix | meson + CUDA/HIP/Metal/SYCL/Vulkan | Multi-backend compute dispatch behind one host layer (example variant). |

## The interop ABI (the spine)

```text
producer (vf_project_*) --[UUID-prefixed flat blob on the AVFrame]--> consumer
                              ProjSideData header
                              ProjSectionDir dir[]
                              section payloads (append-only)
```

Append-only evolution (ADR-0002) means an N+1-minor producer's blob stays
parseable by an N-minor consumer: read `min(known_size, dir.size)` bytes.

## GPU dispatch (matrix variant)

One host-side `select_strategy()` per backend reads an env override
(`PROJ_<BACKEND>_DISPATCH`) via a once-snapshotted getenv, falling back to a
per-backend default. Device code is compiled offline (nvcc/hipcc/xcrun/icpx/
glslang) and embedded into the library; a disabled backend links a `-ENOSYS`
stub so symbols always resolve. See ADR-0004.

## Cross-cutting

Supply chain (build provenance at SLSA Build L2 + cosign + SBOM), security scans
(CodeQL/semgrep/trivy/gitleaks), sanitizers + fuzz, and an app-agnostic Helm
chart with GPU node affinity. See the diagrams you add under
`docs/architecture/` as the project grows.
