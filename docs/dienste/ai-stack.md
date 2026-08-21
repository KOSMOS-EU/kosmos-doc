---
icon: octicons/cpu-24
---

# AI-Stack

Der AI-Stack ist die **KI-Oberfläche** der Edition. Aktiviert per
Instanz-Option ([Deployment](../architektur/deployment.md)):

| Option            | Services                            |
|-------------------|-------------------------------------|
| `with_ai`         | open-webui + open-aitool            |
| `with_openyard`   | openyard (DMS-Microservice)         |

Alle KI-Komponenten sprechen ausschließlich
[microllm](microllm.md) — nie ein Modell direkt
([Schutz](../universum/schutz.md)).

## Open WebUI (`ai.<SUPERDOMAIN>`)

Chat-UI über die lokalen Modelle.

- **LLM-Backend**: `http://microllm:8012/v1` (OpenAI-kompatibel).
- **Spracheingabe**: Whisper über microllm (`llm-stt`, Modell
  `whisper-large-v3`).
- **Login**: nur über den Open-Cloud-IDP (OIDC) — lokale
  Registrierung und Login-Formular sind deaktiviert; Gruppen- und
  Rollenmanagement laufen optional über OpenCloud-Claims.
- **Telemetrie**: komplett aus (`SCARF_NO_ANALYTICS`,
  `DO_NOT_TRACK`, `ANONYMIZED_TELEMETRY=false`).
- Port 8081 (8080 ist im Pod-Modus das Portal), Daten in
  `/app/backend/data` (`[store]`).
- Bildet mit [SearXNG](searxng.md) die Websuche-Grundlage für
  Agent-Funktionen.

## Open AI Tool / CloudCLI (`cli.<SUPERDOMAIN>`)

Agent-CLI im Browser (Claude-Code-artige Oberfläche) für
Dokumenten- und Prozess-Aufgaben.

- **LLM-Backend**: microllm als **Anthropic-kompatibler Endpunkt**
  (`ANTHROPIC_BASE_URL=http://microllm:8012`).
- **Workspaces**: persistentes Volume `/home/agent`
  (`[store]` `aitool-workspaces`).
- **Login**: OIDC über den Open-Cloud-IDP (Client `cloudcli`),
  Login-Formular aus.
- Context-Window konfigurierbar (Default 160000).
- Port 3001.

## OpenYard (`with_openyard`)

DMS-Microservice (Dokumenten-Workflow), Port 9201 — ein
**restricted Port** in der Bridge-Firewall (nur definierte
Source-Netze, [Schutz](../universum/schutz.md)).

## Modelle dahinter

Alle drei Frontends konsumieren dieselben Alias-Gruppen:
`local-ocr` (Vision/OCR), `local-embed` (Embedding), `llm-stt`
(Whisper) — hinterlegt auf lokalen GPU-Instanzen
([Skalierung](../universum/skalierung.md#gpu-instanzen-fur-ki)).
