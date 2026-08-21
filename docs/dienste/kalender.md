---
icon: octicons/calendar-24
---

# Kalender

**radicale** ist der Kalender- und Kontakte-Service der Edition
(CalDAV/CardDAV).

## Aufbau

| | |
|---|---|
| Image | `opencloudeu/radicale` |
| Config | `config/radicale/config` (Compose-Dir, ro) |
| Daten | `/var/lib/radicale` (`[store]`) |
| Pod-Integriert | ja (Standard-Rollout) |

## Zugang

Radicale spricht die Zugangsmodelle des Open Core mit:

- **Nutzer**: Login + Passwort über den IDP bzw. direkt.
- **Apps/Worker**: Login + **App-Token** (Titel + Ablaufdatum) —
  z. B. für Sync-Clienten oder Worker, die Termine anlegen.

Die CalDAV-/CardDAV-Endpunkte laufen pod-intern; ob und wie sie
extern geroutet werden (Domain, Firewall-Port), ist eine
Instanz-Decision im Compose-Dir
([Netzwerk](../architektur/netzwerk.md),
[Updates](../architektur/updates.md)).

## Optional: inbucket

Für Benachrichtigungs-Mails ohne externen Mailserver dient
**inbucket** als Mail-Catcher (SMTP 2500) — im Standard
exkludiert, für Test-Instanzen praktisch
([Optionale Dienste](optional.md)).
