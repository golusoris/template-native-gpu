<!-- markdownlint-disable MD013 -->
# Build & test

## Prerequisites

- meson `>= 0.60` + ninja
- a C11 compiler (gcc / clang) — C++20 for the GPU-matrix example
- `glslangValidator` (optional; for the Vulkan reference shader)
- pkg-config

GPU backends are optional and OFF by default; install a toolchain only for the
backend you want to build (CUDA toolkit / ROCm + hipcc / Intel oneAPI icpx /
Xcode for Metal).

## Minimal seed (repo root)

```bash
meson setup build
meson compile -C build
meson test -C build --print-errorlogs
ninja -C build install            # installs libproject so the FFmpeg patch sees it
```

## Full GPU-matrix example

Configures + compiles with no GPU SDK (every backend resolves to its -ENOSYS
stub):

```bash
meson setup build-gpu examples/full-gpu-matrix/core
meson compile -C build-gpu
meson test -C build-gpu
```

Enable a backend with its toolchain present:

```bash
meson setup build-gpu examples/full-gpu-matrix/core -Denable_cuda=true -Denable_nvcc=true
meson setup build-gpu examples/full-gpu-matrix/core -Denable_hip=true -Denable_hipcc=true
meson setup build-gpu examples/full-gpu-matrix/core -Denable_sycl=true -Dsycl_compiler=icpx
# Metal auto-enables on a darwin host.
```

## The local gate (run before pushing)

```bash
pre-commit run --all-files     # clang-format, shellcheck, codespell, gitleaks, markdownlint
meson test -C build            # fast suite
```

## FFmpeg patch stack

```bash
cd ffmpeg-patches
FFMPEG_REPO=/path/to/ffmpeg ./generate.sh        # regenerate from files/
./test/build-and-run.sh                          # apply + build + smoke
```

## Sanitizers

```bash
meson setup build-asan -Db_sanitize=address,undefined -Db_lundef=false && meson test -C build-asan
meson setup build-tsan examples/full-gpu-matrix/core -Db_sanitize=thread -Db_lundef=false && meson test -C build-tsan
```
