# PROJECT — native (C/C++) + GPU + FFmpeg-filter project template.
# Meson + Ninja. Minimal seed: one C library (libproject) + a Vulkan reference
# shader + an optional FFmpeg patch-stack. The full multi-backend GPU dispatch
# matrix (CUDA / SYCL / HIP / Metal / Vulkan) lives under examples/full-gpu-matrix/.
#
# TEMPLATE PLACEHOLDERS (see README.md § "Placeholder scheme"):
#   project / PROJECT  — library + product name (lowercase / uppercase forms)
#   libproject         — the shared core library directory + soname
#   proj_ / PROJ_      — C symbol + macro prefix
#   myproject          — the org/repo/binary name used in docs + deploy
# Adapted from: Pelorus/meson.build (minimal seed shape).
project(
  'project',
  'c',
  version: '0.1.0',
  license: 'EUPL-1.2',
  default_options: [
    'c_std=c11',
    'warning_level=3',
    'werror=true',
    'default_library=shared',
  ],
  meson_version: '>=0.60.0',
)

cc = meson.get_compiler('c')

# Power-of-10 / CERT-leaning baseline: keep the warning surface wide. Project
# code is warning-clean to -Wall -Wextra; add a few high-signal extras.
add_project_arguments(
  cc.get_supported_arguments([
    '-Wshadow',
    '-Wpointer-arith',
    '-Wstrict-prototypes',
    '-Wmissing-prototypes',
    '-Wvla',
  ]),
  language: 'c',
)

subdir('libproject')
