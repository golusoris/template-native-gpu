<!-- markdownlint-disable MD013 MD041 -->
# ADR-0004: Multi-backend GPU dispatch + -ENOSYS stubs

- **Status**: Accepted
- **Date**: 2026-01-01
- **Deciders**: maintainers
- **Tags**: gpu, build, cuda, hip, metal, sycl

## Context

The full-matrix variant supports five GPU backends (CUDA, HIP, Metal, SYCL,
Vulkan). Each has a different device-code toolchain. We need: (a) the tree to
build on a stock runner with no GPU SDK, (b) one host-side dispatch surface, and
(c) no link-time breakage when a backend is disabled.

## Decision

Each backend (1) compiles device code via its own meson `custom_target`
(nvcc→bin2c, hipcc→xxd, xcrun→metallib, icpx→.o, glslang→.spv), (2) shares the
backend-agnostic host glue (`gpu_dispatch_parse.h`, `gpu_dispatch_env`,
`gpu_picture_pool`), and (3) ships a `stubs.c` whose entry points return
`-ENOSYS` for the disabled build, kept in exact signature lockstep with the
real `common.c`. Backends are OFF/`auto` by default. SYCL's `-fsycl` link arg is
propagated once via `declare_dependency(link_args:['-fsycl'])`.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
| --- | --- | --- | --- |
| One backend only | Simple | Locks out hardware | Defeats the purpose |
| Runtime dlopen of backend plugins | Decoupled | Complex packaging, ABI surface per plugin | Heavier than custom_target embedding |
| custom_target + stub TUs | Builds anywhere, single .so | Per-backend stub discipline | — (chosen) |

## Consequences

- Positive: `meson setup && compile` works with no GPU SDK; symbols always exist.
- Negative: every public entry needs a stub twin; reviewer agents enforce it.
- Follow-ups: the `add-gpu-backend` skill scaffolds the pattern for new backends.

## References

- `examples/full-gpu-matrix/README.md`, `examples/full-gpu-matrix/core/meson.build`.
