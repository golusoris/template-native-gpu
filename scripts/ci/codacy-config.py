#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 The PROJECT Authors
# SPDX-License-Identifier: EUPL-1.2
"""Check that Codacy's markdownlint skips exactly what the markdownlint-cli2 hook skips.

Codacy lints Markdown with its own markdownlint, configured in .codacy.yml. A path the
hook excludes but Codacy does not (a changelog.d fragment) fails every pull request that
touches it. The check compares both exclusion sets on every Markdown file in the tree
plus probe paths, so a new hook exclusion without a Codacy glob, or the reverse, fails
here. Untracked files only add probes: the verdict depends on the path, not the content.

The hook side applies pre-commit's top-level and hook files/exclude regexes with
pre-commit's defaults; the Codacy side applies the global and engine exclude_paths.
The codacy-markdownlint-parity hook must survive pre-commit's top-level files/exclude
and its own, select every judged path and both configuration files, and run at the
pre-commit stage, so a commit that can move either side runs this check.
A key whose effect on path selection this check does not model is refused, not ignored,
and so is a value of the wrong type; only an absent value reads as empty.

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
PARITY_ID = "codacy-markdownlint-parity"
PRECOMMIT = ".pre-commit-config.yaml"
CONFIG_PATHS = (".codacy.yml", PRECOMMIT)
ENGINE = "markdownlint"
PROBES = ("changelog.d/fixed/x.md", "docs/adr/_index_fragments/0001-x.md", "subprojects/x/README.md", "docs/x.MD")
PARITY_UNMODELLED = frozenset({"types", "types_or", "exclude_types", "always_run"})
GLOB_ALLOWED = re.compile(r"[A-Za-z0-9_./*-]+")
MARKDOWN_SUFFIXES = (".md", ".markdown")  # matched lowercased: identify tags README.MD as markdown
CODACY_KEYS = frozenset({"engines", "exclude_paths"})
CODACY_ENGINE_KEYS = frozenset({"exclude_paths"})
HOOK_KEYS = frozenset({"id", "pass_filenames", "files", "exclude"})
COMMIT_STAGE = "pre-commit"
LEGACY_STAGES = {"commit": "pre-commit", "merge-commit": "pre-merge-commit", "push": "pre-push"}

Filter = tuple[re.Pattern[str], re.Pattern[str]]


class ConfigError(Exception):
    """A configuration file this check cannot read."""


def mapping(value: object, where: str) -> dict:
    """Only an absent value (None) reads as empty; any other non-mapping is refused."""
    if value is None:
        return {}
    if not isinstance(value, dict):
        raise ConfigError(f"{where} must be a mapping")
    return value


def mapping_list(value: object, where: str) -> list[dict]:
    if value is None:
        return []
    if not isinstance(value, list) or not all(isinstance(item, dict) for item in value):
        raise ConfigError(f"{where} must be a list of mappings")
    return value


def known_keys(value: object, allowed: frozenset[str], where: str) -> dict:
    config = mapping(value, where)
    unknown = sorted(str(key) for key in set(config) - allowed)
    if unknown:
        raise ConfigError(f"{where}: unsupported key {', '.join(unknown)}; teach this check its effect first")
    return config


def string_list(value: object, where: str) -> list[str]:
    if value is None:
        return []
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        raise ConfigError(f"{where} must be a list of strings")
    return value


def glob_regex(glob: str) -> re.Pattern[str]:
    """Java glob as Codacy reads it: ** crosses directories, * stays inside one."""
    if not GLOB_ALLOWED.fullmatch(glob):
        raise ConfigError(f".codacy.yml: unsupported glob {glob!r}: allowed are letters, digits, _ . / - and *")
    parts = [".*" if piece == "**" else "[^/]*" if piece == "*" else re.escape(piece)
             for piece in re.split(r"(\*\*|\*)", glob) if piece]
    return re.compile("".join(parts))


def codacy_globs(root: Path) -> list[str]:
    """Global exclude_paths skip a path for every engine, the engine's own for markdownlint."""
    text = (root / ".codacy.yml").read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise ConfigError(".codacy.yml must start with a '---' line")
    config = known_keys(yaml.safe_load(text), CODACY_KEYS, ".codacy.yml")
    engines = mapping(config.get("engines"), ".codacy.yml: engines")
    where = f".codacy.yml: engines.{ENGINE}"
    engine = known_keys(engines.get(ENGINE), CODACY_ENGINE_KEYS, where)
    return (string_list(config.get("exclude_paths"), ".codacy.yml: exclude_paths")
            + string_list(engine.get("exclude_paths"), f"{where}.exclude_paths"))


