# zhac-platform

Meta-repo for **ZHAC** — an ESP32 dual-chip Zigbee Home Automation
Controller. This repo is not built directly; it aggregates four source
repositories via git submodules and carries the project's public
identity (umbrella LICENSE, NOTICE, CLA, contributor list, cross-repo
integration tests).

## Sub-repositories (submodules)

| Submodule | Role | License |
|-----------|------|---------|
| [embedded-zhc](https://github.com/zhac-project/embedded-zhc) | Host-testable C++20 device library (373 z2m vendors, 4 167 / 4 213 devices — 98.9 % parity) | Apache-2.0 |
| [zhac-components](https://github.com/zhac-project/zhac-components) | Shared ESP-IDF components (HAP protocol, device shadow, ZHC adapter, ...) | Apache-2.0 / AGPL-3.0 mix |
| [zhac-main-core](https://github.com/zhac-project/zhac-main-core) | ESP32-P4 firmware — Zigbee coordinator + Lua engine | AGPL-3.0-or-later |
| [zhac-net-core](https://github.com/zhac-project/zhac-net-core) | ESP32-S3 firmware — WiFi / REST / WebSocket / MQTT gateway | AGPL-3.0-or-later |
| [www-spa](https://github.com/zhac-project/www-spa) *(nested under zhac-net-core)* | Preact SPA bundled into the S3 SPIFFS partition | AGPL-3.0-or-later |

## Related repositories (NOT submodules)

- [zhac-docs](https://github.com/zhac-project/zhac-docs) — public
  documentation (architecture, API reference, design plans, reviews).
  Clone separately when you want to edit docs. Kept out of the build
  tree so doc-only contributors don't have to clone 12 MB of firmware
  history.
- **zhac-tools** *(private)* — device-port generators and project
  hygiene scripts. Maintainer-only access.

## Prerequisites

- **ESP-IDF v6.0** — `source /path/to/esp-idf-v6.0/export.sh`
- **Node.js ≥ 18** — for the Web UI build
- **Python ≥ 3.10** — for host integration tests (optional)
- **`just`** — command runner. Install with one of:
  ```bash
  sudo snap install just --classic      # Ubuntu/snap
  cargo install just                     # if you have Rust
  curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
  ```
  `just` is optional — every recipe is a plain shell command. See
  [Build without `just`](#build-without-just) below.

## Quick start

```bash
git clone --recurse-submodules https://github.com/zhac-project/zhac-platform.git
cd zhac-platform
source /path/to/esp-idf-v6.0/export.sh

just setup         # idempotent — submodules + npm deps
just build         # www-spa + both firmwares
just flash-p4 /dev/ttyACM0
just flash-s3 /dev/ttyUSB0
just monitor-s3 /dev/ttyUSB0
```

If you forgot `--recurse-submodules` on clone:

```bash
git submodule update --init --recursive
```

## Build without `just`

The `justfile` is a 1:1 wrapper around shell commands. To build by
hand, set the Component-Manager override so firmware builds use the
local submodule checkout instead of re-fetching from GitHub:

```bash
export IDF_COMPONENT_OVERRIDE_PATH="$PWD/zhac-components/components"
export EMBEDDED_ZHC_PATH="$PWD/embedded-zhc"

git submodule update --init --recursive

# Web UI (outputs www-spa/dist consumed by S3 SPIFFS)
( cd zhac-net-core/www-spa && npm ci && npm run build )

# P4 firmware
( cd zhac-main-core && idf.py set-target esp32p4 && idf.py build )

# S3 firmware
( cd zhac-net-core && idf.py set-target esp32s3 && idf.py build )
```

Flash + monitor:

```bash
( cd zhac-main-core && idf.py -p /dev/ttyACM0 flash )
( cd zhac-net-core  && idf.py -p /dev/ttyUSB0 flash monitor )
```

## Layout after checkout

```
zhac-platform/
├── embedded-zhc/             (submodule — library)
├── zhac-components/          (submodule — shared components)
├── zhac-main-core/           (submodule — P4 firmware)
├── zhac-net-core/            (submodule — S3 firmware)
│   └── www-spa/              (nested submodule — Web UI)
├── tests/                    (cross-repo integration tests)
├── justfile                  (build orchestration)
├── LICENSE                   (umbrella — see per-submodule LICENSE too)
├── NOTICE                    (third-party attribution)
├── CLA.md · CONTRIBUTORS.md · CONTRIBUTING.md
└── LICENSES/                 (Apache-2.0 + AGPL-3.0 canonical texts)
```

Documentation lives in the [zhac-docs](https://github.com/zhac-project/zhac-docs)
repo — not under `zhac-platform/docs/`.

Each source repo carries its own `ONBOARDING.md` aimed at new
contributors (human or AI). Start there when opening a sub-repo cold.

## Architecture at a glance

```
             Zigbee device
                  │
                  ▼  radio
┌─────────────────────────────┐
│  ESP32-P4 (zhac-main-core)  │  Zigbee coordinator + Lua engine
│  EZSP/ZNP → zhc_adapter     │
│          → device_shadow    │
└──────────────┬──────────────┘
               │ HAP (custom binary over SPI)
               ▼
┌─────────────────────────────┐
│  ESP32-S3 (zhac-net-core)   │  WiFi / REST / WS / MQTT
│  hap_master → api_handlers  │
│            → ws_server      │
│            → mqtt_gw        │
└──────────────┬──────────────┘
               │ WebSocket  /ws
               ▼
           Preact SPA (www-spa)
           bundled into S3 SPIFFS
```

`embedded-zhc` supplies the device knowledge base (converters,
exposes, bindings, reporting specs) consumed by P4 through
`zhc_adapter`. `zhac-components` carries everything both firmware
chips share.

## Version scheme

Every repo — the five source repos, `zhac-docs`, and this meta-repo —
tag releases as `vYYYYMMDDVV`:

| Tag | Meaning |
|-----|---------|
| `v2026042301` | First tagged release on 2026-04-23 |
| `v2026042302` | Second tagged release on 2026-04-23 |
| `v2026042401` | First tagged release on 2026-04-24 |

A `zhac-platform` tag pins a specific commit for each submodule, so
checking out `zhac-platform@v2026042301` reproduces the exact bundle.

## Licensing

- `embedded-zhc` is **Apache-2.0** — keep it reusable outside ZHAC.
- Everything else (firmware, UI, docs, most components) is
  **AGPL-3.0-or-later**.
- `zhac-components/zap_common` and `zhac-components/metrics` are
  Apache-2.0 within an otherwise-AGPL repo, for the same reason:
  they're portable utilities.
- Every source file carries an `SPDX-License-Identifier:` header.

See `LICENSE` for the umbrella overview, `NOTICE` for third-party
attributions, and each submodule's `LICENSE` file for the
authoritative per-component license.

## Contributing

1. Read `CLA.md` and sign by adding yourself to `CONTRIBUTORS.md` in
   your first PR (in any repo — signing once covers all).
2. Pick the relevant submodule or sibling repo — most contributions
   live there, not in this meta-repo.
3. See `CONTRIBUTING.md` for details.

### Touch `zhac-platform` vs a sub-repo

| Task | Land it here? |
|------|---------------|
| Fix a firmware bug | **No** — in `zhac-main-core` or `zhac-net-core`. |
| Add a device definition | **No** — in `embedded-zhc/definitions/`. |
| Change the HAP protocol | **No** — in `zhac-components/components/hap_protocol/`. |
| Add a Web UI feature | **No** — in `www-spa`. |
| Bump a submodule pointer | **Yes** — commit the advance here. |
| Add a cross-repo integration test | **Yes** — under `tests/`. |
| Update umbrella LICENSE / NOTICE / CLA | **Yes** (mirror to other repos too). |

## Trademarks

"ZHAC" and associated names, logos, and marks are the exclusive
property of the project maintainer. The licenses that govern the
source code DO NOT grant any right to use these names or marks; forks
must choose a different product name and branding. See `NOTICE`.
