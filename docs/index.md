# PROJECT

A reusable boilerplate for native (C/C++) + GPU + FFmpeg-filter projects.

- **Minimal seed** — `libproject` (an append-only side-data interop ABI + a hello
  stub), one Vulkan reference shader, and an FFmpeg patch stack.
- **Full GPU matrix** — CUDA / HIP / Metal / SYCL / Vulkan dispatch scaffolding
  (see `examples/full-gpu-matrix/`).

Start with [Build & test](development/build.md) and the
[Principles](principles.md). The load-bearing contracts are the
[Interop ABI](api/interop-abi.md) (append-only) and the GPU dispatch +
`-ENOSYS` stub pattern ([ADR-0004](adr/0004-gpu-backend-dispatch.md)).
