#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2025-2026 Evgenij Cjura and project contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# check-spdx.sh — fail if any FIRST-PARTY source file lacks an
# `SPDX-License-Identifier:` header. Mechanises the SPDX policy that
# CLAUDE.md claims is enforced (FINDINGS.md F17). Run from a repo root or
# pass roots as args:  ./tools/check-spdx.sh [DIR ...]
#
# Vendored deps keep their upstream headers and are skipped; generated
# device definitions/registries are skipped (the generator in the private
# zhac-tools owns their headers).
set -uo pipefail

ROOTS=("${@:-.}")

# Path fragments to skip (vendored / generated / build artefacts / deps).
SKIP_RE='/(build|managed_components|node_modules|dist|\.git|third_party|LICENSES)/|/arduinojson/|/lua_cjson/|/georgik__lua/|/components/mqtt/|/definitions/[^/]+/generated/|/include/zhc/devices/.*_registry\.hpp$|/definitions/.*\.(cpp|hpp)$|/editor/zhac-completions\.js$'

missing=0
checked=0
while IFS= read -r f; do
  case "$f" in
    *.c|*.cpp|*.cc|*.h|*.hpp|*.js|*.jsx|*.py|*.sh) ;;
    *) continue ;;
  esac
  printf '%s\n' "$f" | grep -qE "$SKIP_RE" && continue
  checked=$((checked+1))
  # SPDX line must appear in the first 15 lines.
  if ! head -n 15 "$f" 2>/dev/null | grep -q 'SPDX-License-Identifier:'; then
    echo "MISSING SPDX: $f"
    missing=$((missing+1))
  fi
done < <(find "${ROOTS[@]}" -type f 2>/dev/null)

echo "---"
echo "checked=$checked  missing=$missing"
[ "$missing" -eq 0 ] || { echo "FAIL: $missing file(s) missing SPDX header"; exit 1; }
echo "OK: all first-party sources carry an SPDX-License-Identifier"
