---
name: add-gpu-backend
description: Scaffold a new GPU compute backend (dispatch + common + stubs + kernel + meson wiring) in the full-gpu-matrix example, mirroring the CUDA/SYCL/HIP/Metal pattern.
---

# add-gpu-backend

Use when adding a new GPU backend to `examples/full-gpu-matrix/core/`.

## What it generates

For a backend `<name>` (lowercase, e.g. `oneapi`, `webgpu`):

- `src/<name>/dispatch_strategy.{h,c}` — env-override dispatch (`PROJ_<NAME>_DISPATCH`).
- `src/<name>/common.{h,c}` — host glue behind `HAVE_<NAME>` (returns -ENOSYS
  until you wire the real runtime).
- `src/<name>/stubs.c` — the -ENOSYS surface for the disabled build.
- `src/<name>/scale_kernel.<ext>` — a trivial illustrative kernel.
- `src/<name>/AGENTS.md` — the backend's review guide.

## Run

```bash
.claude/skills/add-gpu-backend/scaffold.sh <name> <kernel-ext>
# e.g. scaffold.sh oneapi cpp
```

## Then, by hand (the meson wiring the script can't safely automate)

1. Add an `enable_<name>` option to `core/meson_options.txt`.
2. In `core/meson.build`, add an `if is_<name>_enabled … else backend_sources +=
   files('src/<name>/stubs.c') endif` block following the CUDA/HIP pattern —
   including the device-code custom_target (compiler → blob → embed) if the
   backend compiles offline kernels.
3. Keep the `common.c` / `stubs.c` signatures identical (the reviewer agents
   block on drift).
4. Verify: `meson setup /tmp/_chk examples/full-gpu-matrix/core` configures with
   the backend disabled, then `-Denable_<name>=true` with the toolchain present.

Invoke the matching reviewer agent (or write one) before merging.
