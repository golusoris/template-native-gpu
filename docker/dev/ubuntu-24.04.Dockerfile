# Ubuntu 24.04 dev image for PROJECT — CPU/host toolchain + the format/lint/scan
# tools. GPU SDKs are NOT installed here (every backend resolves to its -ENOSYS
# stub); see ubuntu-24.04-cuda.Dockerfile / ubuntu-24.04-sycl.Dockerfile for the
# GPU lanes.
#
# Multi-arch (linux/amd64,linux/arm64) via buildx in docker-publish.yml.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential clang clang-format clang-tidy cppcheck \
        meson ninja-build pkg-config \
        glslang-tools \
        git ca-certificates curl \
        python3 python3-pip python3-venv \
        shellcheck codespell \
    && rm -rf /var/lib/apt/lists/*

# Non-root by default (rootless-friendly).
ARG USER=dev
RUN useradd -ms /bin/bash "$USER"
USER ${USER}
WORKDIR /workspace

# pip --user installs land here.
ENV PATH="/home/${USER}/.local/bin:${PATH}"
RUN python3 -m pip install --user --break-system-packages pre-commit semgrep

CMD ["bash"]
