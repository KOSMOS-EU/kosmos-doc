---
icon: octicons/workflow-24
---

# microllm

microllm ist der **LLM-Routing-Proxy** der Edition — und der
**einzige** LLM-Einstiegspunkt: alle Dienste (open_taki,
open-webui, open-aitool) sprechen microllm, nie ein Modell direkt.
Pure Passthrough, keine Format-Übersetzung. Repo:
`codeberg.org/Gemini-Foundation/microllm`
([Gemini Stiftung](https://codeberg.org/Gemini-Foundation)).

## Erreichbarkeit

| Pfad            | Zugriff                                    |
|-----------------|--------------------------------------------|
| `:8012`         | Pod-intern (alle Services)                 |
| `:8112`         | Extern über den Traefik-AI-Entrypoint, `ai.<SUPERDOMAIN>` |

## Alias-Gruppen und Loadbalancing

Mehrere Backends unter einem `model_name` bilden eine
**Alias-Gruppe** — automatisches Loadbalancing:

```yaml
- model_name: local-ocr
  litellm_params: { ..., api_base: "http://<gpu-1>:8011/v1" }
- model_name: local-ocr
  litellm_params: { ..., api_base: "http://<gpu-2>:8011/v1" }
```

- **Least-Connections**: das Backend mit den meisten freien Slots
  bekommt den nächsten Request. Semaphore pro Backend
  (Default 4 parallel, `max_concurrent` konfigurierbar); schnelle
  Backends geben Slots schneller frei und erhalten automatisch mehr
  Traffic.
- **Fallback** auf Round-Robin nur, wenn alle Backends unhealthy
  sind.

## Health

- 3 consecutive Failures → unhealthy (5-Minuten-Cooldown).
- Background-Health-Check alle 30 s auf unhealthy Backends.
- Discovery alle 10 min (Backend-Modelle + Aliases).

## Hot-Reload

Config ändern, dann:

```bash
curl -X POST http://<pod>:8012/reload    # oder kill -HUP <pid>
```

- Neue Backends werden **sofort** in die Alias-Gruppen eingefügt.
- Entfernte Backends werden erst nach **Drain** (keine in-flight
  Requests) entfernt.
- Semaphores, Stats und laufende Requests bleiben unberührt —
  kein Pod-Restart, keine Downtime
  ([Skalierung](../universum/skalierung.md#gpu-instanzen-fur-ki)).

## Endpoints

| Pfad              | Methode | Zweck                            |
|-------------------|---------|----------------------------------|
| `/health`         | GET     | Health-Check                     |
| `/v1/models`      | GET     | Routen + Backend-Status          |
| `/stats`          | GET     | Request-Statistiken, token/s, Queues |
| `/stats/reset`    | POST    | Stats zurücksetzen               |
| `/reload`         | POST    | Config-Hot-Reload                |
| `/svc/{name}/{path}` | *    | Service-Proxy                    |

## Standard-Aliase der Edition

| Alias         | Modell                                   | Nutzung            |
|---------------|------------------------------------------|--------------------|
| `local-ocr`   | lokales VLM (vLLM)                       | OCR, DocMeta       |
| `local-embed` | Qwen3-Embedding-0.6B (vLLM)              | Suche (Vektoren)   |
| `llm-stt`     | Whisper (vLLM)                           | Spracherkennung    |

Die GPU-Instanzen selbst laufen außerhalb des Pods; die
microllm-Config (Compose-Store, `volumes/microllm/config/`) ist die
einzige Stelle, an der Backends definiert werden. Das Image ist in
`[pin]` gepinnt ([Updates](../architektur/updates.md)).
