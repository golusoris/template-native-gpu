#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 The PROJECT Authors
# SPDX-License-Identifier: EUPL-1.2
"""Emit a Clang host-parse database for a CUDA or HIP kernel."""

# WHY: Meson uses nvcc for CUDA and has no HIP language; clang-tidy needs host-parse commands.
# https://clang.llvm.org/docs/JSONCompilationDatabase.html

import argparse
import json
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("lane", choices=("cuda", "hip"))
    parser.add_argument("build_dir", type=Path)
    parser.add_argument("--toolkit", required=True, type=Path)
    parser.add_argument("--compiler", default="clang++")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[3]
    build = args.build_dir.resolve()
    build.mkdir(parents=True, exist_ok=True)
    database = build / "compile_commands.json"
    toolkit = args.toolkit.resolve()
    flags = (
        ["--cuda-host-only", f"--cuda-path={toolkit}"]
        if args.lane == "cuda"
        else ["--offload-host-only", f"--rocm-path={toolkit}"]
    )
    suffix = "cu" if args.lane == "cuda" else "hip"
    source = (
        root / f"examples/full-gpu-matrix/core/src/{args.lane}/scale_kernel.{suffix}"
    )
    command = [
        args.compiler,
        "-x",
        args.lane,
        *flags,
        "-std=c++20",
        "-c",
        str(source),
    ]
    entry = {"directory": str(root), "file": str(source), "arguments": command}
    database.write_text(json.dumps([entry], indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
