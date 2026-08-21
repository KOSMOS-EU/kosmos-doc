---
icon: octicons/alert-24
---

# Troubleshooting

Die wiederkehrenden Störbilder der Edition — mit Diagnose und
Fix. Erst [Monitoring](monitoring.md) abfragen, dann hier nach-
schlagen.

## Bleve-Segment-Problem (Write-Block)

Bleve/Scorch erzeugt pro Write ein Segment und merged im
Hintergrund. Bei vielen parallelen kleinen Writes (Events,
Re-Enrich, Reindex gleichzeitig) wachsen Segmente schneller als
der Merge — ab ca. 1000 Segmenten **blockiert der Writer**;
Reads gehen weiter.

**Symptom**: `doUpsertItem: bleve upsert starting` im Log, aber
kein `ok`/`failed`; alle nachfolgenden Writes blockieren.

**Diagnose**:

```bash
# 1. Segment-Anzahl (gesund: 10–30, kritisch: >200)
ls /nu/storage/<target>/opencloud/search-v2/bleve/store/*.zap | wc -l

# 2. CPU: 25 % = Merge-Spin, 0 % = echter Deadlock
podman top systemd-<target>-opencloud -eo pid,pcpu,rss | head -2

# 3. Syscall-Count (futex = Lock-Contention)
PID=$(podman inspect --format "{{.State.Pid}}" systemd-<target>-opencloud)
timeout 10 strace -f -p $PID -e trace=futex,pwrite64 -c

# 4. Goroutine-Dump (GOTRACEBACK=all muss in Container-Env sein)
kill -ABRT $PID
journalctl -u <target>-opencloud -n 5000 --no-pager | grep -A5 "bleve\|scorch"
```

**Fix** (Index ist ableitbar — xattrs sind die Wahrheit):

```bash
systemctl stop <target>-opencloud.service
rm -rf /nu/storage/<target>/opencloud/search-v2/bleve
systemctl start <target>-opencloud.service
# nach ~20 s (Service ready):
podman exec systemd-<target>-opencloud \
  opencloud search index --all-spaces --insecure
```

Neuer Index = wenige große Segmente statt vieler kleiner.

**Prävention**: kein `--force-rescan` auf alle Spaces
gleichzeitig im laufenden Betrieb; NATS-Jetstream sauber halten;
Segment-Anzahl regelmäßig prüfen.

## Re-Enrich überschreibt Favorites

Bei `--force-rescan` ruft die Enrich `doUpsertItem` auf. Liefert
der Stat-Call die Favorites im Opaque, bleiben sie erhalten —
sonst wird das Feld leer überschrieben.

**Prüfen** (xattr = Wahrheit vs. Index):

```bash
# xattrs auf dem Dateisystem
podman exec systemd-<target>-opencloud \
  getfattr -d -m ".*fav.*" "/var/lib/opencloud/storage/users/<space>/<ordner>"

# Bleve-Index
podman exec systemd-<target>-opencloud \
  curl -s "http://localhost:9224/index-lookup?q=Favorites:%22<user-id>%22&limit=10"
```

## NATS-Jetstream-Überlaufen

Events stauen sich → Consumer fällt hinterher → neue Events
(Favorites, Tags) gehen verloren. Der Purge-Monitor warnt bei
> 10 000 pending.

```bash
du -sh /nu/storage/<target>/opencloud/nats/jetstream/
```

**Aufräumen** (stoppt den Container!):

```bash
systemctl stop <target>-opencloud.service
rm -rf /nu/storage/<target>/opencloud/nats/jetstream/*
systemctl start <target>-opencloud.service
# danach fehlende Index-Updates nachholen:
podman exec systemd-<target>-opencloud \
  opencloud search re-enrich --all-spaces --force-rescan --insecure
```

## SSH: PerSourcePenalties (Debian 13)

OpenSSH 9.8+ bestraft Clients, die sich verbinden, ohne Auth
abzuschließen — Deploy-Scripts mit vielen schnellen Connects
(`nu pmx`) landen nach wenigen Fehlversuchen in einer Penalty,
die **auch gültige Key-Auth** sperrt.

**Symptom**: `ssh root@<ip>` fragt intermittierend nach Passwort;
Server-Log: `srclimit_penalise: ... deferred penalty for penalty:
connections without attempting authentication`.

**Fix** (im nuhost6-DEB: `99-nu-no-penalties.conf`):

```
PerSourcePenaltyExemptList <management-netze>
PerSourcePenalties noauth:0 authfail:2s max:30s
```

Danach sshd **komplett neu starten** (reload reicht nicht — der
Penalty-State im Master bleibt). Alternativ: über die interne IP
anstelle des öffentlichen Hostnames verbinden.

## IP-Änderungen: Netplan, nicht Runtime

Eine nur per `ip addr del` entfernte IP kommt nach einem
`systemd-networkd`-Restart (z. B. via `unattended-upgrades`)
zurück — Requests landen dann zufällig auf altem/neuem System
(401, Session-Fehler). **Regel: IP-Änderungen immer in der
Netplan-Config, nie nur Runtime.**

## Collabora: App-Provider fehlt

`collaboration` startet vor `collabora` fertig → Discovery-Load
fehlt → App-Provider wird nie registriert (kein Retry).

```bash
systemctl restart <target>-collaboration.service
```

Details: [Collaboration](../dienste/collabora.md#start-timing).

## Port nicht erreichbar — nicht raten

Nicht spekulieren (vorgelagerte Firewall, Security Group), sondern
am Server prüfen, was ankommt:

```bash
# 1. LOG-Regel als erste INPUT-Regel
iptables -I INPUT 1 -p tcp --dport <PORT> -j LOG --log-prefix "DEBUG_PORT: "
# 2. von außen connecten (nc -z -w5 <server> <PORT>)
# 3. dmesg | grep DEBUG_PORT   -> SRC zeigt die Wahrheit
# 4. LOG-Regel entfernen: iptables -D INPUT 1
```

Achtung: Podman-Port-Mappings (`-p`) umgehen UFW-INPUT (NAT/TABLE);
host-Netz-Binds laufen dagegen durch INPUT.
