---
icon: octicons/search-24
---

# Suche

Zwei Engines, getrennte Zuständigkeiten:

| Engine  | Sucht                                  | Geschwindigkeit |
|---------|----------------------------------------|-----------------|
| **Bleve** | Metadaten, Tags, Favoriten, Volltext | Sekunden        |
| **Qdrant** | semantisch (Embeddings)               | abh. von VLM    |

Indexierung über [open_taki](open_taki.md) und die lokalen Modelle
(Embedding: Qwen3-Embedding-0.6B, 1024 dim, 8192 Token,
multilingual — Alias `local-embed` über
[microllm](microllm.md)).

## Dual-Queue-Architektur

Alle Writes laufen durch zwei serialisierte Queues — kein direkter
Bleve-Write außerhalb der Queues:

```
Upload-Event → Debouncer → IndexSpace → doFastIndex (Bleve, sofort)
             → Enrich-Queue → doUpsertItem (Taki + Qdrant + Bleve, deferred)

Tag/Favorit  → Debouncer → IndexSpace → doFastIndex (nur Bleve)
UI-Reindex   → Enrich-Queue (priority=high)
CLI-rescan   → Enrich-Queue (priority=low)
```

- **Index-Queue**: 1 Worker, Bleve-only, Metadaten — macht Dateien
  sofort suchbar.
- **Enrich-Queue**: 1 Worker, open_taki + xattrs + Qdrant + Bleve
  (mit Content) — die tiefe Verarbeitung.
- **Scorch-Patch**: der Bleve-Introducer pausiert bei > 200
  Segmenten (Schutz vor Segment-Explosion).

Queue-Status (Debug-Port 9224):

```bash
curl -s http://localhost:9224/index-status
# {"doc_count": 38440,
#  "index_queue":  {"pending": 0, "max": 1000, "processed": 42},
#  "enrich_queue": {"pending": 121, "max": 1000, "processed": 8}}
```

## Re-Index

Index und Re-Enrich sind **getrennte** Befehle:

```bash
# Bleve-Index aus xattrs/Metadaten (Sekunden)
opencloud search index --all-spaces --insecure

# Re-Enrich: open_taki/LLM → xattrs + Qdrant (Stunden)
# überspringt Dateien, die schon doc.type haben
opencloud search re-enrich --all-spaces --insecure

# --force-rescan: auch Dateien mit doc.type neu verarbeiten
# --force-overwrite: ALLE Metadaten überschreiben (destruktiv!)
```

Nur ein Indexlauf gleichzeitig; bei Hänger: Container restarten,
erneut triggern. Details:
[Troubleshooting](../betrieb/troubleshooting.md).

## UI-Suche (WebDAV REPORT)

Die UI sendet die Suche als `REPORT` an `/dav/spaces`; das Pattern
wird 1:1 an Bleve weitergegeben:

```xml
<oc:search>
  <oc:pattern>name:"*11.12*" scope:<space-uuid>$<drive-uuid></oc:pattern>
  <oc:limit>8</oc:limit>
</oc:search>
```

`scope:` schränkt auf einen Space ein; die Favoriten-Ansicht sendet
`is:favorite`.

## Qdrant

- Collection `opencloud`, 1024 Dimensionen, Cosine-Distanz.
- Keine Auth (nur Pod-intern erreichbar).
- **Trennt nicht nach Space** — Space-Delete räumt nicht automatisch
  auf; nach Dimensionsänderung: Collection drop + `--force-rescan`.

## Debug

```bash
# Index-lookup (z. B. Name-Muster oder Favoriten)
curl -s "http://localhost:9224/index-lookup?q=name:*11.12*&limit=5"

# doUpsertItem loggt jede Phase mit op-ID:
# stat → extract → bleve upsert → taki v2 → qdrant upsert → metadata
```

`bleve upsert starting` ohne `ok`/`failed` = Bleve blockiert
(Segmente) — [Troubleshooting](../betrieb/troubleshooting.md).
