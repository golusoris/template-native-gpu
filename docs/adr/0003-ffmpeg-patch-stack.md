<!-- markdownlint-disable MD013 MD041 -->
# ADR-0003: FFmpeg patch-stack delivery model

- **Status**: Accepted
- **Date**: 2026-01-01
- **Deciders**: maintainers
- **Tags**: build, ffmpeg

## Context

The native compute filters must ship as FFmpeg `vf_*` filters, but maintaining a
full FFmpeg fork is heavy and drifts from upstream. We need a delivery model that
tracks a pinned FFmpeg release and is easy to rebase.

## Decision

We ship the filters as a **cumulative stack of `git format-patch` patches**
against a pinned FFmpeg tag (n8.1.1). `ffmpeg-patches/files/` holds the canonical
filter sources (the source of truth); `generate.sh` replays them onto a pristine
checkout to regenerate the `*.patch` artifacts. Each filter links `libproject`
via `require_pkg_config` (never a `*_filter_deps` entry, which would silently
disable it).

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| Full FFmpeg fork | Simple to build | Heavy maintenance, drifts | Unsustainable |
| Out-of-tree filter plugin | No FFmpeg edit | FFmpeg's plugin ABI is unstable / limited for Vulkan | Vulkan filters need in-tree wiring |
| Patch stack from files/ | Rebasable, upstream-trackable | Regeneration discipline | — (chosen) |

## Consequences

- Positive: a clean `git am --3way` onto the pinned tag; easy upstream bumps.
- Negative: patches are generated artifacts — edit `files/`, never the `.patch`.
- Follow-ups: `test/build-and-run.sh` is the CI gate (apply + build + smoke).

## References

- `ffmpeg-patches/README.md`, `ffmpeg-patches/generate.sh`.
