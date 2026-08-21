---
icon: octicons/database-24
---

# Open Core

**Open Core** ist die Kernplattform der Edition: ein auf ownCloud
Infinite Scale basierender, deutlich aufgerüsteter Open-Cloud-
Unterbau — Storage, Spaces, Web UI, IDP und die Anbindung aller
weiteren Dienste (Open Cosmos Stack).

> **Namen**: Die Repos der Plattform tragen noch den Namen
> `opencloud` (KOSMOS-Edition, Branch `kosmos`); der Manifest-Name
> lautet „OpenCloud KOSMOS Edition".

## Was Open Core ist

- **Zentraler Datenort**: POSIX-Dateisystem auf btrfs, organisiert in
  **Spaces**. Metadaten (Typ, Tags, Favoriten, Extraktion) liegen als
  **xattrs direkt auf den Dateien** — die Quelle der Wahrheit;
  Indexe sind ableitbar
  ([Revisionssicherheit](../universum/revisionssicherheit.md)).
- **Zugänge**: Web UI, **WebDAV**, Public-Links, REST/CS3.
  Externe Web-Apps hängen sich über diese Standard-Schnittstellen an
  ([Skalierung](../universum/skalierung.md#horizontal-web-apps)).
- **IDP (eingebaut)**:
  - Nutzer-Session: Login + Passwort → Bearer-Token
  - App-Session/WebDAV: Login + Token — jedes Token hat Titel und
    Ablaufdatum; Worker melden sich als `worker` mit individuellem
    Token an
  - Machine-Auth für Services (z. B. Classes)
- **JobEngine** (openworks): typisierte Jobs, Worker-Matrix
  (`matrix.yaml`), Ergebnisse als Events über NATS
  ([Worker](worker.md)).
- **Storage-Resilienz**: Read-only-Fallback für btrfs-Snapshots und
  ISO-Mounts; Filesystem-Scan aktiv (`STORAGE_USERS_POSIX_SCAN_FS`).

## Im Pod

| Schnittstelle        | Adresse (Pod-intern)     |
|----------------------|--------------------------|
| HTTP (via Traefik)   | 9200                     |
| Gateway gRPC         | 0.0.0.0:9142             |
| NATS / Micro-Registry| 9233                     |
| Debug                | 9224                     |

- Daten: `/var/lib/opencloud` (btrfs, `[storage]`)
- Config: `/etc/opencloud` (schreibbar, `[store]` — u. a. für die
  Worker-Matrix)
- Init: `opencloud init` (einmalig, generiert Config mit Secrets)

## Suche

Der Open Core delegiert die Inhalts-Extraktion an
[open_taki](open_taki.md) und die Vektoren an
[Qdrant](suche.md):

```
SEARCH_EXTRACTOR_TYPE=tika          → http://tika:9998
SEARCH_VECTOR_ENABLED=true          → http://qdrant:6333
SEARCH_VECTOR_COLLECTION=opencloud
FRONTEND_FULL_TEXT_SEARCH_ENABLED=true
```

Details: [Suche](suche.md).

## Web-Extensions

Die UI wird über **versionierte ZIP-Packages** (`nu.packages`)
erweitert — Deployment ohne Server-Änderung:

| Extension        | Zweck                          |
|------------------|--------------------------------|
| folderviews      | Ordner-Ansichten               |
| htmlviewer       | HTML-Ansicht                   |
| mdm-editor       | Markdown-Editor                |
| classes          | Classes-UI                     |
| openworks        | JobEngine-UI                   |
| draw-io          | Diagramme                      |
| external-sites   | Externe Sites in der UI        |
| json-viewer      | JSON-Ansicht                   |
| mermaid-editor   | Mermaid-Diagramme              |
| posteingang      | Posteingang-Ansicht            |

Die **CSP** der Web UI erlaubt nur Domains, die auf der Instanz
tatsächlich laufen (CSP-Config mit Platzholdern, keine
hardcodeden Domains) — siehe [Schutz](../universum/schutz.md).
