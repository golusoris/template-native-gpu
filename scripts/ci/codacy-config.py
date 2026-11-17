#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 The PROJECT Authors
# SPDX-License-Identifier: EUPL-1.2
"""Check that Codacy's markdownlint skips exactly what the markdownlint-cli2 hook skips.

Codacy lints Markdown with its own markdownlint, configured in .codacy.yml. A path the
hook excludes but Codacy does not (a changelog.d fragment) fails every pull request that
touches it. The check compares both exclusion sets on every Markdown file in the tree
plus probe paths, so a new hook exclusion without a Codacy glob, or the reverse, fails
here. Untracked files only add probes: the verdict depends on the path, not the content.

Usage:
    codacy-config.py [ROOT]   # default: this repository
Exit 0 = same sets, 1 = drift, 2 = a configuration this check cannot read.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

import yaml

HOOK_ID = "markdownlint-cli2"
ENGINE = "markdownlint"
PROBES = ("changelog.d/fixed/x.md", "docs/adr/_index_fragments/0001-x.md", "subprojects/x/README.md")
GLOB_ALLOWED = re.compile(r"[A-Za-z0-9_./*-]+")
MARKDOWN_SUFFIXES = (".md", ".markdown")


class ConfigError(Exception):
    """A configuration file this check cannot read."""


def glob_regex(glob: str) -> re.Pattern[str]:
    """Java glob as Codacy reads it: ** crosses directories, * stays inside one."""
    if not GLOB_ALLOWED.fullmatch(glob):
        raise ConfigError(f".codacy.yml: unsupported glob {glob!r}: allowed are letters, digits, _ . / - and *")
    parts = [".*" if piece == "**" else "[^/]*" if piece == "*" else re.escape(piece)
             for piece in re.split(r"(\*\*|\*)", glob) if piece]
    return re.compile("".join(parts))


def codacy_globs(root: Path) -> list[str]:
    text = (root / ".codacy.yml").read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise ConfigError(".codacy.yml must start with a '---' line")
    config = yaml.safe_load(text) or {}
    engine = ((config.get("engines") or {}).get(ENGINE)) or {}
    globs = engine.get("exclude_paths") or []
    if not isinstance(globs, list) or not all(isinstance(g, str) for g in globs):
        raise ConfigError(f".codacy.yml: engines.{ENGINE}.exclude_paths must be a list of strings")
    return globs


def hook_exclude(root: Path) -> re.Pattern[str] | None:
    config = yaml.safe_load((root / ".pre-commit-config.yaml").read_text(encoding="utf-8")) or {}
    hooks = [hook for repo in config.get("repos") or [] for hook in repo.get("hooks") or []
             if hook.get("id") == HOOK_ID]
    if len(hooks) != 1:
        raise ConfigError(f".pre-commit-config.yaml: expected one {HOOK_ID} hook, found {len(hooks)}")
    exclude = hooks[0].get("exclude")
    return re.compile(exclude) if exclude else None


def tree_markdown(root: Path) -> list[str]:
    paths = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [name for name in dirnames if name != ".git"]
        rel_dir = Path(dirpath).relative_to(root)
        paths.extend((rel_dir / name).as_posix() for name in filenames if name.endswith(MARKDOWN_SUFFIXES))
    return paths


def drift(root: Path) -> list[str]:
    hook = hook_exclude(root)
    globs = [glob_regex(glob) for glob in codacy_globs(root)]
    findings = []
    for path in sorted(set(tree_markdown(root)) | set(PROBES)):
        hook_skips = bool(hook and hook.search(path))
        codacy_skips = any(glob.fullmatch(path) for glob in globs)
        if hook_skips and not codacy_skips:
            findings.append(f"{path}: pre-commit markdownlint skips it, Codacy lints it")
        elif codacy_skips and not hook_skips:
            findings.append(f"{path}: Codacy skips it, pre-commit markdownlint lints it")
    return findings


def main(argv: list[str]) -> int:
    if len(argv) > 2:
        print("usage: codacy-config.py [ROOT]", file=sys.stderr)
        return 2
    root = Path(argv[1] if len(argv) == 2 else Path(__file__).resolve().parents[2])
    try:
        findings = drift(root)
    except (ConfigError, OSError, yaml.YAMLError, re.error) as err:
        print(f"codacy-config: {err}", file=sys.stderr)
        return 2
    for finding in findings:
        print(f"codacy-config: {finding}", file=sys.stderr)
    if findings:
        print("codacy-config: keep engines.markdownlint.exclude_paths in .codacy.yml on the "
              f"{HOOK_ID} hook exclude in .pre-commit-config.yaml", file=sys.stderr)
        return 1
    print("codacy-config: Codacy markdownlint and the pre-commit hook skip the same paths")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
