# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

release-please maintains this file from Conventional Commits; the
`changelog.d/` fragments are the human-readable staging area (see
`changelog.d/README.md`).

## [0.2.0](https://github.com/golusoris/template-native-gpu/compare/v0.1.0...v0.2.0) (2026-10-24)


### ⚠ BREAKING CHANGES

* **license:** the template is no longer permissively licensed; files are EUPL-1.2 unless REUSE.toml says otherwise.

### chore

* **license:** relicense under EUPL-1.2 with LGPL FFmpeg patches ([#8](https://github.com/golusoris/template-native-gpu/issues/8)) ([7eb56a7](https://github.com/golusoris/template-native-gpu/commit/7eb56a75c856f55e68f363828f63df1cfe829308))


### Fixed

* **deps:** bump virtualenv to 21.14.10 for the symlink and quoting CVEs ([#16](https://github.com/golusoris/template-native-gpu/issues/16)) ([66781ef](https://github.com/golusoris/template-native-gpu/commit/66781efef86a56078948f7ce4eeef7f15d6012d4))
* **deps:** lock certifi 2026.10.19 for PYSEC-2026-4320 ([#11](https://github.com/golusoris/template-native-gpu/issues/11)) ([6bb0e31](https://github.com/golusoris/template-native-gpu/commit/6bb0e318a8bb978a923be7b6b1ec90fbe36de530))
* **security:** clear the Trivy Dockerfile and Helm findings ([#5](https://github.com/golusoris/template-native-gpu/issues/5)) ([c72a24a](https://github.com/golusoris/template-native-gpu/commit/c72a24a20cf1ff1c42b39925476143a24e0eeaeb))

## [Unreleased]

### Added

- Initial template scaffold: minimal seed (libproject append-only interop ABI +
  Vulkan reference shader + FFmpeg patch stack) and the full GPU-matrix example
  (CUDA/HIP/Metal/SYCL/Vulkan dispatch).
