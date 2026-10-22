<!-- markdownlint-disable MD013 -->
# golusoris/template-native-gpu Agent Operating Harness

<!-- praetor:head -->

Before concluding any turn:

```bash
make verify-all
```

`make verify-all` fails until project build + test commands exist; reasons in footer.
Pass = exit 0. Signed Ed25519 Exit-0 receipt only from `praetorctl gate run`; report no receipt it did not mint. Fail -> SARIF diagnostic distillation (<= 1500 tokens).

## Core Directives & Invariants

Adopted check = coverage state + mechanism; else audit scanner; else `unknown`. Gates = (generated `make verify-all` + praetor `lefthook.yml`); edits not reflected.

| Invariant | Rule | Adopted check | On fail |
| :--- | :--- | :--- | :--- |
| **HISS-01** control flow | recursion prohibited; call graph = DAG; C/C++: zero `goto` | `praetorctl audit` HISS scan in verify-all + lefthook pre-commit/pre-push: Go `goto`, recursion + plain-function call cycles; Rust, Python direct recursion; C `goto` | new finding fails verify-all, blocks commit, blocks push |
| **HISS-02** loops, I/O | scalar upper bound on every loop; explicit deadline on every I/O call | `praetorctl audit` HISS scan in verify-all + lefthook pre-commit/pre-push: unbounded loop shapes in Go, C, Rust, Python; I/O deadlines unchecked | new finding fails verify-all, blocks commit, blocks push |
| **HISS-03** memory | C/C++: zero heap allocation in hot simulation/tick loops | unknown | advisory |
| **HISS-04** complexity | McCabe cyclomatic <= 10, cognitive <= 12, statements <= 40; func LOC <= 60 (audit ceiling) | `praetorctl audit` HISS scan in verify-all + lefthook pre-commit/pre-push: function length only; other caps need repository linter | new finding fails verify-all, blocks commit, blocks push |
| **HISS-05** scoping | declare every identifier in smallest lexical scope serving it | unknown | advisory |
| **HISS-06** concurrency | explicit scalar upper bound on every worker pool + concurrent fan-out | unknown | advisory |
| **HISS-07** errors | every error handled or wrapped with context | unknown | advisory |
| **HISS-08** determinism | zero dynamic code execution (`eval` / `exec`); C/C++: zero banned libc (`gets` / `strcpy` / `sprintf`); a process signal's target is bounded above 1 (`killpg`, `kill(-pid)`, Go `syscall.Kill`) | `praetorctl audit` HISS scan in verify-all + lefthook pre-commit/pre-push: C banned calls, Python `eval` / `exec`, Go `syscall.Kill` / `unix.Kill` | new finding fails verify-all, blocks commit, blocks push |
| **HISS-09** reference safety | n/a: no such construct in repository languages; advisory | unknown | advisory |
| **HISS-10** warnings | zero warnings: compiler, linter, format sweeps | unknown | advisory |
| **HISS-11** supply chain | pinned lockfiles; zero floating tags; signed provenance | unknown | advisory |
| **HISS-12** secrets | zero credentials in Git history | unknown | advisory |
| **HISS-13** debt ratchet | recorded infractions never grow vs committed baseline | `praetorctl audit` ratchet vs `.standards-baseline.json` in verify-all + lefthook pre-commit/pre-push | growth fails verify-all, blocks commit, blocks push |
| **HISS-14** append-only ABI | public API append-only; breaking change = `!` subject + `Migration:` footer | unknown | advisory |
| **HISS-15** 3D testing | positive + negative + boundary tests, every public interface | unknown | advisory |
| **HISS-16** context integrity | single canonical `AGENTS.md`; vendor files compiled via `praetorctl compile-context` | `praetorctl compile-context --verify` in verify-all + lefthook pre-commit | drift fails verify-all, blocks commit |
| **HISS-17** state ledger | turn start `praetorctl state status`; turn end `praetorctl state sync .` | `praetorctl state sync .` in lefthook post-commit | none; records only |
| **HISS-18** CI efficiency | diff-aware gating via `praetorctl ci filter` | unknown | advisory |
| **HISS-19** reuse before writing | one behavior = one implementation; extend or call existing code | unknown | advisory |
| **HISS-20** replayable evidence | every enforcement claim backed by fixtures replayed both directions | unknown | advisory |
| **HISS-21** platform neutrality | gates, hooks, emitted templates run on Linux, macOS, Windows, or skip with stated reason | unknown | advisory |

