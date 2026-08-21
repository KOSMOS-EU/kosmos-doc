---
icon: octicons/gear-24
---

# Worker

Die **openworks-JobEngine** ist der vertikale Skalierungshebel der
Edition: jede Verarbeitungstiefe (PDF/A, Extraktion, Build, …) ist
ein Worker, der Jobs aus der Queue pickt
([Skalierung](../universum/skalierung.md#vertikal-worker-der-jobengine)).

## JobEngine (im Open Core)

- Typisierte Jobs, initiiert aus der **UI** oder via `job.py`.
- **Worker-Matrix** (`/etc/opencloud/jobs/matrix.yaml`, schreibbar
  im Open-Core-Store): der Admin legt fest, welche Jobs welcher
  Worker bedienen darf.
- Ergebnisse laufen als **Events über NATS** zurück in die
  Plattform.

## Worker-Mechanik

1. Worker meldet sich mit individuellem Token an
   (Login `worker` + eigener Token) und registriert seine
   **Pipeline-Config** („ich kann `<pipeline>`").
2. Admin gibt in der Worker-Matrix die Jobs frei → aktive
   Pipeline.
3. Worker **pollt** die JobEngine und pickt sich Jobs.
4. Stirbt der Worker → Pipeline inaktiv; Jobs bleiben in der
   Queue. Mehrere Worker können dieselbe Pipeline bedienen.

## openworks-worker (Pod-angehörig)

Das Standard-Worker-Target (`<target>_worker`, separates Target
ohne Traefik) führt Dokumenten-Jobs aus:

| | |
|---|---|
| Image | `openworks-worker-cloud` (gepinnt) |
| Pipelines (`OPENWORKS_PICK`) | `md-to-pdf`, `zip-create`, `unzip`, `tar-extract`, `doc-to-pdf`, `test-echo` |
| Kapazität | `OPENWORKS_CAPACITY=2` (parallel Jobs) |
| UI | Web-Extension `openworks-web` |

## Weitere Worker (andere Targets/Maschinen)

Die JobEngine ist maschinen-agnostisch — Worker dürfen auf
anderen Maschinen laufen (z. B. ein Build-Server):

| Worker | Pipeline |
|--------|----------|
| `openworks-worker-ai-tax` | Kontoauszugs-Extraktion (KI) |
| `openworks-worker-pdfa` | PDF/A-Konvertierung |
| `openworks-xis-oracle` | XIS-Oracle |
| `openworks-worker-build` | Builds (pod + web) |
| `openworks-worker-cloud` | Cloud-Jobs |

Jeder Worker hat **eigenes Token, eigenes Target, eigene
Lebenszeit** — die Kern-Plattform bleibt unverändert.
