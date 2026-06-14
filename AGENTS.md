<!-- markdownlint-disable MD013 -->
# AGENTS.md — PROJECT

Cross-tool agent guide (Claude Code, Codex, Cursor, …). Tool-specific extras are
in [CLAUDE.md](CLAUDE.md).

## Layout

```text
template-native-gpu/
├── meson.build  meson_options.txt      # minimal-seed build (libproject)
├── libproject/                         # the shared native core
│   ├── include/project/                # public headers (append-only interop ABI)
│   ├── src/                            # interop.c + hello.c + version.c
│   ├── shaders/                        # Vulkan reference shader (glslang -> .spv)
│   └── test/                           # interop ABI conformance fixture
├── ffmpeg-patches/                     # vf_project_* Vulkan filter patch stack
│   ├── files/                          # canonical filter sources (source of truth)
│   ├── generate.sh  series.txt         # regenerate the stack
│   └── test/build-and-run.sh           # apply + build + smoke gate
├── examples/full-gpu-matrix/core/      # CUDA/HIP/Metal/SYCL/Vulkan dispatch example
│   └── src/{cuda,hip,metal,sycl,vulkan}/  + gpu_dispatch_*, gpu_picture_pool
├── changelog.d/                        # Keep-a-Changelog fragments (per section)
├── docs/{adr,development,architecture,api}/  mkdocs.yml
├── deploy/helm/project/                # app-agnostic Helm chart
├── docker/dev/  .devcontainer/         # dev images
├── .github/workflows/                  # CI + supply-chain + scorecard + security
├── scripts/{adr,release}/              # ADR allocator + changelog renderer
└── .claude/                            # agents, hooks, skills, settings
```

## Build / test / gate

```bash
meson setup build && meson compile -C build && meson test -C build
pre-commit run --all-files        # format + lint + gitleaks (the local gate)
```

## Principles (read docs/principles.md)

- **Power-of-10 (C-adapted)** — bounded control flow + loops, small functions,
  checked errors (the `proj_result` enum; no bare `-1` across an API boundary),
  zero clang-tidy/semgrep/gitleaks findings on merge.
- **SEI CERT C/C++** — bounded string ops, deterministic RNG, double accumulators
  in reductions for CPU↔GPU bit-exactness.
- **C4 + ADRs** — decisions in `docs/adr/` (Nygard); Accepted bodies immutable.
- **Wire/supply-chain** — RFC 9457 error bodies (if you add an HTTP surface),
  OpenAPI 3.1, SLSA L3 + cosign + SBOM on release.

## The two load-bearing patterns (don't break)

1. **Append-only interop ABI** — `libproject/include/project/interop.h` rules
   R1–R6. New fields at the end; bump `PROJ_ABI_MINOR`; update size locks + test.
2. **`-fsycl` link propagation + `-ENOSYS` stubs** — see
   `examples/full-gpu-matrix/README.md`.

## Conventions

Conventional Commits, SemVer, Keep-a-Changelog (via `changelog.d/`), Trunk-Based
Dev (short-lived branches off `main`). Format with gofumpt-equivalent for C:
clang-format (config at root). One-liner WHY comments only.
