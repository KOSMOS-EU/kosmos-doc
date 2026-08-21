---
icon: octicons/package-24
---

# Deployment

Eine KOSMOS-Instanz wird von der **Workstation** aus gerollt —
`deploy-opencloud.sh` (Repo `kosmos-nuhost-deploy`) spricht nur
`nu pmx`-Kommandos an. Auf dem Zielhost landet kein Rollout-Repo,
nur das fertige Compose-Dir unter `/nu/container/<target>/compose/`.

## INI-Config = Instanz-Dokumentation

Pro Instanz eine INI-Datei unter `deploy/`. Alle Werte außer
Superdomain sind optional — Defaults übernimmt die Referenz-VM:

```ini
[cloud]
superdomain = kunde.example.com
# target = kunde_example_com     # Default: Superdomain, . durch _
# site_name = Kunde GmbH

[pmx]
host = 192.0.2.2                 # Proxmox-Host
vmid = 301
source = 300                     # Referenz-VM für Hardware-Profil
ip = 192.0.2.140/24
# name = nuhost6-301
# gateway = 192.0.2.1            # Default: von Quell-VM
# memory = 8192                  # Default: von Quell-VM
# cores = 4
# disk_size = 64G
# ip1 = 198.51.100.140/24        # zweite NIC
# storage = lvm-nvme01
# deb = /tmp/nuhost6_6.0.3-1_all.deb

[network]
network = nu-open2000:ip=192.0.2.140
dns = 192.0.2.1
# dns_search = kunde.example.com
# public_ip = 203.0.113.50       # bei NAT: Router forwardet 80/443

[options]
# with_ai = true                 # Open WebUI + AI-CLI
# with_openyard = true
```

## Phasen

```
Phase 0: Preflight    ./deploy-opencloud.sh --config deploy/kunde.conf --preflight
Phase A: VM           nu pmx clonehost <source>@<host> <vmid> --ip ...
Phase B: OpenCloud    Templates rendern → nu pmx push → nu compose
                      --auto-apply → nu packages pull → nu container
                      enable → nu start
Phase C: Validierung  nu ps, curl -k https://cloud.<SUPERDOMAIN>
Phase D: Absicherung  nu container check-all, nu snapshot,
                      nu container nas2-backup-enable
```

Die Preflight-Checks vor dem ersten Touch:

| Check        | Prüfung                                          |
|--------------|--------------------------------------------------|
| Lokale Tools | nu, openssl, rsync, curl, dig vorhanden          |
| Templates    | compose/, .env.template, nuhost6.conf.template   |
| DNS          | alle Domains auflösbar, zeigen auf public_ip     |
| PMX-Host     | SSH-Zugang zum Proxmox-Host                      |
| Quell-VM     | Referenz-VM (source) existiert                   |
| Ziel-VMID    | noch nicht belegt                                |
| DEB-Datei    | existiert (wenn angegeben)                       |

CLI-Parameter überschreiben die Config
(`--memory 16384 --cores 8`); `--skip-vm` (VM existiert),
`--no-start` (Pod nicht starten, für manuelle Anpassungen).

## Was gerendert wird

| Template                          | Platzhalter                          |
|-----------------------------------|--------------------------------------|
| `.env.template`                   | Superdomain, Admin-Passwort, Secrets |
| `compose.nuhost6.conf.template`   | Superdomain, Site-ID, Netzwerk       |
| `config/opencloud/apps.yaml`      | Classes-Domain                       |
| `config/idp-extra-clients.yaml`   | OIDC-Domains + Secrets               |
| `portal-sites.yaml.template`      | Superdomain, Site-ID/Name            |
| `config/ocis.yaml.template`       | JWT, Machine-Auth, Transfer-Secrets  |

Secrets werden per `openssl rand -hex 32` generiert. Bei Re-Deploy
werden bestehende Secrets von der VM übernommen — Identitäten
bleiben stabil.

## Nach dem Deployment

```bash
nu ps                        # Status
nu images                    # Image-Versionen
nu logs <target> -f          # Logs aller Pod-Member
nu restart <target>          # Neustart
nu snapshot <target>         # Referenz-Snapshot
```

Was danach passiert — Pins, Diffs, Packages:
[Updates](updates.md).
