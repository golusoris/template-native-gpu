<!-- markdownlint-disable MD013 -->
# Claude Code guide — PROJECT

> Claude Code-specific guide. For cross-tool conventions read [AGENTS.md](AGENTS.md)
> first; this file extends it. This is a **template** — see README.md for the
> placeholder scheme before you rename anything.

## What this is

A reusable boilerplate for native (C/C++) + GPU + FFmpeg-filter projects. Two
shapes:

- **Minimal seed** (repo root): `libproject` (an append-only interop ABI + a
  hello stub) + one Vulkan reference shader + an FFmpeg patch stack.
- **Full GPU matrix** (`examples/full-gpu-matrix/`): CUDA / HIP / Metal / SYCL /
  Vulkan dispatch scaffolding behind one host layer.

## How to build / test

```bash
meson setup build && meson compile -C build      # libproject + interop test + shader
meson test -C build --suite=fast                 # the pre-push gate
ninja -C build install                           # install so the FFmpeg patch sees libproject

meson setup build-gpu examples/full-gpu-matrix/core && meson test -C build-gpu
```

## Skills available (`.claude/skills/`)

| Skill | When |
| --- | --- |
| `add-gpu-backend` | Adding a CUDA/HIP/Metal/SYCL-shaped backend to the matrix example |
| `new-adr` | Recording an architecture decision |
| `render-changelog` | Previewing the changelog.d/ fragments |
| `cut-release` | Driving a release-please release |

## Reviewer agents (`.claude/agents/`)

`c-reviewer`, `cuda-reviewer`, `sycl-reviewer`, `hip-reviewer`, `metal-reviewer`,
`meson-reviewer`, `pr-body-checker`. Invoke the relevant one before merging a
change in its area.

## Hooks active (`.claude/hooks/`)

- PreToolUse `block-unsafe-bash.sh` — blocks destructive commands + `--no-verify`.
- PostToolUse `auto-format-on-edit.sh` — clang-formats C/C++ edits (skips
  ffmpeg-patches/files/).
- PostToolUse `docs-drift-warn.sh` — warns when an interop/backend/build change
  needs a companion ABI bump / stub / changelog.
- SessionStart / Stop — orientation + pre-push reminders.

## Don't

- Don't break the interop ABI. It is **append-only** (libproject/AGENTS.md R1–R6).
- Don't let a GPU backend's `common.c` and `stubs.c` drift out of signature
  lockstep — the disabled build links the stub.
- Don't remove the `-fsycl` link-arg propagation in the SYCL meson dependency.
- Don't `fmt.Println`-equivalent (`printf` debug) in library code.
- Don't add features beyond the task. Don't write multi-paragraph comments.
- Don't silence a linter without a justification comment next to the suppression.
- Don't create new markdown docs unless asked.

## Every commit touching new/changed modules

- Add a `changelog.d/<section>/` fragment for user-facing changes.
- Update the relevant `AGENTS.md` (per-subpackage) + the README "Landed" list.
- ABI change → bump `PROJ_ABI_MINOR`, update the static-assert locks + the
  conformance test, write an ADR.
