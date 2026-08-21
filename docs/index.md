---
icon: octicons/cloud-24
---

# KOSMOS

**KOSMOS ist der zentrale, revisionssichere und geschützte Datenort, der
digitale Prozesse vertikal und horizontal skaliert.**

Kern der Edition ist **Open Core**: ein auf ownCloud Infinite Scale
basierender, deutlich aufgerüsteter Open-Cloud-Unterbau mit dem
**Open Cosmos Stack** aufgesetzt — Suche, Dokumenten-Verständnis, KI
und Collaboration. Die Repos tragen noch den Namen `opencloud`
(KOSMOS-Edition).

KOSMOS ist damit eine vollständige Digitallandschaft für die
Verwaltung, die auf einer einzigen VM läuft — als ein Container-Pod,
in dem Speicher, Suche, Dokumenten-Verständnis, KI, Collaboration und
Betrieb zusammenarbeiten.

Projektseite: [https://kosmos.technology/](https://kosmos.technology/)

## Die Idee

Verwaltung läuft auf Prozessen: Dokumente kommen an, werden verstanden,
klassifiziert, abgelegt, gesucht, bearbeitet, versichert und gehen
wieder raus. KOSMOS bündelt alle Schichten dieses Prozesses an einem
Ort:

- **Zentraler Datenort** — alle Inhalte liegen in Spaces auf einem
  POSIX-Dateisystem. Der Speicher ist die Quelle der Wahrheit; alle
  Indizes sind davon ableitbar.
- **Revisionssicher** — Snapshots, Backup und nachvollziehbare
  Deployment-Configs: jeder Zustand des Systems ist wiederherstellbar
  und jede Änderung dokumentiert.
- **Geschützt** — Bridge-Firewall pro Pod, lokale Modelle, keine
  Dokumenteninhalte nach außen.
- **Skalierend** — horizontal über Web-Apps, vertikal über Worker
  der JobEngine; die Infrastruktur (VM, Nodes, GPU) folgt der Last.

## Aufbau dieser Doku

| Abschnitt | Inhalt |
|---|---|
| [Universum](universum/index.md) | Was KOSMOS ist: Revisionssicherheit, Schutz, Skalierung |
| [Architektur](architektur/index.md) | Pod, Netzwerk, Deployment, Updates |
| [Dienste](dienste/index.md) | Jeder Dienst der Edition im Einzelnen |
| [Betrieb](betrieb/monitoring.md) | Monitoring, Backup, Troubleshooting |

## Grundprinzipien

- **Souveränität** — Betrieb auf eigener Infrastruktur; alle Modelle
  lokal (vLLM), kein Content-Abfluss.
- **Modell-Agnostik** — jeder OpenAI-kompatible Endpunkt; das Routing
  ([microllm](dienste/microllm.md)) verteilt über die Instanzen.
- **Open Source** — Plattform, Dienste und Tooling in eigenen Repos.
- **Praxisgeführt** — Anforderungen aus dem laufenden Betrieb der
  Kommunen, nicht aus Anforderungsanalysen.
