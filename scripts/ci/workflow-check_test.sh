#!/usr/bin/env bash
# Planted cases for scripts/ci/workflow-check.sh: a clean workflow, a flaky pull and an SBOM step
# that cannot reach a release pass; a tag pin, a stale or missing version comment, a broken
# workflow, a dead pull, a missing token and an SBOM release upload without contents: write fail.
#   usage: scripts/ci/workflow-check_test.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

CHECKOUT=actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1

# plant CASE DIR USES [RUNS_ON_KEY]: one workflow whose only step uses USES.
plant() {
  mkdir -p "$WORK/$1/$2/workflows"
  cat >"$WORK/$1/$2/workflows/planted.yml" <<YAML
name: planted
on:
  pull_request:
permissions:
  contents: read
jobs:
  planted:
    ${4:-runs-on}: ubuntu-26.04
    steps:
      - uses: $3
        with:
          persist-credentials: false
YAML
}

# expect_refusal CASE NEEDLE [COMMAND PREFIX...]: the check must fail and name NEEDLE.
expect_refusal() {
  local name="$1" needle="$2" out
  shift 2
  if out="$("$@" bash "$HERE/workflow-check.sh" "$WORK/$name" 2>&1)"; then
    printf 'FAIL %s: accepted\n%s\n' "$name" "$out" >&2
    exit 1
  fi
  case "$out" in
    *"$needle"*) echo "ok   $name: refused ($needle)" ;;
    *)
      printf 'FAIL %s: refused without "%s"\n%s\n' "$name" "$needle" "$out" >&2
      exit 1
      ;;
  esac
}

plant clean .github "$CHECKOUT # v7.0.1"
bash "$HERE/workflow-check.sh" "$WORK/clean" >/dev/null
echo "ok   clean: accepted"

REAL_DOCKER="$(command -v "${DOCKER_BIN:-docker}")"
mkdir -p "$WORK/pull-state"
cat >"$WORK/docker" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$1" >>"$DOCKER_LOG"
if [ "$1" = pull ]; then
  if [ "$DOCKER_MODE" = dead ]; then
    exit 1
  fi
  state="$DOCKER_STATE/${3//[^[:alnum:]]/_}"
  if [ ! -f "$state" ]; then
    : >"$state"
    exit 1
  fi
fi
exec "$DOCKER_REAL" "$@"
BASH
chmod +x "$WORK/docker"

plant flaky-pull .github "$CHECKOUT # v7.0.1"
DOCKER_BIN="$WORK/docker" DOCKER_REAL="$REAL_DOCKER" DOCKER_MODE=flaky \
  DOCKER_STATE="$WORK/pull-state" DOCKER_LOG="$WORK/flaky.log" WORKFLOW_CHECK_PULL_DELAY=0 \
  bash "$HERE/workflow-check.sh" "$WORK/flaky-pull" >/dev/null
echo "ok   flaky-pull: accepted"

plant dead-pull .github "$CHECKOUT # v7.0.1"
expect_refusal dead-pull "failed after 3 attempts" env \
  DOCKER_BIN="$WORK/docker" DOCKER_REAL="$REAL_DOCKER" DOCKER_MODE=dead \
  DOCKER_STATE="$WORK/pull-state" DOCKER_LOG="$WORK/dead.log" WORKFLOW_CHECK_PULL_DELAY=0
if [ "$(cat "$WORK/dead.log")" != $'pull\npull\npull' ]; then
  echo "FAIL dead-pull: expected exactly 3 pulls and no run" >&2
  cat "$WORK/dead.log" >&2
  exit 1
fi

plant tag-pin .github "actions/checkout@v7"
expect_refusal tag-pin "unpinned-uses"

plant stale-comment .github "$CHECKOUT # v4.0.0"
expect_refusal stale-comment "ref-version-mismatch"

plant no-comment .github "$CHECKOUT"
expect_refusal no-comment "ref-version-mismatch"

plant broken .github "$CHECKOUT # v7.0.1" runs-in
expect_refusal broken "syntax-check"

SBOM=anchore/sbom-action@e22c389904149dbc22b58101806040fa8d37a610
RELEASE=$'  release:\n    types: [published]'
# plant_sbom CASE TRIGGER [WITH]: a read-only SBOM job and a contents: write one under the
# on: block TRIGGER; WITH is one more input line for the read-only step.
plant_sbom() {
  mkdir -p "$WORK/$1/.github/workflows"
  cat >"$WORK/$1/.github/workflows/planted.yml" <<YAML
name: planted
on:
$2
permissions:
  contents: read
jobs:
  read-only:
    runs-on: ubuntu-26.04
    steps:
      - uses: $SBOM # v0.24.0
        with:
          path: .
${3:-}
  release-write:
    runs-on: ubuntu-26.04
    permissions:
      contents: write
    steps:
      - uses: $SBOM # v0.24.0
        with:
          path: .
YAML
}

plant_sbom sbom-scoped "$RELEASE" "          upload-release-assets: false"
bash "$HERE/workflow-check.sh" "$WORK/sbom-scoped" >/dev/null
echo "ok   sbom-scoped: accepted"

plant_sbom sbom-pull-request "  pull_request:"
bash "$HERE/workflow-check.sh" "$WORK/sbom-pull-request" >/dev/null
echo "ok   sbom-pull-request: accepted"

plant_sbom sbom-branch-push $'  push:\n    branches: [main]'
bash "$HERE/workflow-check.sh" "$WORK/sbom-branch-push" >/dev/null
echo "ok   sbom-branch-push: accepted"

plant_sbom sbom-read-upload "$RELEASE"
expect_refusal sbom-read-upload "job read-only: sbom-release-upload"

plant_sbom sbom-tag-push $'  push:\n    tags: ["v*"]'
expect_refusal sbom-tag-push "job read-only: sbom-release-upload"

expect_refusal clean "is required" env -u GH_TOKEN -u GITHUB_TOKEN

mkdir -p "$WORK/empty"
expect_refusal empty "no workflow file"

echo "workflow check: 5 accepted, 9 refused"
