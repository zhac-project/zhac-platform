# SPDX-FileCopyrightText: 2025-2026 Evgenij Cjura and project contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# ZHAC platform build orchestration.
#
# Prerequisites:
#   - ESP-IDF v6.0 activated (source export.sh from the IDF install)
#   - Node.js >=18 (for www-spa)
#   - Python >=3.10 (for integration tests)

default: build

# Point Component Manager + firmware at local submodule checkouts so
# they don't re-fetch from git on every build.
export IDF_COMPONENT_OVERRIDE_PATH := `pwd` / "zhac-components/components"
export EMBEDDED_ZHC_PATH           := `pwd` / "embedded-zhc"

# ESP-IDF exposes `idf.py` as a bash ALIAS in activate_idf_*.sh — which
# does not survive the jump into just's sub-shells. Resolve the real
# python + script path from the env vars activation DOES export.
# If IDF isn't activated, these will be empty and assert-idf fails early.
IDF_PY := env_var_or_default("IDF_PYTHON_ENV_PATH", "") + "/bin/python3 " + env_var_or_default("IDF_PATH", "") + "/tools/idf.py"

# Fail fast if the user forgot to source activate_idf_v6.0.sh.
assert-idf:
    @test -n "${IDF_PATH:-}" || { echo "ESP-IDF not activated — source activate_idf_v6.0.sh first"; exit 1; }
    @test -x "{{IDF_PY}}" -o -f "${IDF_PATH}/tools/idf.py" || { echo "idf.py not found at ${IDF_PATH}/tools/idf.py"; exit 1; }

setup:
    git submodule update --init --recursive
    cd zhac-net-core/www-spa && npm ci

build: build-www build-p4 build-s3

build-www:
    cd zhac-net-core/www-spa && npm run build

build-p4: assert-idf
    rm -rf zhac-main-core/build
    cd zhac-main-core && {{IDF_PY}} set-target esp32p4 && {{IDF_PY}} build

build-s3: assert-idf
    rm -rf zhac-net-core/build
    cd zhac-net-core && {{IDF_PY}} set-target esp32s3 && {{IDF_PY}} build

clean:
    rm -rf zhac-main-core/build zhac-net-core/build
    rm -rf zhac-net-core/www-spa/dist zhac-net-core/www-spa/node_modules/.vite
    rm -rf zhac-main-core/managed_components zhac-net-core/managed_components

deep-clean: clean
    find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    rm -rf zhac-net-core/www-spa/node_modules

flash-p4 port="/dev/ttyACM0": assert-idf
    cd zhac-main-core && {{IDF_PY}} -p {{port}} flash

flash-s3 port="/dev/ttyUSB0": assert-idf
    cd zhac-net-core && {{IDF_PY}} -p {{port}} flash

monitor-p4 port="/dev/ttyACM0": assert-idf
    cd zhac-main-core && {{IDF_PY}} -p {{port}} monitor

monitor-s3 port="/dev/ttyUSB0": assert-idf
    cd zhac-net-core && {{IDF_PY}} -p {{port}} monitor

spiffs-only port="/dev/ttyUSB0": assert-idf
    cd zhac-net-core && {{IDF_PY}} -p {{port}} spiffs-flash

# Pull upstream changes in every submodule to their tracked branches.
update:
    git submodule update --remote --recursive

# Record a new meta-repo tag that pins current submodule SHAs.
# Usage: just release vYYYYMMDDVV
release tag:
    git add embedded-zhc zhac-components zhac-main-core zhac-net-core
    git commit -m "release: {{tag}}"
    git tag {{tag}}
    @echo "Now: git push && git push --tags"

# Run host-side tests in every submodule (skips firmware build tests
# that require hardware).
test-host:
    cd embedded-zhc && cmake -B build -S . && cmake --build build && ctest --test-dir build
    cd zhac-net-core/www-spa && npm test -- --run

# Print what version is checked out in each submodule.
status:
    @echo "=== embedded-zhc ==="
    @cd embedded-zhc && git describe --tags --always --dirty
    @echo "=== zhac-components ==="
    @cd zhac-components && git describe --tags --always --dirty
    @echo "=== zhac-main-core ==="
    @cd zhac-main-core && git describe --tags --always --dirty
    @echo "=== zhac-net-core ==="
    @cd zhac-net-core && git describe --tags --always --dirty
    @echo "=== zhac-net-core/www-spa ==="
    @cd zhac-net-core/www-spa && git describe --tags --always --dirty