## Operational Rules

1. **Act on verified state.** Read source files, run real commands before hypothesis or edit. Never guess flag names, library signatures, repo configuration from memory.

2. **Lead with output.** Direct answers, diffs, commands. No filler preamble, no "Based on", no restatement, no chatter.

3. **Context transpiler first.** Never edit `CLAUDE.md`, `.cursor/rules/hiss-invariants.mdc`, `.github/copilot-instructions.md`, `.windsurfrules`, `.gemini/GEMINI.md`, `.codex/rules.md` manually. All agent instruction updates -> `AGENTS.md`, then:

   ```bash
   praetorctl compile-context
   ```

   - `AGENTS.md` = agent-only text -> caveman (internal register). `praetorctl compile-context --verify` + `praetorctl audit` run caveman lint; findings fail gate; no opt-out. Check first: `praetorctl caveman check --kind=context AGENTS.md`.

4. **SARIF diagnostic distillation.** Compiler/linter errors -> distill to $\le 1,500$ tokens ($< 60$ lines): top 3 root-cause failures with file/line pointers; full SARIF logs -> ephemeral storage.

5. **No evasion.** Never attempt `--no-verify`, `LEFTHOOK=0`, or modifying `.git/hooks`. Hooks = local gate adoption installs. Adoption adds no server-side `praetorctl` gate run. Scaffolded CI: `.github/workflows/reuse.yml` runs step `Stop on a draft pull request`, step `reuse lint`.

6. **Anti-loop interception.** Same AST diff + error category repeats $\ge 3$ times -> halt immediately. Re-evaluate design; no micro-textual retries.

<!-- praetor:config -->

## Text Register

