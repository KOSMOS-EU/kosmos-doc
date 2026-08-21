---
icon: octicons/file-24
---

# open_taki

open_taki ist die **Dokumenten-Engine** der Edition: ein
Tika-kompatibler Auswertungsdienst, der Content-Extraktion, OCR und
Metadaten-Verständnis über lokale Vision-Modelle macht. Im Pod heißt
der Service `tika` (Port 9998) — der Name kommt von der
Schnittstelle, die er erfüllt.

## Was es macht

- **Content-Extraktion** — Text aus Dokumenten (PDF, Office, …);
  der Open-Core-Index ruft den Service als Tika-Extractor auf
  (`SEARCH_EXTRACTOR_TYPE=tika`).
- **OCR mit Vision-Modell** — gescannte Seiten und Bilder werden
  über das lokale VLM gelesen (Alias `local-ocr`).
- **DocMeta** — strukturierte Metadaten pro Dokument per
  guided-JSON: Dokumenttyp (26-Typen-Enum, z. B. Rechnung,
  Bescheid, Vertrag), Absender, Empfänger, Beträge. Die
  Extraktion läuft typ-spezifisch über den Vision-Prompt; ein
  textbasierter Rescue-Pass fängt, was das VLM nicht liefert.
- **Embeddings** — Vektoren für die semantische Suche (Alias
  `local-embed`).
- **Dokumenten-Chat** — `/chat/ask` beantwortet Fragen über einen
  Ordner: Tool-Loop (Dateien lesen, suchen) über einen ephemeralen
  Public-Link-Share — der Chat bekommt keinen direkten
  Dateisystemzugriff.

## Integration

- Der Open Core ruft open_taki aus der **Enrich-Queue** der
  [Suche](suche.md) auf; Ergebnisse landen als xattrs auf dem
  Dateisystem (die Wahrheit) und als Embeddings in Qdrant.
- **Alle LLM-Zugriffe laufen über
  [microllm](microllm.md)** — open_taki kennt nur lokale
  Alias-Namen, nie Modell-URLs.
- Modell-Versionen werden mitgeführt (`docmeta.model_version` in
  Config, Response und Health); bei Timeout oder Überlast gibt es
  Retry mit Backoff (3 Versuche).

## Betrieb

- Konfiguration: `/etc/open_taki.yaml` (Compose-Config, ro
  gemountet); Arbeitsdaten unter `/data/takiwork` (btrfs-Volume
  `taki-trace`); Prompts als eigenes Volume.
- Health/Status: `GET /test` — Queue (in_flight/max/oldest),
  Subsysteme (llm, embedding, whisper, collabora, docmeta) und
  Backend-Health.

## Weitere Dokumentation

In der F13-Programmlinie ist die Engine als *F17 Engine*
versioniert — [f17-Dokumentation](https://gitlab.opencode.de/kosmos/f17).
