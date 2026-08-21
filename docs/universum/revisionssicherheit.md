---
icon: octicons/history-24
---

# Revisionssicherheit

KOSMOS ist so gebaut, dass **jeder Zustand des Systems wiederherstellbar**
und **jede Änderung dokumentiert** ist. Drei Mechanismen tragen das:

1. **Ableitbare Daten** — der Dateispeicher ist die Wahrheit; alles
   andere (Indexe, Embeddings, Container-Definitionen) lässt sich
   daraus neu erzeugen.
2. **btrfs-Snapshots** — punktuelle Zeitpunkte pro Target,
   wiederherstellbar und zwischen Nodes übertragbar.
3. **Versionierte Konfiguration** — Compose-Dir, Image-Pins und
   Instanz-Config sind die einzige Quelle; alles Lauffähige ist ein
   daraus abgeleitetes Artefakt.

## Der Speicher ist die Wahrheit

Alle Inhalte liegen in Spaces auf einem POSIX-Dateisystem
([Open Core](../dienste/opencore.md)). Metadaten — Dokumenttyp, Tags,
Favoriten, Extraktionsergebnisse — werden als **xattrs direkt auf den
Dateien** geschrieben. Daraus folgt das zentrale Sicherheitsprinzip:

- Der **Bleve-Index** (Suche) ist ableitbar — er wird aus xattrs und
  Metadaten neu aufgebaut.
- Die **Qdrant-Embeddings** (semantische Suche) sind ableitbar — sie
  werden per Re-Enrich über die lokalen Modelle neu erzeugt.
- Die **Quadlets** (Container-Definitionen) sind ableitbar — sie werden
  aus dem Compose-Dir von `nu compose` generiert.

Der schlimmste Fall ist damit nie Datenverlust, sondern **Rearbeit**:
ein Index wird gelöscht und aus dem Dateibaum neu aufgebaut (Sekunden
bis Stunden, je nach Bestand). Details: [Suche](../dienste/suche.md),
[Troubleshooting](../betrieb/troubleshooting.md).

## btrfs: Snapshots pro Target

Die großen Daten-Volumes des Targets liegen auf **btrfs**
(`[storage]`-Section der Compose-Config, z. B. der Open-Cloud-Dateibaum
und Qdrant). Pro Target lassen sich Snapshots erzeugen:

```bash
nu snapshot <target>                    # Snapshot anlegen
nu volumes                              # Volumes + Snapshots anzeigen
nu snapshot-restore <target> <snap>     # Snapshot wiederherstellen
nu snapshot-send <target> <snap> <node> # Snapshot auf anderen Node senden
```

Die Betriebsregel: **vor jeder Änderung Snapshot** — Image-Update,
Config-Änderung, Massen-Reindex.

## Backup: NAS2

Snapshots bleiben nicht auf dem Node: die Volumes werden per
**NAS2-Backup** auf einen zweiten Standort gesichert. Pro Target existiert
eine `nas2.conf`; das Backup wird aktiviert per

```bash
nu container nas2-backup-enable <target>
```

Damit ist die Wiederherstellung auch nach einem Totalausfall des Nodes
möglich — nicht nur nach einem schlechten Update.
Details: [Backup](../betrieb/backup.md).

## Versionierte Konfiguration

| Ebene          | Was ist versioniert                          | Wo                                        |
|----------------|----------------------------------------------|-------------------------------------------|
| Compose        | Service-Definitionen, Env, Volumes, Firewall | `/nu/container/<target>/compose/`         |
| Image-Pins     | exakte Image-Version pro Service             | `[pin]` in `compose.nuhost6.conf`         |
| Packages       | Web-Extensions als versionierte ZIPs         | `nu.packages`                             |
| Instanz        | Superdomain, Netzwerk, Optionen              | INI-Config im Deploy-Repo                 |

- **Kein Auto-Upgrade**: Images sind gepinnt; eine Versionsänderung ist
  immer ein bewusster, diffbarer Schritt
  ([Updates](../architektur/updates.md)).
- **Kein manuelles Nachbestücken**: Quadlets und abgeleitete Configs
  werden von `nu compose` generiert; Änderungen gehen immer durch das
  Compose-Dir und werden vor dem Apply per `nu compose --diff` gezeigt.
- **Maschinenlesbare Instanz-Dokumentation**: die INI-Config pro Kunde
  beschreibt, wie die Instanz aussieht
  ([Deployment](../architektur/deployment.md)).

## Wiederherstellungspfade

| Schaden                                | Maßnahme                                        |
|----------------------------------------|-------------------------------------------------|
| Index korrupt oder blockiert           | Index löschen, aus xattrs neu aufbauen          |
| Embeddings veraltet (Modell-Wechsel)   | Re-Enrich mit `--force-rescan`                  |
| Datenverlust, kaputtes Update          | `nu snapshot-restore` oder NAS2-Backup          |
| Node ausgefallen                       | `nu migrate <target> <node>` auf identischem Node |
| Compose-Drift                          | `nu compose --diff` zeigen, `--auto-apply` regeneriert |

[Monitoring](../betrieb/monitoring.md) zeigt, ob die abgeleiteten
Indexe mit dem Dateibaum mithalten.
