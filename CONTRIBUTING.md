# Contributing to ZHAC

This meta-repo aggregates five source repositories. Most contributions
do not land here — they land in the relevant submodule. Use this file
as the entry point to figure out **where** your change goes.

## License and CLA — required

All contributions, across every submodule, require signing the
Contributor License Agreement in `CLA.md`. Signing is one-time; you
do not repeat it for every repo or PR.

**How to sign:** add a line with your full legal name, email, and
GitHub handle to `CONTRIBUTORS.md` (in this meta-repo) and
include in your first PR description:

> I have read and agree to the Contributor License Agreement
> in `CLA.md`. This and all future contributions I make to this
> project are submitted under its terms.

Each submodule also carries its own copy of `CLA.md` and
`CONTRIBUTORS.md` — adding your name to either one counts.

## Where does my change go?

| Change | Target submodule |
|--------|------------------|
| New Zigbee device port, z2m adaptation, library API | `embedded-zhc` |
| Shared component (HAP protocol, device shadow, metric registry) | `zhac-components` |
| Zigbee stack, Lua engine, coordinator behaviour | `zhac-main-core` (P4) |
| REST / WS / MQTT endpoint, WiFi, OTA, time sync | `zhac-net-core` (S3) |
| UI, styling, client-side state, WS client | `www-spa` |
| Cross-cutting docs, release scripts, integration tests | this meta-repo |

If your change touches **multiple** submodules (common for
architectural refactors), open an issue here first to coordinate.

## Workflow for multi-submodule changes

1. Open a planning issue in this meta-repo describing the change.
2. Branch in each affected submodule; open PRs against each.
3. In this meta-repo, update the submodule pointer commits to the
   SHAs of each merged PR, all in a single meta-repo PR.

## Per-submodule contribution guides

Each submodule carries its own `CONTRIBUTING.md` with build, test, and
style specifics for its tech stack. Start there once you've picked the
right repo.

## Style overview (common across repos)

- **C++**: 4-space indent, `snake_case` for vars/funcs,
  `UPPER_CASE` for macros, `PascalCase` for structs/enums. No
  exceptions / RTTI in firmware.
- **JavaScript**: 2-space indent, single quotes, `camelCase`.
- **Python**: PEP 8, type hints where they help.
- **SPDX headers**: every new source file starts with two lines
  identifying author + license. Templates are in each submodule's
  `CONTRIBUTING.md`.

## Reporting bugs

Open an issue in the relevant submodule. Include:
- Firmware version (`zhac status` → `p4.fw`, `s3.fw`)
- Reset reason from the boot log
- Minimal reproduction steps
- Which submodule(s) you suspect

For cross-submodule or install/setup bugs, open the issue here.
