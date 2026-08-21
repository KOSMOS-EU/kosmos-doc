---
icon: octicons/server-24
---

# Architektur

KOSMOS ist **ein Pod auf einer VM**. Alle Dienste der Edition
teilen Lebenszyklus, Netzwerk-Namespace, Firewall und Backup-
Konzept. Das Fundament ist **nuhost6**: Container-Host-Management
für Debian 13 auf Podman-Quadlet-Basis, Dach-Kommando `nu`
([Universum](../universum/index.md)).

## Ein Pod

- Alle Container laufen im **Pod-Modus**: gemeinsamer
  Netzwerk-Namespace, Kommunikation über `localhost`, Servicenamen
  per `--add-host` aufgelöst statt geroutet.
- **Traefik** ist der einzige Service mit Ports nach außen
  (80/443, optional 8112 für den AI-Endpunkt).
- Große Daten-Volumes liegen auf btrfs unter
  `/nu/storage/<target>/`, kleine Config- und State-Daten unter
  `/nu/container/<target>/volumes/`.

## Target-Struktur

```
/nu/container/<target>/
  compose/          # Source of Truth (YAMLs, .env, nuhost6.conf)
  nu.pod            # Quadlet (generiert)
  nu.env            # Compose-Env für den ganzen Pod
  <member>.env      # Container-Env pro Member (generiert)
  nu.firewall.nft   # Bridge-Firewall (generiert)
  nas2.conf         # Backup-Config
  nu.packages       # Web-Extensions (versionierte ZIPs)
  volumes/<member>/ # Daten + Config + Packages
```

## Service-Map

| Service      | Rolle                                        | Port (Pod-intern) |
|--------------|----------------------------------------------|-------------------|
| traefik      | Reverse Proxy, TLS, Routen                   | 80, 443, 8112     |
| opencloud    | **Open Core**: Storage, Spaces, Web, IDP     | 9224 (Debug)      |
| tika         | open_taki: Dokumenten-Engine                 | 9998              |
| qdrant       | Vektor-Speicher (Embeddings)                 | 6333              |
| microllm     | LLM-Routing, Alias-Gruppen                   | 8012              |
| collabora    | Office-Rendering (WOPI)                      | 9980              |
| collaboration| Office-App-Provider im Open Core             | —                 |
| classes      | Classes-Service (Kategorien/Ansichten)       | —                 |
| portal       | Intranet: Public-Links als Sites             | —                 |
| radicale     | Kalender und Kontakte                        | —                 |
| open_webui   | Chat-UI (Option `with_ai`)                   | —                 |
| open_aitool  | Agent-Tool (Option `with_ai`)                | —                 |
| openyard     | Option `with_openyard`                       | —                 |

Eigene Targets (außerhalb des Pods): `searxng` (Meta-Suche) und
`openworks-worker` (JobEngine-Worker).

Jeder Service im Einzelnen: [Dienste](../dienste/index.md).

## Domains

Alle Domains werden aus der **Superdomain** abgeleitet
([Deployment](deployment.md)):

| Domain                     | Service                          |
|----------------------------|----------------------------------|
| `cloud.<SUPERDOMAIN>`      | Open Core (Web, WebDAV)          |
| `collabora.<SUPERDOMAIN>`  | Collabora Online                 |
| `wopiserver.<SUPERDOMAIN>` | WOPI-Server                      |
| `intranet.<SUPERDOMAIN>`   | Portal / Intranet                |
| `classes.<SUPERDOMAIN>`    | Classes-Service                  |
| `ai.<SUPERDOMAIN>`         | Open WebUI (`with_ai`)           |
| `cli.<SUPERDOMAIN>`        | AI-CLI (`with_ai`)               |

DNS wird vor dem Deployment konfiguriert; externes Routing
(öffentliche IP → VM) liegt außerhalb von nuhost6
([Netzwerk](netzwerk.md)).

## Pod- vs. Network-Modus

Standard ist `mode=pod` (alles auf `localhost`, einfach,
performant). `mode=network` isoliert Container über ein internes
DNS-Netzwerk mit Gateway-Service (Traefik) — nur nötig, wenn
Container-Isolation gewünscht ist. Details:
[Netzwerk](netzwerk.md#pod-vs-network-modus).
