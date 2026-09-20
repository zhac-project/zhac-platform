<!--
SPDX-FileCopyrightText: 2025-2026 Evgenij Cjura and project contributors
SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Changelog

Changes to the `zhac-platform` meta-repo itself. Firmware, library and UI changes are
recorded in each sub-repo's own `CHANGELOG.md`. An `## [Unreleased]` section accumulates
work; its contents become the release-tag annotation at `just release`.

## [Unreleased]

### Added

- **Issue forms for the whole project** — device request, bug report and board report,
  plus links to Discussions and the security policy. Blank issues are off so reports
  arrive with the build, firmware version and device identifiers already filled in.
- **Release images on every tag** — the `release` workflow builds the P4 and S3 firmware
  from the pinned submodules and attaches one merged `.bin` per board (flash at offset
  0x0) plus `SHA256SUMS` to the GitHub release. No toolchain needed to install ZHAC.

### Fixed

- `just test-host` ran `npm test` in www-spa, which has no test script; it now runs the
  design-token guard, the only automated check www-spa has.
