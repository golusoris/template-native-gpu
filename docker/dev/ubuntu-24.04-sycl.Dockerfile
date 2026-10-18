# Ubuntu 24.04 + Intel oneAPI dev image — for building/testing the SYCL backend
# of the full-gpu-matrix example. Ships icpx (-fsycl). The host C/C++ compiler
# stays gcc/clang; only the SYCL TUs go through icpx (see core/meson.build).
#
# TEMPLATE: pin the oneAPI tag your project targets.
FROM intel/oneapi-basekit:2025.1.0-0-devel-ubuntu24.04@sha256:f1aa2341564b065d5eeb3b6706759f04b7f250084501ff4dc4c0bb0c77c3b746

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential clang clang-format \
        meson ninja-build pkg-config glslang-tools \
        git ca-certificates python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Non-root by default (rootless-friendly).
ARG USER=dev
RUN useradd -ms /bin/bash "$USER"
USER ${USER}
WORKDIR /workspace

# The oneAPI image sources its env via /opt/intel/oneapi/setvars.sh; do that in
# your shell before building:
#   . /opt/intel/oneapi/setvars.sh
#   meson setup build examples/full-gpu-matrix/core -Denable_sycl=true -Dsycl_compiler=icpx
#   meson compile -C build
# Interactive dev shell, no service to probe.
HEALTHCHECK NONE
CMD ["bash"]
