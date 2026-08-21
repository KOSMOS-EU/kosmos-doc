#!/bin/bash
# Deploy der gebauten Doku in den KOSMOS-Space auf OpenCloud per WebDAV.
#
# Der WebDAV-Link (public_link) kommt aus der Intranet-Config des Pods:
#   /nu/container/<POD>/compose/portal-sites.yaml
# (der Intranet-Dienst montiert sie read-only als /app/sites.yaml).
#
# Usage:
#   ./deploy_docs.sh                       # lokale dist/ (zuvor build_web.sh)
#   ./deploy_docs.sh pkg-20260820-1607     # bestimmtes Package von GitHub
#
# DIST (lokal, gitignored):
#   HOST=cloud.brandis.eu
#   POD=cloud_brandis
#   KOSMOS_SITE=<domain des KOSMOS-Sites in portal-sites.yaml>
#   WEBDAV_BASE=https://cloud.brandis.eu/public-webdav
#   WEBDAV_USER= / WEBDAV_TOKEN=   (nur wenn der Link Passwort schuetzt)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/DIST"

HOST="${HOST:?HOST in DIST}"
POD="${POD:?POD in DIST}"
SITE="${KOSMOS_SITE:?KOSMOS_SITE in DIST}"
WEBDAV_BASE="${WEBDAV_BASE:-https://${HOST}/public-webdav}"
SITES_YAML="/nu/container/${POD}/compose/portal-sites.yaml"

# ── 1. public_link aus der Intranet-Config holen ──
echo "[resolve] ${SITE} -> ${SITES_YAML} auf ${HOST}"
LINK=$(ssh "root@${HOST}" awk -v dom="\"${SITE}\"" '
    $0 ~ "domain:[[:space:]]*" dom { f=1; next }
    f && /public_link:/ { gsub(/[^A-Za-z0-9]/, "", $2); print $2; exit }
' "$SITES_YAML")
: "${LINK:?kein public_link fuer Site ${SITE} in ${SITES_YAML}}"
DAV="${WEBDAV_BASE}/${LINK}/"
echo "[resolve] WebDAV: ${DAV}"

AUTH=()
if [ -n "${WEBDAV_USER:-}" ]; then
    AUTH=(-u "${WEBDAV_USER}:${WEBDAV_TOKEN}")
fi

# ── 2. Site beschaffen: lokale dist/ oder Package von GitHub ──
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
SRC=""

if [ -n "${1:-}" ]; then
    TAG="$1"
    [[ "$TAG" != pkg-* ]] && TAG="pkg-${TAG}"
    echo "[fetch] ${PACKAGE_NAME:-kosmos-doc-web}:${TAG} von GitHub"
    curl -sfL -H "Authorization: token ${PUSH_TOKEN}" \
        "https://api.github.com/repos/${PUSH_ORG:-KOSMOS-EU}/${REPO:-kosmos-doc}/releases/tags/${TAG}" \
        | python3 -c "
import sys, json
r = json.load(sys.stdin)
asset = next(a for a in r['assets'] if a['name'].endswith('.zip'))
print(asset['browser_download_url'])
" > "$WORK/url"
    curl -sfL -H "Authorization: token ${PUSH_TOKEN}" -o "$WORK/site.zip" "$(cat "$WORK/url")"
    mkdir -p "$WORK/site"
    (cd "$WORK/site" && unzip -q "$WORK/site.zip")
    SRC="$WORK/site"
elif [ -d "$SCRIPT_DIR/dist" ] && [ -n "$(ls -A "$SCRIPT_DIR/dist" 2>/dev/null)" ]; then
    SRC="$SCRIPT_DIR/dist"
else
    echo "ERROR: keine dist/ (build_web.sh) und kein Package-Tag angegeben" >&2
    exit 1
fi
echo "[src] $(find "$SRC" -type f | wc -l) Dateien"

# ── 3. Alte Dateien loeschen (PROPFIND + DELETE) ──
OLD=$(curl -sf "${AUTH[@]}" -X PROPFIND -H "Depth: infinity" -H "Content-Type: application/xml" "$DAV" \
    -d '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop><d:resource/></d:prop></d:propfind>' \
    | grep -oE '<d:href>[^<]+</d:href>' | sed -E 's|</?d:href>||g' \
    | python3 -c "import sys, urllib.parse; [print(urllib.parse.unquote(l.strip())) for l in sys.stdin if l.strip().strip('/')]")
COUNT=0
while IFS= read -r p; do
    [ -z "$p" ] && continue
    curl -sf -o /dev/null "${AUTH[@]}" -X DELETE "${DAV}${p}" || true
    COUNT=$((COUNT+1))
done <<< "$OLD"
echo "[purge] ${COUNT} alte Dateien geloescht"

# ── 4. Highladen (PUT; OpenCloud legt fehlende Ordner an) ──
UPLOADED=0
cd "$SRC"
while IFS= read -r -d '' f; do
    curl -sf -o /dev/null "${AUTH[@]}" -X PUT -T "$f" "${DAV}${f#./}"
    UPLOADED=$((UPLOADED+1))
    [ $((UPLOADED % 50)) -eq 0 ] && echo "[upload] ${UPLOADED} ..."
done < <(find . -type f -print0)
echo "=== ${UPLOADED} Dateien in ${DAV} ==="
