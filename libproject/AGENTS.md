# libproject — agent guide

The shared native core. Two things live here and both are load-bearing:

1. **The interop ABI** (`include/project/interop.h` + `src/interop.c`). This is
   an **append-only** wire contract (rules R1–R6 in the header). When you touch
   it:
   - Add fields only at the END of a section struct, above its `APPEND-ONLY`
     marker, OR add a NEW section bit. Never reorder/resize/repurpose.
   - Bump `PROJ_ABI_MINOR` (never `PROJ_ABI_MAJOR` — that is a break R1/R2
     forbid).
   - Update the `_Static_assert` size locks AND the `interop_test.c` fixture.
   - Write a changelog fragment under `changelog.d/changed/` and an ADR if the
     section is new.

2. **The hello stub** (`hello.{c,h}`) + **the reference shader**
   (`shaders/project.comp`). These are illustrative — replace with your real
   algorithm. Keep the double-accumulator discipline in any reduction (see the
   `.semgrep.yml` rule the repo ships).

Build: `meson setup build && meson compile -C build && meson test -C build`.
Format before commit: `clang-format -i` (config at repo root).