def regex(config: dict, key: str, default: str, where: str) -> re.Pattern[str]:
    value = config.get(key, default)
    if not isinstance(value, str):
        raise ConfigError(f"{where}: {key} must be a string")
    return re.compile(value)


def include_exclude(config: dict, where: str) -> Filter:
    """pre-commit's defaults: files '' keeps every path, exclude '^$' drops none."""
    return regex(config, "files", "", where), regex(config, "exclude", "^$", where)


def one_hook(config: dict, hook_id: str) -> dict:
    hooks = [hook for repo in mapping_list(config.get("repos"), f"{PRECOMMIT}: repos")
             for hook in mapping_list(repo.get("hooks"), f"{PRECOMMIT}: hooks") if hook.get("id") == hook_id]
    if len(hooks) != 1:
        raise ConfigError(f"{PRECOMMIT}: expected one {hook_id} hook, found {len(hooks)}")
    return hooks[0]


def hook_filters(config: dict) -> list[Filter]:
    """The top-level filter, then the hook's, as pre-commit applies them."""
    hook = known_keys(one_hook(config, HOOK_ID), HOOK_KEYS, f"{PRECOMMIT}: {HOOK_ID} hook")
    if hook.get("pass_filenames", True) is not True:
        raise ConfigError(f"{PRECOMMIT}: {HOOK_ID} hook must pass filenames; its own globs are not modelled")
    return [include_exclude(config, PRECOMMIT), include_exclude(hook, f"{PRECOMMIT}: {HOOK_ID} hook")]


def runs_on_commit(config: dict, hook: dict, where: str) -> bool:
    """pre-commit's stage choice: hook stages, else default_stages, else every stage."""
    stages = string_list(hook.get("stages"), f"{where}: stages")
    if not stages and "default_stages" in config:
        stages = string_list(config["default_stages"], f"{PRECOMMIT}: default_stages")
    elif not stages:
        return True
    return COMMIT_STAGE in {LEGACY_STAGES.get(stage, stage) for stage in stages}


def selected(filters: list[Filter], path: str) -> bool:
    return all(files.search(path) and not exclude.search(path) for files, exclude in filters)


def parity_misses(config: dict, paths: list[str]) -> list[str]:
    """Paths the parity hook misses after the top-level and its own filter, or no commit stage."""
    where = f"{PRECOMMIT}: {PARITY_ID} hook"
    hook = one_hook(config, PARITY_ID)
    unknown = sorted(PARITY_UNMODELLED & set(hook))
    if unknown:
        raise ConfigError(f"{where}: unsupported key {', '.join(unknown)}; teach this check its effect first")
    filters = [include_exclude(config, PRECOMMIT), include_exclude(hook, where)]
    misses = [f"{path}: the {PARITY_ID} hook does not run when it changes"
              for path in [*CONFIG_PATHS, *paths] if not selected(filters, path)]
    return misses + stage_misses(config, hook, PARITY_ID)


def stage_misses(config: dict, hook: dict, hook_id: str) -> list[str]:
    where = f"{PRECOMMIT}: {hook_id} hook"
    return [] if runs_on_commit(config, hook, where) else [f"{hook_id} hook does not run at the {COMMIT_STAGE} stage"]


def tree_markdown(root: Path) -> list[str]:
    paths = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [name for name in dirnames if name != ".git"]
        rel_dir = Path(dirpath).relative_to(root)
        paths.extend((rel_dir / name).as_posix() for name in filenames if name.lower().endswith(MARKDOWN_SUFFIXES))
    return paths


def drift(root: Path) -> list[str]:
    config = mapping(yaml.safe_load((root / PRECOMMIT).read_text(encoding="utf-8")), PRECOMMIT)
    filters = hook_filters(config)
    globs = [glob_regex(glob) for glob in codacy_globs(root)]
    paths = sorted(set(tree_markdown(root)) | set(PROBES))
    findings = parity_misses(config, paths) + stage_misses(config, one_hook(config, HOOK_ID), HOOK_ID)
    for path in paths:
        hook_skips = not selected(filters, path)
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
        print("codacy-config: keep the exclude_paths in .codacy.yml on the files/exclude filters "
              f"of the {HOOK_ID} hook in {PRECOMMIT}, and the {PARITY_ID} hook filter on every "
              "Markdown path and both configuration files", file=sys.stderr)
        return 1
    print("codacy-config: Codacy markdownlint and the pre-commit hook skip the same paths")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
