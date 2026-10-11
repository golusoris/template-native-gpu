# Ubuntu 24.04 + CUDA dev image — for building/testing the CUDA backend of the
# full-gpu-matrix example. Based on NVIDIA's CUDA devel image (ships nvcc +
# bin2c). No GPU is required to BUILD (-Denable_cuda=true compiles the kernels);
# running the kernels needs an NVIDIA GPU + driver at runtime.
#
# TEMPLATE: pin the CUDA tag your project targets.
FROM nvidia/cuda:12.6.2-devel-ubuntu24.04@sha256:738fba0fbdb225b7a2931c58a5c8f03a84d3cd2f6a84975826a157339ef750b8

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential clang clang-format clang-tidy \
        meson ninja-build pkg-config glslang-tools \
        git ca-certificates python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Build the matrix example with CUDA enabled:
#   meson setup build examples/full-gpu-matrix/core -Denable_cuda=true -Denable_nvcc=true
#   meson compile -C build
CMD ["bash"]
