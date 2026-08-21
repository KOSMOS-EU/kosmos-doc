---
icon: octicons/globe-24
---

# Intranet

Das **Portal** (`opencloud_intranet`) ist die Intranet-Oberfläche
der Edition: es serviert **Open-Core-Public-Links als Sites** —
Dokumente werden damit Inhalte für andere Oberflächen
([Skalierung](../universum/skalierung.md#horizontal-web-apps)).

Repo: `opencloud_intranet` (KOSMOS-EU).

## Wie es arbeitet

- **Sites-Config** (`portal-sites.yaml` im Compose-Dir, ro
  gemountet als `/app/sites.yaml`): je Eintrag Domain, Site-Name
  und der `public_link` des Open Core:

```yaml
sites:
  - domain: "kosmos.kunde.example.com"
    name: KOSMOS
    public_link: <link-token>
```

- **Content**: Die Sites lesen über den Public-Link (WebDAV) aus
  dem jeweiligen Space — der Portal-Service hat keinen direkten
  Dateisystemzugriff.
- **Caching**: kurze TTL (Default 60 s) mit Refresh-Trigger
  (`REFRESH_TOKEN`) — nach Uploads tauscht der Cache schnell.
- **Security**: optional `ALLOWED_IPS` (Source-Beschränkung auf
  Management-Netze).

## Authentifizierung

OIDC gegen den **eingebauten IDP des Open Core** (Client `portal`):

- Session-Cookies: secure, sliding, Default 7 Tage
  (`SESSION_MAX_AGE=604800`).
- Kein lokales Login — wer im Open Core darf, sieht das Portal.

## Domains und Port

`intranet.<SUPERDOMAIN>`, intern Port 8080 (deshalb nutzt
open-webui 8081, [AI-Stack](ai-stack.md)).

## Beispiel: diese Doku

Diese Dokumentation ist selbst eine Portal-Site: die gebaute
mkdocs-Site liegt als statische Inhalte in einem KOSMOS-Space, das
Portal serviert den dazugehörigen Public-Link unter der
Sites-Domain. Deploy läuft per WebDAV
(README: `deploy_docs.sh`).
