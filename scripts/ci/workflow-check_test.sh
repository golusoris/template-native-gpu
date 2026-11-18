#!/usr/bin/env bash
# Planted cases for scripts/ci/workflow-check.sh (15 accepted, 38 refused): a clean workflow, a
# flaky pull, a called workflow with contents: write and SBOM steps that cannot reach a release
# (disabled on root or publish-sbom in with, with false overriding env true, upper-case key, padded
# false, pull_request, branch-only or aliased branch push with release-ref-prefix: refs/tags/ pinned
# in with, and with prefix pin overriding step env or a GITHUB_ENV rewrite) pass; a tag pin, a stale
# or missing version comment, a broken workflow, a dead pull, a missing token, an old yq, an empty
# workflow directory and SBOM release uploads without contents: write (release, upper-case uses, tag
# push, aliased tag push, publish-sbom without with disable, padded true, blank, non-false literal,
# expression, disagreeing keys, env-only disable on root or publish-sbom, unpinned branch-only push,
# blank or non-tag release-ref-prefix in with including upper-case key or with bad over env, env-only
# release-ref-prefix across step, job, workflow, shadowed, lower-case on ubuntu, Windows or matrix
# runs-on, or GITHUB_ENV rewrite, an env that is no map, read-only workflow_call) fail.
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
SBOM_PUBLISH=anchore/sbom-action/publish-sbom@e22c389904149dbc22b58101806040fa8d37a610
SBOM_DOWNLOAD=anchore/sbom-action/download-syft@e22c389904149dbc22b58101806040fa8d37a610
RELEASE=$'  release:\n    types: [published]'
# plant_sbom CASE TRIGGER [WITH] [USES] [JOB] [RUNS_ON] [WF_ENV] [PRE_STEP]: a read-only SBOM job
# and a contents: write one under the on: block TRIGGER; WITH is extra step YAML, JOB is extra job
# YAML, WF_ENV is top-level workflow YAML and PRE_STEP is an extra step before the SBOM step.
plant_sbom() {
  mkdir -p "$WORK/$1/.github/workflows"
  cat >"$WORK/$1/.github/workflows/planted.yml" <<YAML
name: planted
on:
$2
permissions:
  contents: read
${7:-}
jobs:
  read-only:
    runs-on: ${6:-ubuntu-26.04}
${5:-}
    steps:
      - uses: $SBOM_DOWNLOAD # v0.24.0
${8:-}
      - uses: ${4:-$SBOM} # v0.24.0
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

# plant_called CASE [PERMISSIONS]: a workflow_call workflow with no top-level permissions block.
plant_called() {
  mkdir -p "$WORK/$1/.github/workflows"
  cat >"$WORK/$1/.github/workflows/planted.yml" <<YAML
name: planted
on:
  workflow_call:
jobs:
  read-only:
    runs-on: ubuntu-26.04
${2:-}
    steps:
      - uses: $SBOM # v0.24.0
        with:
          path: .
YAML
}

plant_sbom sbom-scoped "$RELEASE" "          upload-release-assets: false"
bash "$HERE/workflow-check.sh" "$WORK/sbom-scoped" >/dev/null
echo "ok   sbom-scoped: accepted"

plant_sbom sbom-false-capital "$RELEASE" "          upload-release-assets: 'False'"
bash "$HERE/workflow-check.sh" "$WORK/sbom-false-capital" >/dev/null
echo "ok   sbom-false-capital: accepted"

plant_sbom sbom-publish-off "$RELEASE" "          upload-release-assets: false" "$SBOM_PUBLISH"
bash "$HERE/workflow-check.sh" "$WORK/sbom-publish-off" >/dev/null
echo "ok   sbom-publish-off: accepted"

plant_sbom sbom-upload-env-true "$RELEASE" $'          upload-release-assets: false\n        env:\n          INPUT_UPLOAD-RELEASE-ASSETS: true'
bash "$HERE/workflow-check.sh" "$WORK/sbom-upload-env-true" >/dev/null
echo "ok   sbom-upload-env-true: accepted"

plant_sbom sbom-key-upper "$RELEASE" "          UPLOAD-RELEASE-ASSETS: false"
bash "$HERE/workflow-check.sh" "$WORK/sbom-key-upper" >/dev/null
echo "ok   sbom-key-upper: accepted"

plant_sbom sbom-false-padded "$RELEASE" "          upload-release-assets: ' False '"
bash "$HERE/workflow-check.sh" "$WORK/sbom-false-padded" >/dev/null
echo "ok   sbom-false-padded: accepted"

plant_sbom sbom-pull-request "  pull_request:"
bash "$HERE/workflow-check.sh" "$WORK/sbom-pull-request" >/dev/null
echo "ok   sbom-pull-request: accepted"

plant_sbom sbom-branch-push $'  push:\n    branches: [main]' "          release-ref-prefix: refs/tags/"
bash "$HERE/workflow-check.sh" "$WORK/sbom-branch-push" >/dev/null
echo "ok   sbom-branch-push: accepted"

plant_sbom sbom-alias-branch-push $'  pull_request: &main\n    branches: [main]\n  push: *main' "          release-ref-prefix: refs/tags/"
bash "$HERE/workflow-check.sh" "$WORK/sbom-alias-branch-push" >/dev/null
echo "ok   sbom-alias-branch-push: accepted"

plant_sbom sbom-prefix-default $'  push:\n    branches: [main]' "          release-ref-prefix: refs/tags/"
bash "$HERE/workflow-check.sh" "$WORK/sbom-prefix-default" >/dev/null
echo "ok   sbom-prefix-default: accepted"

plant_sbom sbom-prefix-with-over-env $'  push:\n    branches: [main]' $'          release-ref-prefix: refs/tags/\n        env:\n          INPUT_RELEASE-REF-PREFIX: refs/heads/'
bash "$HERE/workflow-check.sh" "$WORK/sbom-prefix-with-over-env" >/dev/null
echo "ok   sbom-prefix-with-over-env: accepted"

plant_sbom sbom-github-env-with-pin $'  push:\n    branches: [main]' \
  "          release-ref-prefix: refs/tags/" "" "" "" \
  $'env:\n  INPUT_RELEASE-REF-PREFIX: refs/tags/' \
  "      - run: echo \"INPUT_RELEASE-REF-PREFIX=refs/heads/\" >>\"\$GITHUB_ENV\""
bash "$HERE/workflow-check.sh" "$WORK/sbom-github-env-with-pin" >/dev/null
echo "ok   sbom-github-env-with-pin: accepted"

plant_called sbom-called-write $'    permissions:\n      contents: write'
bash "$HERE/workflow-check.sh" "$WORK/sbom-called-write" >/dev/null
echo "ok   sbom-called-write: accepted"

plant_sbom sbom-read-upload "$RELEASE"
expect_refusal sbom-read-upload "job read-only: sbom-release-upload"

plant_sbom sbom-uses-upper "$RELEASE" "" "Anchore/SBOM-Action@e22c389904149dbc22b58101806040fa8d37a610"
expect_refusal sbom-uses-upper "job read-only: sbom-release-upload"

plant_sbom sbom-tag-push $'  push:\n    tags: ["v*"]'
expect_refusal sbom-tag-push "job read-only: sbom-release-upload"

plant_sbom sbom-alias-tag-push $'  pull_request:\n    branches: &tags ["v*"]\n  push:\n    tags: *tags'
expect_refusal sbom-alias-tag-push "job read-only: sbom-release-upload"

plant_sbom sbom-publish-read "$RELEASE" "" "$SBOM_PUBLISH"
expect_refusal sbom-publish-read "job read-only: sbom-release-upload"

plant_sbom sbom-publish-env-off "$RELEASE" $'        env:\n          INPUT_UPLOAD-RELEASE-ASSETS: false' "$SBOM_PUBLISH"
expect_refusal sbom-publish-env-off "job read-only: sbom-release-upload"

plant_sbom sbom-publish-env-on "$RELEASE" $'        env:\n          INPUT_UPLOAD-RELEASE-ASSETS: true' "$SBOM_PUBLISH"
expect_refusal sbom-publish-env-on "job read-only: sbom-release-upload"

plant_sbom sbom-true-padded "$RELEASE" "          upload-release-assets: ' true '"
expect_refusal sbom-true-padded "job read-only: sbom-release-upload"

plant_sbom sbom-blank "$RELEASE" "          upload-release-assets: '  '"
expect_refusal sbom-blank "job read-only: sbom-release-upload"

plant_sbom sbom-other-literal "$RELEASE" "          upload-release-assets: 'no'"
expect_refusal sbom-other-literal "job read-only: sbom-release-upload"

plant_sbom sbom-expression "$RELEASE" "          upload-release-assets: \${{ inputs.x }}"
expect_refusal sbom-expression "job read-only: sbom-release-upload"

plant_sbom sbom-keys-disagree "$RELEASE" $'          upload-release-assets: false\n          UPLOAD-RELEASE-ASSETS: true'
expect_refusal sbom-keys-disagree "job read-only: sbom-release-upload"

plant_sbom sbom-upload-env-only "$RELEASE" $'        env:\n          INPUT_UPLOAD-RELEASE-ASSETS: false'
expect_refusal sbom-upload-env-only "job read-only: sbom-release-upload"

plant_sbom sbom-branch-push-unpinned $'  push:\n    branches: [main]'
expect_refusal sbom-branch-push-unpinned "job read-only: sbom-release-upload"

plant_sbom sbom-prefix-blank $'  push:\n    branches: [main]' "          release-ref-prefix: ''"
expect_refusal sbom-prefix-blank "job read-only: sbom-release-upload"

plant_sbom sbom-prefix-heads $'  push:\n    branches: [main]' "          release-ref-prefix: refs/heads/"
expect_refusal sbom-prefix-heads "job read-only: sbom-release-upload"

plant_sbom sbom-prefix-key-upper $'  push:\n    branches: [main]' "          RELEASE-REF-PREFIX: refs/heads/"
expect_refusal sbom-prefix-key-upper "job read-only: sbom-release-upload"

plant_sbom sbom-prefix-with-bad-over-env $'  push:\n    branches: [main]' $'          release-ref-prefix: refs/heads/\n        env:\n          INPUT_RELEASE-REF-PREFIX: refs/tags/'
expect_refusal sbom-prefix-with-bad-over-env "job read-only: sbom-release-upload"

plant_sbom sbom-prefix-env-default $'  push:\n    branches: [main]' $'        env:\n          INPUT_RELEASE-REF-PREFIX: refs/tags/'
expect_refusal sbom-prefix-env-default "job read-only: sbom-release-upload"

plant_sbom sbom-prefix-env-lower $'  push:\n    branches: [main]' $'        env:\n          input_release-ref-prefix: refs/heads/'
expect_refusal sbom-prefix-env-lower "job read-only: sbom-release-upload"

plant_sbom sbom-prefix-env-shadow $'  push:\n    branches: [main]' $'        env:\n          INPUT_RELEASE-REF-PREFIX: refs/tags/'
printf 'env:\n  INPUT_RELEASE-REF-PREFIX: refs/heads/\n' >>"$WORK/sbom-prefix-env-shadow/.github/workflows/planted.yml"
expect_refusal sbom-prefix-env-shadow "job read-only: sbom-release-upload"

plant_sbom sbom-prefix-env $'  push:\n    branches: [main]' $'        env:\n          INPUT_RELEASE-REF-PREFIX: refs/heads/'
expect_refusal sbom-prefix-env "job read-only: sbom-release-upload"

plant_sbom sbom-prefix-env-lower-windows $'  push:\n    branches: [main]' $'        env:\n          input_release-ref-prefix: refs/heads/' "" "" windows-2025
expect_refusal sbom-prefix-env-lower-windows "job read-only: sbom-release-upload"

plant_sbom sbom-matrix-env-case $'  push:\n    branches: [main]' \
  $'        env:\n          input_release-ref-prefix: refs/tags/' "" "" "\${{ matrix.os }}" \
  $'env:\n  INPUT_RELEASE-REF-PREFIX: refs/heads/'
expect_refusal sbom-matrix-env-case "job read-only: sbom-release-upload"

plant_sbom sbom-github-env-prefix $'  push:\n    branches: [main]' \
  "" "" "" "" \
  $'env:\n  INPUT_RELEASE-REF-PREFIX: refs/tags/' \
  "      - run: echo \"INPUT_RELEASE-REF-PREFIX=refs/heads/\" >>\"\$GITHUB_ENV\""
expect_refusal sbom-github-env-prefix "job read-only: sbom-release-upload"

plant_sbom sbom-prefix-env-shadow-bad $'  push:\n    branches: [main]' $'        env:\n          INPUT_RELEASE-REF-PREFIX: refs/heads/'
printf 'env:\n  INPUT_RELEASE-REF-PREFIX: refs/tags/\n' >>"$WORK/sbom-prefix-env-shadow-bad/.github/workflows/planted.yml"
expect_refusal sbom-prefix-env-shadow-bad "job read-only: sbom-release-upload"

plant_sbom sbom-prefix-job-env $'  push:\n    branches: [main]' "" "" $'    env:\n      INPUT_RELEASE-REF-PREFIX: refs/heads/'
expect_refusal sbom-prefix-job-env "job read-only: sbom-release-upload"

plant_sbom sbom-prefix-wf-env $'  push:\n    branches: [main]'
printf 'env:\n  INPUT_RELEASE-REF-PREFIX: refs/heads/\n' >>"$WORK/sbom-prefix-wf-env/.github/workflows/planted.yml"
expect_refusal sbom-prefix-wf-env "job read-only: sbom-release-upload"

plant_sbom sbom-env-opaque $'  push:\n    branches: [main]' "        env: \${{ fromJSON(vars.SBOM_ENV) }}"
expect_refusal sbom-env-opaque "job read-only: sbom-release-upload"

plant_called sbom-called-read
expect_refusal sbom-called-read "job read-only: sbom-release-upload"

mkdir -p "$WORK/old-yq-bin"
cat >"$WORK/old-yq-bin/yq" <<'BASH'
#!/usr/bin/env bash
if [ "${1:-}" = --version ]; then
  echo "yq (https://github.com/mikefarah/yq/) version v4.18.1"
  exit 0
fi
echo "Error: 1:1: lexer: invalid input text" >&2
exit 1
BASH
chmod +x "$WORK/old-yq-bin/yq"
plant old-yq .github "$CHECKOUT # v7.0.1"
expect_refusal old-yq "lacks operators the SBOM rule needs" env PATH="$WORK/old-yq-bin:$PATH"

expect_refusal clean "is required" env -u GH_TOKEN -u GITHUB_TOKEN

mkdir -p "$WORK/empty"
expect_refusal empty "no workflow file"

echo "workflow check: 15 accepted, 38 refused"
