---
icon: octicons/tag-24
---

# Classes

**Classes** ist der Kategorien-/Ansichten-Service der Edition:
dokumentbasierte Ansichten und Klassifizierungen, angedockt an den
Open Core. Repo: `opencloud_classes` (KOSMOS-EU).

## Aufbau

| Teil | Rolle |
|------|-------|
| `classes` (Service) | Backend: Categories, Views, Sharing — Port 9181 (Debug 9182) |
| `classes-web` (Extension) | UI in der Open-Core-Web, über `nu.packages` deployed |

## Anbindung an den Open Core

- **Machine-Auth**: Der Service läuft mit Machine-Auth-Key
  (`CLASSES_MACHINE_AUTH_KEY` = `machine_auth_api_key` aus
  `ocis.yaml`) und tauscht Tokens für Portal-Zugriffe
  (`CLASSES_GATEWAY_ADDR=opencloud:9142`).
- **Admin**: Admin-Token + Admin-Gruppe `Classes`; optional OIDC-
  Admin-Login über den Open-Cloud-IDP (Client `classes`).
- **CORS**: nur die Cloud-Domain der Instanz.
- **Sharing**: Public-Shares ohne Passwort erlaubt
  (`OC_SHARING_PUBLIC_SHARE_MUST_HAVE_PASSWORD=false`) — nötig für
  Classes-Links; Default-Share-Expiration 24 h.
- **CSP**: Die Classes-Domain wird in der CSP des Open Core
  freigegeben (`CLASSES_DOMAIN`).

## Daten

`/app/data` — persistenter Store (`[store]` `classes-data`),
snapshottbar wie alle Store-Volumes.

## Domains

`classes.<SUPERDOMAIN>` (aus der Superdomain abgeleitet,
[Netzwerk](../architektur/netzwerk.md)); Traefik-Routing auf
Port 9181.
