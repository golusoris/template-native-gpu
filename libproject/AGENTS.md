# libproject — agent guide

Shared native core. Two load-bearing items:

1. **Interop ABI** (`include/project/interop.h` + `src/interop.c`).
   **Append-only** wire contract (rules R1–R6 in header). Edits:
   - Add fields only at END of section struct, above `APPEND-ONLY`
     marker, OR add NEW section bit. Never reorder/resize/repurpose.
   - Bump `PROJ_ABI_MINOR` (never `PROJ_ABI_MAJOR` — breaking change R1/R2
     forbid).
   - Update `_Static_assert` size locks AND `interop_test.c` fixture.
   - Write changelog fragment under `changelog.d/changed/` + ADR when section
     new.

2. **Hello stub** (`hello.{c,h}`) + **reference shader**
   (`shaders/project.comp`). Illustrative -> replace with real algorithm.
   Keep double-accumulator discipline in any reduction (see `.semgrep.yml`
   rule repository ships).

Build: `meson setup build && meson compile -C build && meson test -C build`.
Format before commit: `clang-format -i` (config at repository root).
