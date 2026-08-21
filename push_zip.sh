#!/bin/bash
# ZIP der gebauten Doku + Push als GitHub Release (pkg-<TAG>).
# Das pkg-Prefix erwartet nu-packages / deploy_docs.sh.
#
# Expects (aus DIST bzw. Worker-Env): TAG, OWNER(PUSH_ORG), REPO,
# PACKAGE_NAME, TOKEN(PUSH_TOKEN)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SCRIPT_DIR/DIST" ] && . "$SCRIPT_DIR/DIST"

OWNER="${PUSH_ORG:-KOSMOS-EU}"
REPO="${REPO:-kosmos-doc}"
PACKAGE="${PACKAGE_NAME:-kosmos-doc-web}"
TAG="${TAG:-$(date +%Y%m%d-%H%M)}"
TOKEN="${PACKAGES_TOKEN:-${PUSH_TOKEN:-${CODEBERG_TOKEN:-}}}"
: "${TOKEN:?Set PUSH_TOKEN in DIST}"

# Build (skip wenn Worker build_web.sh schon lief)
if [ -z "${SKIP_BUILD:-}" ]; then
    bash "$SCRIPT_DIR/build_web.sh"
fi

# ZIP (Site-Root = ZIP-Root)
SRC_DIR="${DIST_DIR:-$SCRIPT_DIR/dist}"
if [ ! -d "$SRC_DIR" ] || [ -z "$(ls -A "$SRC_DIR" 2>/dev/null)" ]; then
    echo "ERROR: keine Site unter $SRC_DIR (build_web.sh zuerst)" >&2
    exit 1
fi
TMPZIP="/tmp/${PACKAGE}-${TAG}.zip"
rm -f "$TMPZIP"
(cd "$SRC_DIR" && zip -qr "$TMPZIP" .)
echo "[zip] $(du -h "$TMPZIP" | cut -f1)"

# GitHub Release mit pkg-Prefix
echo "[push] GitHub Release ${OWNER}/${REPO} tag=pkg-${TAG}"
RELEASE=$(curl -sf -X POST "https://api.github.com/repos/${OWNER}/${REPO}/releases" \
    -H "Authorization: token ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"tag_name\":\"pkg-${TAG}\",\"name\":\"${PACKAGE} ${TAG}\",\"draft\":false}")
RELEASE_ID=$(echo "$RELEASE" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
curl -sf -X POST \
    "https://uploads.github.com/repos/${OWNER}/${REPO}/releases/${RELEASE_ID}/assets?name=${PACKAGE}.zip" \
    -H "Authorization: token ${TOKEN}" \
    -H "Content-Type: application/zip" \
    --data-binary "@${TMPZIP}"
echo "=== Pushed: ${PACKAGE}:pkg-${TAG} (GitHub Release) ==="
