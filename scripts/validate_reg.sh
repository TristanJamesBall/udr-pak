#!/usr/bin/env bash
set -euo pipefail

# Validate that symbols referenced in sql/udr-pak_REG.sql exist in the built shared object
# Usage: scripts/validate_reg.sh [so-path] [reg-sql]

SO=${1:-build/lib/udr-pak.so}
REGSQL=${2:-sql/udr-pak_REG.sql}

if [ ! -f "$SO" ]; then
  echo "ERROR: shared object not found: $SO"
  exit 2
fi

if [ ! -f "$REGSQL" ]; then
  echo "ERROR: reg sql not found: $REGSQL"
  exit 2
fi

echo "Inspecting symbols in: $SO"
symbols=$(nm -D --defined-only "$SO" 2>/dev/null | awk '{print $3}')

missing=0
echo "Checking registration SQL: $REGSQL"
grep -oP '\.so\(\K[^\)]+' "$REGSQL" | sed 's/^[ \t]*//;s/[ \t]*$//' | sort -u | while read -r sym; do
  if [ -z "$sym" ]; then
    continue
  fi
  if ! echo "$symbols" | grep -xq -- "$sym"; then
    echo "MISSING: symbol not found in $SO -> $sym"
    missing=1
  else
    echo "OK: $sym"
  fi
done

if [ "$missing" -ne 0 ] 2>/dev/null; then
  echo "One or more registration symbols are missing in $SO"
  exit 3
fi

echo "All registration symbols found in $SO"
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SO="$REPO_ROOT/build/lib/udr-pak.so"
REGSQL="$REPO_ROOT/sql/udr-pak_REG.sql"

if [ ! -f "$SO" ]; then
  echo "Missing $SO; run 'make' first to build the shared object." >&2
  exit 2
fi

echo "Extracting defined symbols from $SO..."
if command -v nm >/dev/null 2>&1; then
  nm -D --defined-only "$SO" 2>/dev/null | awk '{print $3}' | sort -u > /tmp/udr_symbols.txt
else
  readelf -Ws "$SO" 2>/dev/null | awk '/FUNC|OBJECT/ {print $8}' | sort -u > /tmp/udr_symbols.txt
fi

echo "Parsing registered symbols from $REGSQL..."
grep -oP "\.so\([^)]*\)" "$REGSQL" | sed -e 's/^\.so(//' -e 's/)$//' | sort -u > /tmp/udr_registered.txt || true

echo "Checking registered symbols..."
MISSING=0
while read -r sym; do
  [ -z "$sym" ] && continue
  # skip entries that look like file paths or contain slashes/dollars
  if echo "$sym" | grep -q '[\\/\$]'; then
    echo "  Skipping non-symbol entry: '$sym'"
    continue
  fi
  if ! grep -qx "$sym" /tmp/udr_symbols.txt; then
    echo "  MISSING: $sym"
    MISSING=1
  else
    echo "  OK: $sym"
  fi
done < /tmp/udr_registered.txt

if [ "$MISSING" -ne 0 ]; then
  echo "One or more registered symbols are missing in $SO" >&2
  exit 3
fi

echo "All registered symbols found in $SO."
exit 0
