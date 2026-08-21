---
icon: octicons/shield-24
---

# Schutz

Geschützt heißt bei KOSMOS: **keine Dokumenteninhalte verlassen das
System**, die Netzwerkkanten sind per Default geschlossen, und alle
Modelle laufen lokal.

## Netzwerk: Default-Drop an der Bridge

Jedes Target hat eine eigene **nftables-Bridge-Firewall**. Eingehender
Traffic auf der Bridge wird per Default gedroppt; nur explizit
freigegebene Ports werden akzeptiert. Die Regeln werden aus der
Compose-Config generiert:

```ini
# compose.nuhost6.conf
[firewall]
ports = 80,443     # -> tcp dport { 80, 443 } accept
```

Die daraus generierte Chain (vereinfacht):

```nft
ct state established,related counter accept
icmp type echo-request counter accept
tcp dport { 80, 443 } ct state new counter accept
counter drop
```

- **Einzelfreigaben statt offener Ports**: jeder Port ist eine
  bewusste Decision in der Config und in `nu compose --diff` sichtbar.
- **Source-Restriktion**: sensible Ports (z. B. SSH) dürfen nur aus
  Management- und Provider-Netzen; interne Diagnose-Ports nur aus
  definierten Source-Netzen.
- **Atomarer Wechsel**: neue Firewall-Generationen werden unter
  `/run/nu-container-nftables/generations/` gebaut, mit `nft --check`
  validiert und über einen Symlink atomar freigeschaltet — kaputte
  Regeln nehmen das laufende System nicht mit.

Zusätzlich trennt die Topologie selbst: Management- und Service-Netz
laufen auf eigenen Bridges mit eigenen VLANs
([Netzwerk](../architektur/netzwerk.md)).

## Keine Inhalte nach außen

- **Modelle laufen lokal** — LLM, Embedding und Spracherkennung sind
  lokale GPU-Instanzen hinter [microllm](../dienste/microllm.md); der
  Dokumentenbestand verlässt das System nicht.
- **Keine externen APIs** für Dokumenteninhalte; die Edition arbeitet
  ohne Verbindung zur Außenwelt (Ausnahme: Updates).
- **CSP der Web UI** erlaubt nur Domains, die auf der Instanz
  tatsächlich laufen — keine eingebetteten Drittanbieter-Dienste.
- **Updates sind gepinnt**: nur bekannte, versionierte Images und
  Packages kommen ins System ([Updates](../architektur/updates.md)).

## Zugriffsschutz

| Zugang                 | Mechanik                                            |
|------------------------|-----------------------------------------------------|
| Nutzer-Session (Web)   | IDP: Login + Passwort → Bearer-Token                |
| App-Session (WebDAV)   | Login + Token; jedes Token hat Titel und Ablaufdatum |
| Worker                 | Login `worker` + individuelles Token pro Worker     |
| Public-Links (WebDAV)  | optional passwortgeschützt                          |
| SSH                    | nur aus Management-/Provider-Netzen (Firewall)      |

## Ein LLM-Einstiegspunkt

[microllm](../dienste/microllm.md) ist der **einzige** LLM-Einstiegspunkt
des Pods: alle Dienste sprechen die lokale Alias-Gruppe, nie ein Modell
direkt. Für den Inhalt heißt das: LLM-Kommunikation ist ein
dokumentierter, zentral beaufsichtigter interner Pfad — statt vieler
individueller Endpunkt-Verbindungen.
