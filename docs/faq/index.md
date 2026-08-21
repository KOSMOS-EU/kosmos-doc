---
icon: octicons/question-24
---

# FAQ

## Warum ein Pod und keine Microservice-Landschaft?

Ein Pod = ein Netzwerk-Namespace, ein Update-Zyklus, eine
Firewall, ein Backup-Konzept. Fehlersuchen über Service-Grenzen,
Dutzend CIs und Deployment-Patchwork fallen weg. Der Dienst-Pool
hat eine **Konvergenz**: er wächst nicht mit der Last — Last und
neue Funktionen laufen über Web-Apps, Worker und Modelle
([Skalierung](../universum/skalierung.md)).

## Wo liegen eigentlich die Dokumente?

Im POSIX-Dateibaum des Open Core (btrfs, Spaces). Metadaten sind
**xattrs auf den Dateien** — die Quelle der Wahrheit. Bleve-Index
und Qdrant-Vektoren sind **ableitbar**: im Schadensfall wird
gelöscht und neu aufgebaut, nicht aus einer Kopie wiederhergestellt.

## Funktioniert die Edition ohne Internet?

Ja (außer Updates). Alle Modelle laufen lokal (GPU-Instanzen,
vLLM), das LLM-Routing ist
[microllm](../dienste/microllm.md). Keine Dokumenteninhalte
verlassen das System
([Schutz](../universum/schutz.md)).

## Welche KI-Modelle laufen in der Edition?

Das ist bewusst **modell-agnostisch**: microllm akzeptiert jeden
OpenAI-kompatiblen Endpunkt. Standard sind lokale Modelle —
Vision/OCR (`local-ocr`), Qwen3-Embedding-0.6B (`local-embed`),
Whisper (`llm-stt`). Welche Modelle hinter einer Alias-Gruppe
stehen, ist reine Config
([Skalierung](../universum/skalierung.md#gpu-instanzen-fur-ki)).

## Wie wird das System geupdatet?

Images sind **gepinnt**; Updates sind ein diffbarer
Vier-Schritt: Pin ändern → `nu compose --diff` →
`--auto-apply` → den einen Container restarten. Quadlets werden
nie von Hand angefasst
([Updates](../architektur/updates.md)).

## Was ist Open Core?

Die Kernplattform: ownCloud-Infinite-Scale-basierender, deutlich
aufgerüsteter Open-Cloud-Unterbau mit Open Cosmos Stack
(Suche, Dokumenten-Verständnis, KI, Collaboration). Die Repos
heißen noch `opencloud` (KOSMOS-Edition)
([Open Core](../dienste/opencore.md)).

## Was ist der Unterschied zu F13?

Die Edition führt die F13-Programmlinie in einem neuen Bereich
(Dokumentenmanagement) weiter; gemeinsame Grundlagen
(Souveränität, Modell-Agnostik, Open Source) gelten für beide
([F13](https://gitlab.opencode.de/groups/f13)).

## Wer betreibt das?

Die **Innovationskommune Stadt Brandis** im Rahmen des
**Parthlandverbunds** (acht Kommunen des Landkreises Leipzig) als
praxisgeführtes Vortriebsprojekt — Anforderungen aus dem
laufenden Verwaltungsbetrieb.
[Kontakt](../kontakt/impressum.md).
