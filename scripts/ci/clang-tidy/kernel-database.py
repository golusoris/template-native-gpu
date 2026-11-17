#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 The PROJECT Authors
# SPDX-License-Identifier: EUPL-1.2
"""Emit a Clang host-parse database for a CUDA or HIP kernel."""

# WHY: Meson uses nvcc for CUDA and has no HIP language; Clang -MJ emits its own argv.

import argparse
import json
import subprocess
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
    database.unlink(missing_ok=True)
    fragment = build / "kernel-command.json"
    fragment.unlink(missing_ok=True)
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
        "-fsyntax-only",
        "-MJ",
        str(fragment),
        str(source),
    ]
    subprocess.run(command, cwd=root, check=True, timeout=120)
    entry = json.loads(fragment.read_text(encoding="utf-8").strip().removesuffix(","))
    database.write_text(json.dumps([entry], indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
