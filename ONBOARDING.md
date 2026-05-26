# ONBOARDING — zhac-platform (meta-repo)

You are an AI agent arriving on **zhac-platform**. This file is your
single-source briefing. Read it top-to-bottom before opening anything
else. Everything here is load-bearing.

---

## 1. What ZHAC is (platform overview)

**ZHAC** = dual-chip ESP32 Zigbee Home Automation Controller.

| Chip | Role | Firmware repo |
|------|------|---------------|
| ESP32-P4 | Zigbee coordinator (ZCL, EZSP/ZNP drivers, Lua rules) | `zhac-main-core` |
| ESP32-S3 | WiFi / REST / WebSocket / MQTT gateway | `zhac-net-core` |

The two chips talk over SPI using a custom binary framing called
**HAP** (not HomeKit — our own protocol). S3 is the host, P4 is the
slave.

Data flow (happy path):

```
Zigbee device --(radio)--> P4 EZSP/ZNP driver
                         --> zhc_adapter (decodes ZCL to ZclAttribute)
                         --> device_shadow (NVS-backed cache)
                         --> HAP/SPI --> S3
                                         --> ws_event_broadcast --> Web UI
                                         --> mqtt_gw_publish --> MQTT broker

Web UI toggles switch --> WS cmd --> S3 api_handlers
                       --> HAP/SPI --> P4 hap_dispatch
                                      --> zhc_adapter TZ converter
                                      --> ZCL write --> Zigbee device
```

### The 7 repos

This split replaced the former monorepo on 2026-04-23. Every repo was
tagged `v2026042301` at the split point.

| Repo | Role | License |
|------|------|---------|
| **zhac-platform** *(this)* | Meta — aggregates submodules, holds umbrella LICENSE/NOTICE/CLA/CONTRIBUTORS, cross-repo tests | Apache-2.0 umbrella; per-sub licenses authoritative |
| `embedded-zhc` | C++20 static-memory ZCL device library (373 vendors, 4 167 devices) | Apache-2.0 |
| `zhac-components` | 17 shared ESP-IDF components + vendored `arduinojson` | Per-component (Apache or AGPL); arduinojson = MIT |
| `zhac-main-core` | P4 firmware (Zigbee coordinator) | AGPL-3.0-or-later |
| `zhac-net-core` | S3 firmware (WiFi gateway). Nests `www-spa` as submodule | AGPL-3.0-or-later |
| `www-spa` | Preact 10 + Vite 5 Web UI, bundled into S3 SPIFFS | AGPL-3.0-or-later |
| `zhac-docs` | Public documentation (NOT a submodule — clone separately) | Apache where docs describe library; AGPL where docs describe firmware |
| *(private)* `zhac-tools` | Device-port generators, hygiene scripts — maintainer-only | — |

### Version scheme

`vYYYYMMDDVV` — date plus 2-digit daily counter. Example:
`v2026042301` = first tag on 2026-04-23. Tags are **independent per
repo** — the meta-repo pins submodules to specific commits, not to
shared tags.

---

## 2. What zhac-platform owns

This repo **does not build firmware**. Its job is:

1. **Aggregate submodules** at known-good commits via `.gitmodules`.
2. **Carry umbrella LICENSE, NOTICE, CLA.md, CONTRIBUTORS.md, CONTRIBUTING.md** — signing the CLA once (by adding yourself to `CONTRIBUTORS.md`) covers all 7 repos.
3. **Host cross-repo integration tests** under `tests/` (P4↔S3 HAP round-trip, end-to-end WS→ZCL).
4. **Orchestrate builds** via `justfile` when you want to rebuild everything from a single checkout.

### Layout

```
zhac-platform/
├── embedded-zhc/             (submodule)
├── zhac-components/          (submodule)
├── zhac-main-core/           (submodule)
├── zhac-net-core/            (submodule)
│   └── www-spa/              (nested submodule of net-core)
├── tests/                    (cross-repo integration tests)
├── justfile                  (build orchestration)
├── README.md · LICENSE · NOTICE · CLA.md · CONTRIBUTORS.md · CONTRIBUTING.md
└── LICENSES/                 (Apache-2.0 + AGPL-3.0 canonical texts)
```

`zhac-docs` and `zhac-tools` live as siblings, **not submodules**.
Clone them separately when you need them.