<!-- praetor:register:start -->
Register follows the audience, then the task label of your brief (`register:` in `.standards.yaml`; labels are the router's `target_tasks`).

| Register | Where | Form |
| :--- | :--- | :--- |
| social | forge: issues, PR bodies, review comments, commit bodies | `social-text` skill: BLUF, full sentences, scannable, enough and no more; conventional commit subject unchanged; changelog fragment unchanged |
| docs | docs/, README, ADR bodies | complete without bloat: newcomer path first, expert reference after; every claim points at a file, command or test; no restated code |
| internal | briefs, agent-to-agent traffic, research fan-outs, workflow returns | `caveman` skill: fragments, no filler, verbatim code/paths/errors; facts, paths, commands, verdict |

- Task rows: social = commit_message_synthesis, waiver_signoff; docs = architecture_synthesis, function_docstrings; every other label and any unlabeled text = internal. Subagent launch brief: `caveman` brief shape with `task:` = routing label.
- Evidence above 58 lines or 1500 tokens leaves the message as a file under `.workingdir/evidence/`; return `evidence: <path> sha256:<12 hex> lines:<n>` and fetch it only when a decision needs it.
- An internal return carries verdict, changed paths, commands run, evidence pointers and open questions, nothing else.
<!-- praetor:register:end -->

<!-- praetor:tail -->

## Primary Verification Commands

```bash
# Fast local test suite
# Project verification unavailable: Select and exercise the project's configured native test/build commands for meson.build; a governance profile cannot select them. A required build or test command is absent; define and exercise the project's verify-all contract.
exit 1

# Recompile and verify cross-agent context outputs
praetorctl compile-context --verify

# Audit repository against declared HISS standards
praetorctl audit

# Repository gate; steps live in Makefile
make verify-all
```

<!-- markdownlint-enable MD013 -->
<!-- markdownlint-disable MD025 -->
<!-- praetor:harness:end -->

---

<!-- markdownlint-disable MD013 -->
# AGENTS.md — PROJECT

Cross-tool agent guide (Claude Code, Codex, Cursor, …). Tool-specific extras in
[CLAUDE.md](CLAUDE.md).

## Layout

```text
template-native-gpu/
├── meson.build  meson_options.txt      # minimal-seed build (libproject)
├── libproject/                         # shared native core
│   ├── include/project/                # public headers (append-only interop ABI)
│   ├── src/                            # interop.c + hello.c + version.c
│   ├── shaders/                        # Vulkan reference shader (glslang -> .spv)
│   └── test/                           # interop ABI conformance fixture
├── ffmpeg-patches/                     # vf_project_* Vulkan filter patch stack
│   ├── files/                          # canonical filter sources (source of truth)
│   ├── generate.sh  series.txt         # regenerate stack
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
pre-commit run --all-files        # format + lint + gitleaks (local gate)
```

## Principles (`docs/principles.md`)

- **Power-of-10 (C-adapted)**: bounded control flow + loops, small functions,
  checked errors (`proj_result` enum; zero bare `-1` across API boundary),
  zero clang-tidy/semgrep/gitleaks findings on merge.
- **SEI CERT C/C++**: bounded string ops, deterministic RNG, double accumulators
  in reductions for CPU<->GPU bit-exactness.
- **C4 + ADRs**: decisions in `docs/adr/` (Nygard); Accepted bodies immutable.
- **Wire/supply-chain**: RFC 9457 error bodies (when adding HTTP surface),
  OpenAPI 3.1, build provenance (SLSA Build L2) + cosign + SBOM on release.

## Load-Bearing Patterns (do not break)

1. **Append-only interop ABI**: `libproject/include/project/interop.h` rules
   R1–R6. New fields at tail; bump `PROJ_ABI_MINOR`; update size locks + test.
2. **`-fsycl` link propagation + `-ENOSYS` stubs**: see
   `examples/full-gpu-matrix/README.md`.

## Conventions

Conventional Commits, SemVer, Keep-a-Changelog (`changelog.d/`), Trunk-Based
Dev (short-lived branches off `main`). Format: clang-format (config at root).
One-liner WHY comments only.

<!-- Folded from CLAUDE.md -->

<!-- markdownlint-disable MD013 -->
# Claude Code guide — PROJECT

Claude Code-specific extensions.

## Architecture Shapes

Reusable boilerplate: native (C/C++) + GPU + FFmpeg-filter projects:

- **Minimal seed** (repo root): `libproject` (append-only interop ABI + hello
  stub) + Vulkan reference shader + FFmpeg patch stack.
- **Full GPU matrix** (`examples/full-gpu-matrix/`): CUDA / HIP / Metal / SYCL /
  Vulkan dispatch scaffolding behind host layer.

## Extended Build & Test

```bash
meson setup build && meson compile -C build      # libproject + interop test + shader
meson test -C build --suite=fast                 # pre-push gate
ninja -C build install                           # install so FFmpeg patch sees libproject

meson setup build-gpu examples/full-gpu-matrix/core && meson test -C build-gpu
```

## Skills Available (`.claude/skills/`)

| Skill | When |
| :--- | :--- |
| `add-gpu-backend` | add CUDA/HIP/Metal/SYCL backend to matrix example |
| `new-adr` | record architecture decision |
| `render-changelog` | preview changelog.d/ fragments |
| `cut-release` | drive release-please release |

## Reviewer Agents (`.claude/agents/`)

`c-reviewer`, `cuda-reviewer`, `sycl-reviewer`, `hip-reviewer`, `metal-reviewer`,
`meson-reviewer`, `pr-body-checker`. Invoke relevant reviewer before merging
change in area.

## Hooks Active (`.claude/hooks/`)

- PreToolUse `block-unsafe-bash.sh`: blocks destructive commands + `--no-verify`.
- PostToolUse `auto-format-on-edit.sh`: clang-formats C/C++ edits (skips
  `ffmpeg-patches/files/`).
- PostToolUse `docs-drift-warn.sh`: warns when interop/backend/build change
  needs companion ABI bump / stub / changelog.
- SessionStart / Stop: orientation + pre-push reminders.

## Invariant Rules & Prohibitions

- Zero interop ABI breakage. Append-only (`libproject/AGENTS.md` R1–R6).
- GPU backend `common.c` and `stubs.c` must not drift; disabled build links
  stub.
- Zero removal of `-fsycl` link-arg propagation in SYCL meson dependency.
- Zero `printf` debug in library code.
- Zero features beyond task. Zero multi-paragraph comments.
- Zero linter suppression without justification comment.
- Zero new markdown docs unless requested.

## Module Changes

- Add `changelog.d/<section>/` fragment for user-facing changes.
- Update relevant nested `AGENTS.md` + README landed list.
- ABI change -> bump `PROJ_ABI_MINOR`, update `_Static_assert` locks +
  conformance test, write ADR.
