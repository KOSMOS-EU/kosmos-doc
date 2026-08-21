# KOSMOS — Gesamtdokumentation

Gesamtdokumentation der **KOSMOS Edition (Open Core)** — des
zentralen, revisionssicheren und geschützten Datenorts, der digitale
Prozesse vertikal und horizontal skaliert.

**Open Core** = auf ownCloud Infinite Scale basierender, deutlich
aufgerüsteter Open-Cloud-Unterbau mit **Open Cosmos Stack** aufgesetzt
(Suche, Dokumenten-Verständnis, KI, Collaboration). Die Repos tragen
noch den Namen `opencloud` (KOSMOS-Edition).

Projektseite: [https://kosmos.technology/](https://kosmos.technology/)

## Inhalt

Die Doku deckt die Edition als Ganzes ab:

- **Universum** — was KOSMOS ist: Revisionssicherheit, Schutz, Skalierung
- **Architektur** — Pod, Netzwerk, Deployment, Updates
- **Dienste** — jeder Dienst der Edition (open core, open_taki, microllm,
  AI-Stack, Collaboration, Classes, Intranet, Kalender, SearXNG, Scanner,
  Worker, optionale Dienste)
- **Betrieb** — Monitoring, Backup, Troubleshooting

## Bauen (lokal)

```bash
python3 -m venv .venv
.venv/bin/pip install mkdocs-material
.venv/bin/mkdocs build --strict     # -> site/
.venv/bin/mkdocs serve --strict     # Dev-Server auf 127.0.0.1:8000
```

## Bauen (Build-Worker)

Die Doku wird als **OC-Package** gebaut: Der Web-Build-Worker der
JobEngine klonet das Repo, führt `build_web.sh` (mkdocs → `dist/`) und
`push_zip.sh` (ZIP → GitHub Release `pkg-<TAG>`) aus.

```bash
cd kosmos-doc
../kosmos-nuhost-deploy/job.py build-web
```

Konfiguration in der (gitignoreden) `DIST`:

```bash
REPO=kosmos-doc
BRANCH=main
GIT_BASE=https://github.com/KOSMOS-EU
PACKAGE_NAME=kosmos-doc-web
PUSH_REGISTRY=github
PUSH_ORG=KOSMOS-EU
PUSH_TOKEN=...
```

## Deploy (WebDAV → KOSMOS-Space)

Die gebaute Doku wird als statische Site in den **KOSMOS-Space** auf
`cloud.brandis.eu` per WebDAV deployt. `deploy_docs.sh` nimmt den
WebDAV-Link aus der Intranet-Config (`portal-sites.yaml`) des Pods:

```bash
./deploy_docs.sh                      # lokale dist/
./deploy_docs.sh pkg-20260820-1607    # bestimmtes Package
```

## Quellen

| Komponente | Repository |
|---|---|
| KOSMOS Plattform (Open Core; Repos: OpenCloud-Forks) | [KOSMOS-OpenCloud](https://github.com/KOSMOS-OpenCloud) |
| Dokumente (open_taki) | [KOSMOS-EU/opentaki](https://github.com/KOSMOS-EU/opentaki) |
| Routing (microllm) | [Gemini-Foundation/microllm](https://codeberg.org/Gemini-Foundation/microllm) |
| F13-Programmlinie | [f13](https://gitlab.opencode.de/groups/f13) |

## Lizenz

Die Dokumentation ist lizenziert unter [CC-BY-SA-4.0](LICENSE.md).
