---
icon: octicons/shield-lock-24
---

# Backup

Backup-Konzept der Edition: **btrfs-Snapshots** als
Wiederherstellungseinheit, **NAS2** als zweiter Standort, und die
Einsicht, dass alles außer dem Dateibaum **ableitbar** ist
([Revisionssicherheit](../universum/revisionssicherheit.md)).

## Was gesichert wird

| Was | Wie | Ableitbar? |
|-----|-----|-----------|
| Dateibaum + xattrs (`/var/lib/opencloud`) | Snapshot + NAS2 | nein — **die** Wahrheit |
| Qdrant-Vektoren (`/qdrant/storage`) | Snapshot + NAS2 | ja (Re-Enrich) |
| Config/State (`/etc/opencloud`, …) | Store-Volumes, Snapshot | teils (Secrets nicht!) |
| Bleve-Index | — | ja (Re-Index) |
| Quadlets | — | ja (`nu compose`) |
| Compose-Dir | Git-Repo | — (Versionierung) |

Praktische Konsequenz: Das Snapshot des Storage-Targets **ist**
das Backup. Indexe und Container-Definitionen brauchen keines.

## Snapshots

```bash
nu snapshot <target>                     # anlegen (vor jeder Änderung!)
nu volumes                               # anzeigen
nu snapshot-restore <target> <snap>      # wiederherstellen
nu snapshot-send <target> <snap> <node>  # auf anderen Node übertragen
```

## NAS2

Pro Target eine `nas2.conf` im Target-Dir; Aktivierung:

```bash
nu container nas2-backup-enable <target>
```

Die Snapshots werden damit auf den zweiten Standort (NAS2)
gesichert — Wiederherstellung auch nach Totalausfall des Nodes.
NAS2 ist Teil der Absicherungsphase des Rollouts
([Deployment](../architektur/deployment.md#phasen)).

## Datenmigration (Node-Wechsel)

Für Migrationen zwischen Nodes (Skalierung, Failover):

```bash
# Dateibaum
nu pmx sync <vmA>@<host>:/nu/storage/<target>/opencloud/ \
            <vmB>@<host>:/nu/storage/<target>/opencloud/
# Vektoren
nu pmx sync <vmA>@<host>:/nu/storage/<target>/qdrant/ \
            <vmB>@<host>:/nu/storage/<target>/qdrant/
```

`nu pmx sync` richtet SSH-Key automatisch ein und bevorzugt
interne IPs. Danach: `nu migrate <target> <node>`
([Skalierung](../universum/skalierung.md#weitere-nodes)).

## Betriebsregeln

- **Vor jeder Änderung Snapshot** — Image-Update, Config-Änderung,
  Massen-Reindex.
- **Nur ein Indexlauf gleichzeitig**; bei Hänger Container
  restarten, dann erneut triggern.
- Secrets (Admin-Passwort, Machine-Auth, OIDC) werden beim
  Rollout generiert und beim Re-Deploy von der VM übernommen —
  liegen also im Store-Backup, nicht im Git.