---

## 3. Clone / build recipe

```bash
# Full checkout with all submodules (recursive for nested www-spa)
git clone --recurse-submodules https://github.com/zhac-project/zhac-platform.git
cd zhac-platform

# Build web UI first (produces dist/ consumed by S3 SPIFFS)
cd www-spa || cd zhac-net-core/www-spa
npm install && npm run build
cd -

# Build P4 firmware
cd zhac-main-core
idf.py set-target esp32p4
idf.py build
cd ..

# Build S3 firmware
cd zhac-net-core
idf.py set-target esp32s3
idf.py build
```

**Do not invoke `idf.py build` for the user** — they build firmware
themselves. Your job stops at code changes.

### Local override for component manager

When building from the meta-repo, the S3/P4 `idf_component.yml`
manifests fetch `zhac-components` from GitHub by default. To use the
local submodule checkout instead:

```bash
export IDF_COMPONENT_OVERRIDE_PATH=$PWD/zhac-components/components
```

Same for `embedded-zhc` — firmware CMake uses `FetchContent` by
default, overridable with `EMBEDDED_ZHC_PATH=$PWD/embedded-zhc`.

---

## 4. Cross-repo dependency graph

```
                     zhac-platform
                          │
        ┌────────┬────────┼────────┬─────────────┐
        ▼        ▼        ▼        ▼             ▼
  embedded-zhc zhac-components  zhac-main-core  zhac-net-core
                    │                 │             │
                    │                 │             ▼
                    │                 │          www-spa (nested)
                    ├─────────────────┘
                    └── consumed by both firmware repos
                        via ESP Component Manager
```

- `embedded-zhc` has **zero** project-internal deps. Library is
  host-testable with no ESP-IDF.
- `zhac-components` depends only on `embedded-zhc` (through
  `zhc_adapter`) and on the IDF core.
- Both firmware repos depend on `zhac-components` + `embedded-zhc`.
- `www-spa` is build-time-only: its `dist/` is bundled into S3 SPIFFS.

---

## 5. Licensing — the rules that matter

- **Per-file SPDX headers are authoritative.** Repo-level LICENSE is
  a convenience pointer. Every source file has
  `SPDX-License-Identifier: <Apache-2.0 | AGPL-3.0-or-later | MIT>`
  as line 2.
- **Apache** covers: `embedded-zhc/**`, most of `zhac-components/**`
  (all but `mqtt_gw`, `simple_rules`, `hap_master`, which are AGPL).
- **AGPL** covers: `zhac-main-core/**`, `zhac-net-core/**`,
  `www-spa/**`, and the AGPL components above.
- **MIT** covers vendored `arduinojson` only.
- **CLA**: Apache ICLA v2.2 + explicit §4 relicensing grant so the
  maintainer can dual-license. Signing = add your name + email to
  `CONTRIBUTORS.md` in any repo's first PR.

Run `tools/add_spdx_headers.py` from the old monorepo history if you
ever need to re-stamp — the sweep is idempotent.

---

## 6. Conventions

Inherited from the monorepo CLAUDE.md. Still apply across all 7 repos.

### Code

- **C++17** on ESP-IDF (`-fno-exceptions -fno-rtti`). Library
  (`embedded-zhc`) is C++20.
- **`static_assert` on struct sizes** for ABI-critical types:
  - `ZclAttribute` = 52 B
  - `ZclAttrEvent` = 96 B
  - `ShadowAttr` = 52 B
  - `ZapDevice` = 522 B
  Bump `NVS_SHADOW_VERSION` (currently v4) if you change layout.
- **No hand-maintained attribute namespaces.** Names come from the
  `zhc` library's `exposes`. String keys ≤ 20 chars, string values ≤ 24 chars.
- Generated files (`embedded/zhc/definitions/**/generated/`) are
  committed. Regenerate with `just refresh-parity` (needs the private
  `zhac-tools` repo).

### Behaviour (from user memory)

- **User builds firmware themselves.** Don't run `idf.py build`.
- **Early-dev stance.** Accept breaking changes without migration
  shims — project isn't deployed.
- **Prefer hook/callback registration** when two components would
  otherwise need each other. See `zhac_adapter_register_shadow_hook`
  for the canonical pattern.

