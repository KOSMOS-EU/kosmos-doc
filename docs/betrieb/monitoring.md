---
icon: octicons/pulse-24
---

# Monitoring

KOSMOS hat keine zentrale APM-Landschaft — sondern **kurze,
typisierte Status-Endpunkte** pro Subsystem. Die Regel: erst
fragen, dann graben.

## Pod-Status (nuhost6)

```bash
nu status              # RAM, Targets, Storage-Übersicht
nu ps                  # laufende Targets mit Node + IP
nu images              # Image-Versionen aller Targets
nu logs <target> -f    # journalctl über alle Pod-Member
nu volumes             # btrfs-Volumes + Snapshots
```

## Suche (Open Core)

| Check | Befehl | Gesund |
|-------|--------|--------|
| Queue-Status | `curl -s http://localhost:9224/index-status` | `pending` niedrig, `processed` wächst |
| Index-lookup | `curl -s "http://localhost:9224/index-lookup?q=name:*test*&limit=5"` | Treffer |
| Bleve-Segmente | `ls .../search-v2/bleve/store/*.zap \| wc -l` | 5–30 |
| Merge-Spin | `podman top systemd-<target>-opencloud -eo pid,pcpu,rss` | keine Dauer-CPU |

Segment-Anzahl ist der wichtigste Frühindikator:
**> 200 = kritisch** (der Scorch-Introducer pausiert dann;
davor liegt der Sweet-Spot) —
[Troubleshooting](troubleshooting.md#bleve-segment-problem-write-block).

## open_taki (Dokumenten-Engine)

```bash
curl -s http://<pod>:9998/test
```

Zeigt: Queue (in_flight / max / oldest_seconds), Subsysteme
(llm, embedding, whisper, collabora, docmeta), Backend-Health und
die Modell-Versionen. `oldest_seconds` in der Queue ist das
Signal für Engpässe (zu wenig GPU-Kapazität →
Alias-Gruppe vergrößern, [Skalierung](../universum/skalierung.md#gpu-instanzen-fur-ki)).

## microllm (LLM-Routing)

| Endpoint | Bedeutung |
|----------|-----------|
| `GET /health` | Gesamt-Health |
| `GET /v1/models` | Routen + Backend-Status (wer ist in welcher Alias-Gruppe, healthy?) |
| `GET /stats` | Request-Statistiken, **token/s**, Queues |
| `GET /stats` nach `POST /stats/reset` | belastbares Zeitfenster messen |

`/stats` ist das Instrument, um zu sehen, ob eine GPU-Instanz
wirklich Last trägt (Loadbalancing wirkt).

## NATS / Events

```bash
# Jetstream-Größe
du -sh /nu/storage/<target>/opencloud/nats/jetstream/
```

Der Purge-Monitor warnt bei > 10 000 pending Events. Wachsendes
Jetstream bei ruhiger Instanz = Consumer hängt hinterher —
[Troubleshooting](troubleshooting.md#nats-jetstream-uberlaufen).

## doUpsertItem-Phasen

Jede Enrich-Operation loggt mit op-ID jede Phase:

```
doUpsertItem: start            op=42  name=X.pdf
doUpsertItem: stat ok           op=42  stat_ms=5ms
doUpsertItem: extract ok        op=42  content_len=13171  extract_ms=41000ms
doUpsertItem: bleve upsert starting  op=42
doUpsertItem: bleve upsert ok   op=42  bleve_ms=12ms
doUpsertItem: taki v2 complete  op=42  method=pdftotext  dims=1024
doUpsertItem: qdrant upsert ok  op=42  qdrant_ms=5ms
doUpsertItem: done              op=42  total_ms=41200ms
```

`bleve upsert starting` **ohne** `ok`/`failed` = Bleve blockiert.
