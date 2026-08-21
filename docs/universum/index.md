---
icon: octicons/repo-24
---

# Das KOSMOS-Universum

KOSMOS ist ein **Universum von Diensten um einen zentralen Datenort**
herum. Der Datenort ist ein POSIX-Dateisystem in Spaces (Open Core);
alle anderen Dienste lesen, indexieren, verstehen oder veredeln —
aber keiner von ihnen *ist* der Datenbestand.

## Die Schichten

```
                    ┌─────────────────────────────────────────┐
                    │           KOSMOS-Universum              │
                    │                                         │
  Menschen ───────► │  Intranet · Web UI · AI-Frontends       │  (Zugang)
                    │  ─────────────────────────────────────  │
                    │  Suche (Bleve + Qdrant)                 │  (Verständnis)
                    │  open_taki (OCR, Metadaten, Chat)       │
                    │  AI-Stack (microllm → lokale Modelle)   │
                    │  ─────────────────────────────────────  │
                    │  Storage: Spaces auf btrfs              │  (Datenort)
                    │  xattrs = Wahrheit, Indexe = ableitbar  │
                    │  ─────────────────────────────────────  │
                    │  Betrieb: nuhost6, Snapshots, Backup    │  (Revision)
                    └─────────────────────────────────────────┘
```

## Warum ein Pod, keine Plattform-Landschaft

KOSMOS läuft als **ein Pod** auf **einer VM** (Podman-Quadlet,
verwaltet von [nuhost6](#betriebsfundament)). Die Konsequenzen:

- **Kein Fehlersuchen über Service-Grenzen** — alle Container teilen
  sich einen Netzwerk-Namespace; Kommunikation läuft über `localhost`,
  Servicenamen werden aufgelöst, nicht geroutet.
- **Ein Update-Zyklus** — `nu compose` ist der einzige Weg von Config
  zu lauffähigem System; kein Patchwork aus Dutzend Deployments.
- **Eine Firewall** — die Bridge-Firewall (nftables) des Pods definiert
  exakt, welche Ports von außen erreichbar sind. Default ist Drop.
- **Ein Backup-Konzept** — btrfs-Volumes des Targets werden gesnapshotet
  und nach NAS2 gesichert; Migration zwischen Nodes ist `nu migrate`.

## Betriebsfundament

Das Fundament ist **nuhost6**: ein Container-Host-Management für
Debian 13 mit Podman-Quadlet. Das Dach-Kommando `nu` deckt den
gesamten Lebenszyklus ab — Compose-Definitionen werden zu
Quadlets konvertiert (`nu compose`), Targets starten und stoppen,
Volumes werden gesnapshotet, VMs werden per `nu pmx` auf Proxmox
provisioniert.

Die Edition ist damit vollständig reproduzierbar: Jede
Kunden-Instanz entsteht aus denselben Compose-Templates, denselben
Pins und demselben Rollout-Skript — unterscheidbar nur durch eine
INI-Config mit Superdomain, Netzwerk und Optionen
([Deployment](../architektur/deployment.md)).

## Was KOSMOS nicht ist

- **Keine Microservice-Landschaft** — keine Dutzend Container mit
  eigenem API und eigenem CI; die Dienste des Pods haben eine gemeinsame
  Lebenszeit und ein gemeinsames Update-Verhalten. Der Dienst-Pool
  besitzt eine **Konvergenz**: Last und neue Funktionen werden in
  bestehende Schichten aufgenommen (Web-Apps, Worker, Modelle —
  [Skalierung](skalierung.md)), statt als neue Container. Der Pool
  wächst nicht endlos — und genau das hält die Wartungsqualität hoch.
- **Kein Kopie-Konzept** — die Dokumenten-Engine indexiert *auf* dem
  Dateisystem (xattrs); Inhalte werden nicht in eine eigene
  Datenhaltung kopiert. Eine Änderung am Original ist ohne Reindex
  die Wahrheit.
- **Keine externe Abhängigkeit** — Modelle laufen lokal; die Edition
  funktioniert ohne Verbindung zur Außenwelt (außer für Updates).
