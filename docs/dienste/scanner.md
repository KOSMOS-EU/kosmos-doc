---
icon: octicons/file-24
---

# Scanner

**scanner-fix** ist ein Kompatibilitäts-Sidecar für
MFP-Scanner, die Dokumente per WebDAV in den Open Core scannen.

## Das Problem

Sharp-Scanner-Firmware (z. B. SKM_C301i) interpretiert
**HTTP 204 auf `OPTIONS`** als Netzwerkfehler. Der Open Core
antwortet RFC-konform mit 204 auf `OPTIONS` — die Scanner-Firmware
erwartet aber 200. Ergebnis: Scan geht nicht durch.

## Die Lösung

Ein Nginx-Sidecar (`nginx:alpine`) auf einem eigenen
Traefik-Entrypoint (Port 444):

- `OPTIONS`-Requests werden abgefangen und mit **200 + DAV-
  Headers** beantwortet.
- Alle anderen Requests (`PUT`, `PROPFIND`, …) werden
  transparent an den Open Core weitergeleitet.

```
Scanner ──▶ :444 (scanner-fix/Nginx) ──▶ Open Core (WebDAV)
             OPTIONS → 200 + DAV-Headers
             PUT/PROPFIND/… → proxy_pass
```

## Voraussetzungen

1. Traefik-Entrypoint `scanner` auf Port 444 (+ Port-Mapping).
2. **Firewall**: Port 444/tcp im `[firewall]`-Block freigeben.
3. Nginx-Config (`config/scanner-fix.conf`) im Compose-Dir.
4. `scanner-fix.yml` im Compose-Dir aktiv.

## Scanner-Konfiguration

| Feld | Wert |
|------|------|
| URL  | `https://cloud.<SUPERDOMAIN>:444/dav/spaces/<storage-id>$<space-id>/` |
| Auth | HTTP Basic: Benutzername + **App-Token** (Open Core: Settings → App Passwords) |

Getestet mit Sharp SKM_C301i (Juli 2026).
