---
icon: octicons/sync-24
---

# Updates

Update-Prinzip: **kein Container-Recreate, kein manuelles
`podman pull`, nie Quadlets von Hand anfassen.** Jede Änderung läuft
durch das Compose-Dir und `nu compose`.

## Image-Update

Images sind in `[pin]` **gepinnt** — es gibt kein Auto-Upgrade.
Ein Service-Update:

```bash
# 1. Pin ändern (exakte Version)
vi /nu/container/<target>/compose/compose.nuhost6.conf
#    [pin]
#    tika = <registry>/<repo>:<tag>

# 2. Prüfen, was sich ändert
nu compose --diff /nu/container/<target>/compose/

# 3. Anwenden (Container-Dateien + enable + daemon-reload)
nu compose --auto-apply /nu/container/<target>/compose/

# 4. Nur den betroffenen Container restarten — NICHT den ganzen Pod
systemctl restart <target>-<service>.service
```

- `nu compose --pin-freeze` friert die laufenden Image-Versionen
  in `[pin]` ein.
- Podman zieht das neue Image beim Container-Start — kein
  separates Pull.
- Nach `--auto-apply` räumt nu automatisch auf: max. 3 Image-
  Versionen pro Repo, freier Platte auf `/` wird gemeldet
  (Warnung > 80 %, kritisch > 90 %).

## Web-Extensions (nu.packages)

Extensions sind versionierte ZIPs mit vier Spec-Formaten:

```
package:version                        # Default-Registry
package:version:org                     # anderer Org, gleiche Registry
package:version@github:owner/repo       # GitHub-Release-Asset
https://example.com/file.zip            # direkte URL
```

Deploy aus dem Extension-Repo: `deploy_zip.sh` (liest die DIST des
Repos) → pinnt die Version in `nu.packages` →
`nu compose --auto-apply` — packages pull, Quadlet-Update und
Restart in einem Lauf.

## Regeln für Compose-Änderungen

- **Das Compose-Dir ist die einzige Schreiblebfläche.** Jedes
  `nu compose --auto-apply` überschreibt die abgeleiteten
  Config-Volumes, Env-Dateien und Quadlets. In abgeleitete
  Config-Volumes hineinschreiben bringt nichts — beim nächsten
  Apply ist es weg.
- **Vorher immer `--diff`** — bei Updates, bei Live-Migrationen,
  bei manuellen Anpassungen.
- **Drei Stufen des Compose-Lebenszyklus**: (1) ein frisches
  Rollout erzeugt alles sauber; (2) ein Update muss prüfen, welche
  Daten der Deploy-Config ggf. überschrieben werden; (3) eine
  Live-Migration verhält sich wie ein Update — abgeleitet, ohne
  partielles Übernehmen.
- **Member-Env** gehört in die `environment:`-Section der
  jeweiligen Service-YAML; nu-compose generiert daraus die
  `<member>.env`. Manuelle Env-Dateien im Compose-Dir werden
  ignoriert.
- **Neue Volumes** werden in der Service-Definition deklariert
  (Named Volumes zusätzlich unter `[storage]` = btrfs, groß,
  snapshottbar, oder `[store]` = klein, unter `volumes/`) — dann
  `--diff` + `--auto-apply`.
