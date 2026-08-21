#!/bin/bash
# mkdocs-Build fuer den Web-Build-Worker (alpine: python3 + pip)
# Output: dist/  (push_zip.sh verpackt den Inhalt)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

OUT="${DIST_DIR:-$SCRIPT_DIR/dist}"
rm -rf "$OUT"
mkdir -p "$OUT"

# mkdocs-material installieren (Image hat python3 + pip, alpine)
pip install --quiet --no-cache-dir --break-system-packages mkdocs-material

mkdocs build --strict -d "$OUT"
echo "[build] mkdocs ok -> $DIST_DIR ($(find "$DIST_DIR" -type f | wc -l) Dateien)"
