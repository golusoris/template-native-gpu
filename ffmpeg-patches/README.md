<!-- markdownlint-disable MD013 -->
# PROJECT FFmpeg patch stack

Native `vf_project_*` Vulkan compute filters, shipped as a stack of patches
against **FFmpeg n8.1.1**. The filters link **libproject** (the shared interop
ABI + filter contracts) so a single filtergraph can carry the PROJECT side-data
blob straight through to a hardware encoder, and a downstream consumer can read
it. See [docs/adr/0003-ffmpeg-patch-stack.md](../docs/adr/0003-ffmpeg-patch-stack.md).

> TEMPLATE: this seed ships one illustrative filter (`vf_project_vulkan`, a
> trivial scale+bias compute pass). Replace it with your real filter(s) and grow
> `series.txt` / `generate.sh`.

## Layout

| Path | Role |
| --- | --- |
| `files/` | Canonical filter sources — the source of truth a maintainer edits. |
| `0001-*.patch` … | Generated artifacts (`git format-patch`), the applied form. |
| `series.txt` | Ordered apply list (cumulative stack). |
| `generate.sh` | Regenerate the patches from `files/` against a base tag. |
| `test/build-and-run.sh` | Apply + configure + build + smoke-test gate. |

## Prerequisites

- A Vulkan SDK / loader + headers and a SPIR-V compiler (libshaderc or
  libglslang) — FFmpeg's `spirv_library`.
- **libproject installed and visible to pkg-config**
  (`pkg-config --exists libproject`). Build it from the repo root:
  `meson setup build && ninja -C build && ninja -C build install`.

## Apply

```bash
cd /path/to/ffmpeg            # a pristine n8.1.1 checkout
git reset --hard n8.1.1
for p in /path/to/template-native-gpu/ffmpeg-patches/0*.patch; do
    git am --3way "$p" || break
done
```

`git am --3way` (not per-patch `git apply --check`) is the correct gate: the
stack is cumulative and later patches' context can depend on earlier ones.

## Configure + build

```bash
./configure --enable-vulkan --enable-libshaderc          # filter auto-enables
make -j libavfilter/vf_project_vulkan.o                  # single-TU check
make -j                                                  # full build
```

The filter is gated `project_vulkan_filter_deps="vulkan spirv_library"`, and a
soft `require_pkg_config libproject ...` probe wires its cflags/libs. Install
libproject where pkg-config can see it (`--prefix=/usr`, or set
`PKG_CONFIG_PATH`) before configuring FFmpeg.

## Regenerate

```bash
FFMPEG_REPO=/path/to/ffmpeg BASE_TAG=n8.1.1 ./generate.sh
```

Edit the sources under `files/`, rerun `generate.sh`, and commit both the
sources and the regenerated `*.patch` in the same change.

## License

The sources under `files/` and the generated `*.patch` files are
LGPL-2.1-or-later: they become part of FFmpeg when applied, so new
`libavfilter/*.c` files carry FFmpeg's LGPL-2.1 header and FFmpeg's copyright
applies next to the authors'. `generate.sh`, `series.txt` and `test/` are
tooling under the project's EUPL-1.2. `REUSE.toml` at the repository root
records both.
