#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 The PROJECT Authors
# SPDX-License-Identifier: EUPL-1.2
"""Run clang-tidy with warnings as errors over every in-tree unit of a compile database.

Units outside the repository (meson subprojects, generated sources under the
build tree) are skipped. The check fails when a database is missing, lists no
in-tree unit, or clang-tidy reports any finding.

Usage:
    run.py BUILD_DIR [BUILD_DIR ...]
"""

import json
import os
import subprocess
import sys


def in_tree_units(build_dir: str, root: str) -> list[str]:
    with open(os.path.join(build_dir, "compile_commands.json"), encoding="utf-8") as db_file:
        entries = json.load(db_file)
    units = []
    for entry in entries:
        path = os.path.normpath(os.path.join(entry["directory"], entry["file"]))
        rel = os.path.relpath(path, root)
        if rel.startswith("..") or rel.startswith(build_dir.rstrip("/") + os.sep):
            continue
        if rel not in units:
            units.append(rel)
    return units


def main(argv: list[str]) -> int:
    if not argv:
        print("usage: run.py BUILD_DIR [BUILD_DIR ...]", file=sys.stderr)
        return 2
    root = os.getcwd()
    for build_dir in argv:
        units = in_tree_units(build_dir, root)
        if not units:
            print(f"clang-tidy: {build_dir}: no in-tree unit in the compile database", file=sys.stderr)
            return 1
        cmd = ["clang-tidy", "-p", build_dir, "--warnings-as-errors=*", *units]
        if subprocess.run(cmd, check=False).returncode != 0:  # noqa: S603 - fixed argv, no shell
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
