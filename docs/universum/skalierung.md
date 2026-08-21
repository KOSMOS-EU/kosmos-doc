---
icon: octicons/rocket-24
---

# Skalierung

KOSMOS skaliert **digitale Prozesse** — nicht die Anzahl der
Container. Die beiden Achsen laufen durch Schichten, die dafür gebaut
sind:

- **Horizontal mit Web-Apps** — der Prozess erstreckt sich über
  weitere Oberflächen und Systeme.
- **Vertikal über Worker der JobEngine** — der Prozess bekommt
  weitere Bearbeitungstiefen: mehr Verarbeitungsschritte pro Dokument.

Beides wächst **ohne neue Container im Pod**. Der Dienst-Pool besitzt
eine **Konvergenz**: Er wächst nicht endlos mit der Last, und genau
das erhöht die Wartungsqualität — ein Update-Zyklus, eine Firewall,
ein Backup-Konzept
([Warum ein Pod](index.md#warum-ein-pod-keine-plattform-landschaft)).

## Horizontal: Web-Apps

Der Datenort ist über Standard-Schnittstellen erreichbar —
**WebDAV**, **Public-Links**, Web UI. Daraus wächst der Prozess nach
neben:

- **Web-Extensions** erweitern die Open-Core-UI um Ansichten und
  Funktionen (FolderViews, HTML-Viewer, Classes, openworks, …) —
  versionierte ZIPs, deren Deployment ein Package-Pin in
  `nu.packages` plus `nu compose --auto-apply` ist
  ([Updates](../architektur/updates.md)).
- **Portal (Intranet)** serviert Public-Links als Webseiten —
  Dokumente werden Inhalte für andere Oberflächen. Diese Doku selbst
  ist so ein Public-Link im KOSMOS-Space.
- **Externe Web-Apps** greifen über WebDAV und Public-Links auf den
  Bestand zu; die Web UI erlaubt per CSP nur Domains, die auf der
  Instanz tatsächlich laufen.

Neue Web-App = horizontale Prozess-Erstreckung: mehr Systeme,
gleicher Datenort, gleicher Pod.

## Vertikal: Worker der JobEngine

Die Bearbeitungstiefe eines Dokuments wächst über die
**openworks-JobEngine**:

- **Typisierte Jobs**: Worker melden sich mit individuellem Token
  und eigener Pipeline-Config an („ich kann `pdfa`", „ich kann
  `ai-tax`") und picken sich Jobs aus der Queue.
- **Jeder Worker ist eine Bearbeitungstiefe** — z. B. PDF/A-
  Konvertierung, Kontoauszugs-Extraktion, XIS-Oracle. Eine neue
  Tiefe ist ein neues Worker-Image plus Pipeline — keine Änderung
  am Kern.
- **Freigabe durch den Admin**: In der Worker-Matrix wird festgelegt,
  welche Jobs ein Worker bedienen darf. Stirbt ein Worker, wird die
  Pipeline inaktiv; Jobs bleiben in der Queue.
- Ergebnisse laufen als Events zurück in die Plattform
  ([Worker](../dienste/worker.md)).

Mehr Tiefe pro Dokument = weitere Worker-Stufen — die vertikale
Achse. Der Pod bleibt unverändert; Worker dürfen auch auf anderen
Maschinen laufen.

## Die Infrastruktur folgt der Last

Die Pod-Infrastruktur skaliert nach, ohne dass sich das Konzept
ändert:

### Größere VM

Die Edition läuft als ein Pod auf einer VM — Sizing bedeutet, die VM
zu dimensionieren, nicht Dutzend Services abzustimmen. Die Parameter
stehen in der Instanz-Config
([Deployment](../architektur/deployment.md)):

```ini
[pmx]
memory = 8192        # MB
cores = 4
disk_size = 64G
```

Werte lassen sich beim Rollout per CLI überschreiben
(`--memory 16384 --cores 8`); `nu pmx disk add` ergänzt Datenträger.
Speichermächtige Services (Open Core mit Suchindex) werden per
`GOMEMLIMIT` begrenzt.

### Weitere Nodes

Alle Nodes eines Standorts haben **identische Bridges und
Podman-Netzwerke** — gleiche IP-Schemata, gleiche VLANs:

```bash
nu migrate <target> <node>      # Stop + Sync + Enable + Start
nu failover-activate <node>     # Node als primär aktivieren
nu sync                         # Config-Sync zwischen Nodes
nu snapshot-send <target> <snap> <node>   # Daten auf neuen Node ziehen
```

Ein Pod wechselt den Node **mit gleicher IP** — DNS, Zertifikate und
Firewall-Regeln bleiben gültig.

### GPU-Instanzen für KI

Die KI-Rechenlast ist vom Datenort **entskoppelt**: GPU-Instanzen
(vLLM) laufen außerhalb des Pods,
[microllm](../dienste/microllm.md) verteilt dorthin. Mehrere
Backends unter einem Modellnamen bilden eine **Alias-Gruppe** mit
automatischem Loadbalancing (Least-Connections). Eine GPU
dazuschalten ist ein Eintrag in der microllm-Config plus
`POST /reload` — Hot-Reload, kein Pod-Restart. Gleiches Muster für
Embedding (`local-embed`) und Spracherkennung (`llm-stt`).

Der Datenort bleibt dabei eindeutig am Storage-Node (Prinzip:
**kein Kopie-Konzept**). Wächst der Dateibaum, läuft das über
Node-Migration auf Storage mit mehr Platz — nicht über Replikation.