### Commits and PRs

- No commits unless the user asks.
- PRs land in the repo that owns the code, not in `zhac-platform`.
  Only meta-level changes (submodule bumps, integration tests,
  umbrella docs) land here.
- Use trailer:
  `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`

---

## 7. Cross-repo wire contracts (don't break these)

### HAP (S3↔P4)

- Binary framing over SPI. Request/response pairs with message type +
  payload. See `zhac-components/components/hap_protocol/`.
- S3 is host, P4 is slave. Every P4-originated event (attribute
  report, device join) is pushed via the same SPI channel.

### WS envelope (SPA↔S3)

- `{id, cmd, args}` → `{id, ok, data|err}`.
- Push events from S3: `device.added`, `device.updated`,
  `device.removed`, `attr.bulk`, `alert.*`. All emitted via
  `ws_event_broadcast`.
- Full dispatch table: 35 entries in
  `zhac-net-core/main/ws_bridge.cpp`. Every entry maps to a
  transport-agnostic `api_*` function in `api_handlers.{h,cpp}`.

### ZclAttribute (52 B)

The canonical attribute type shared by every consumer.

```cpp
struct ZclAttribute {
    char     key[20];        // z2m-style expose name
    uint8_t  val_type;        // VAL_BOOL / VAL_INT / VAL_UINT / VAL_STR
    uint16_t cluster;
    uint16_t attr_id;
    union { int32_t int_val; char str_val[24]; };
};
static_assert(sizeof(ZclAttribute) == 52);
```

Definition: `zhac-components/components/zap_common/include/zcl_attribute.h`.

---

## 8. Common pitfalls

- **S3 freeze via log pipeline.** `mqtt_gw_publish` used to block the
  `ESP_LOG` vprintf hook. Fixed by a worker task + bounded queue in
  `components/mqtt_gw/mqtt_gw_s3.cpp`. Do NOT call
  `mqtt_gw_publish` from within log output paths.
- **TZ converter type mismatch.** UI paths send `Uint` via
  `zhac_adapter_send_uint` but older TZ converters only accepted
  `Bool`/`StringRef`. When writing TZ converters, accept the full
  `ValType` union.
- **Tuya LED drivers stay silent** on command-driven state changes.
  Every light definition must include `ReportingSpec` + `ConfigStep`
  initial reads, and P4 performs an **optimistic shadow update** in
  `handle_set_attribute` after a successful send so the UI reflects
  the toggle before the next attribute report.
- **Z2M fingerprint order matters.** When two vendors share a
  `zigbee_models` string (e.g. `ZB-CL01` on Kurvia + Ysrsai), always
  match the manufacturer-filtered variant first; the naked one falls
  through in Pass 2.

---

## 9. When to touch zhac-platform vs a sub-repo

| Task | Touch this repo? |
|------|------------------|
| Fix a firmware bug | **No** — land in `zhac-main-core` or `zhac-net-core`. |
| Add a device definition | **No** — land in `embedded-zhc/definitions/`. |
| Change the HAP protocol | **No** — land in `zhac-components/components/hap_protocol/` (+ hap_slave / hap_master / hap_bridge as consumers). |
| Bump a submodule pin | **Yes** — commit the submodule hash advance here. |
| Add a cross-repo integration test | **Yes** — under `tests/`. |
| Update umbrella LICENSE / NOTICE / CLA | **Yes** (and mirror to other repos' own copies). |
| Add a new submodule | **Yes** — edit `.gitmodules`, update this `ONBOARDING.md` and the README. |

---

## 10. Where to go next

- **Architecture / API**: clone `zhac-docs` (`REST_API.md`,
  `WS_API.md`, `LUA_API.md`, `RULES_DSL.md`, `FEATURES.md`).
- **Knowledge graph** *(maintainer-only; not part of the public split)*:
  the pre-split monorepo has `graphify-out/graph.json` (982 nodes,
  1 331 edges, 146 communities).
- **CLAUDE.md** from the old monorepo still documents the
  code-change philosophy (Think Before Coding · Simplicity First ·
  Surgical Changes · Goal-Driven Execution). Same rules apply here.

---

*Tag on first split: `v2026042301` · 2026-04-23.*
*Maintainer: Evgenij Cjura (`zhac.project@gmail.com`).*
