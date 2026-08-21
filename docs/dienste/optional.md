---
icon: octicons/circle-slash-24
---

# Optionale Dienste

Diese Services sind im Standard-Rollout **exkludiert**
(`[services.exclude]` in der `compose.nuhost6.conf`) und werden
einzelaktiviert, wenn die Instanz sie braucht. Aktivierung =
Exklusion entfernen + die Service-YAML im Compose-Dir vorhanden +
`nu compose --diff` → `--auto-apply`.

## Authentifizierung

| Service | Zweck |
|---------|-------|
| **keycloak** | Externer IDP statt eingebautem IDP: OIDC-Realm, Rolle-Assignment über `oidc`-Driver |
| **keycloak-autoprovisioning** | Keycloak-Variante mit Auto-Provisioning: Nutzer/Gruppen werden aus Keycloak angelegt (`sub`-Claim als Username, stabil bei Umbenennungen) |
| **ldap-server** | LDAP-Authentifizierung für den Open Core (`ldaps://ldap-server:1636`, Groups/EntryUUID) |
| **postgres** | Datenbank-Backend (z. B. für Keycloak) |

## Storage

| Service | Zweck |
|---------|-------|
| **decomposed** | Alternativer Storage-Driver (`STORAGE_USERS_DRIVER=decomposed`) |
| **decomposeds3** | Storage auf S3-Objektspeicher (z. B. Minio); Systemdaten bleiben auf dem Open-Core-Storage |
| **minio** | S3-Objektspeicher (Console auf 9001) für `decomposeds3` |

## Betrieb

| Service | Zweck |
|---------|-------|
| **clamav** | Virenscan: ClamAV-Socket, Postprocessing-Step `virusscan`, Scan-Größenlimit (Default 100 MB, `partial`) |
| **inbucket** | Mail-Catcher für Benachrichtigungen (SMTP 2500) — Test/Demo ohne externen Mailserver |
| **superdomain-redirect** | Weiterleitung `<SUPERDOMAIN>` → `cloud.<SUPERDOMAIN>` (Path/Query erhalten, permanent) |
| **debug-opencloud** | Debug-Variante des Open-Core-Containers (Troubleshooting) |
| **debug-collaboration-collabora** | Debug-Variante: Collaboration gegen Collabora |
| **debug-collaboration-onlyoffice** | Debug-Variante: Collaboration gegen OnlyOffice |

## Aktivierungsmuster

```ini
# compose.nuhost6.conf — Eintrag entfernen:
# [services.exclude]
# keycloak =            <- raus
```

Danach wie jede andere Compose-Änderung: `--diff` prüfen,
`--auto-apply`, betroffene Container restarten
([Updates](../architektur/updates.md)). Bei neuen Volumes:
`[storage]`/`[store]` deklarieren, bei Firewall-relevanten
Services: Ports im `[firewall]`-Block.
