---
icon: octicons/graph-24
---

# Netzwerk

Das Netzwerk entsteht in **drei Schichten** — jede mit eigener
Zuständigkeit und eigener Config:

```
Schicht          Zustaendigkeit          Konfiguration
=======          ==============          =============
netplan          Bridges aus Rollen      /nu/etc/bridges.conf (once-setup.sh)
nu-container     Podman-Netzwerke        Prefix = Rolle (management-*, service-*)
nu-compose       Pod-Zuweisung           compose.nuhost6.conf [network]
```

## Physische Topologie

```
Physische NIC  →  Bridge (netplan)      →  Podman-Netzwerk     →  Pod-IP
eth0 (VLAN)      bridge-management         management-xxx           192.0.2.200
eth1 (VLAN)      bridge-service            service-xxx              192.0.2.200
```

- Bridge-Namen: `bridge-<rolle>`; Podman-Netzwerke: `<rolle>-<name>`,
  z. B. `service-nu-open2000`.
- Die Rollen stehen in `/nu/etc/bridges.conf`
  (`management = eth0`, `service = eth1`, …); Bonding oder VLANs
  laufen in netplan.
- Auf Proxmox werden VLANs über SDN (VNet) verwaltet und als
  Bridges an die VM durchgereicht: `nu pmx vlan list/new/add`.
- `once-setup.sh` (im nuhost6-Paket) richtet Bridges,
  systemd-networkd und Podman-Netzwerke **einmalig pro Node** ein —
  bei `nu pmx clonehost` automatisch mit.

## Pod-Zuweisung

```ini
# compose.nuhost6.conf
[network]
network = nu-open2000:ip=192.0.2.200   # Pod-IP im Service-Netz
dns = 192.0.2.1
hostname = cloud.kunde.example.com
```

`nu-compose` löst Netzwerknamen transparent auf: wer
`nu-open2000` angibt, bekommt automatisch `service-nu-open2000`.

## Bridge-Firewall (nftables)

Pro Target erzeugt nu-container eine nftables-Chain
(`nu.firewall.nft`): Default-Drop, explizite Ports aus
`[firewall]`, Source-Restriktionen für SSH und interne
Diagnose-Ports, atomarer Generationswechsel.
Details: [Schutz](../universum/schutz.md#netzwerk-default-drop-an-der-bridge).

## Externes Routing

DNS und externes Routing macht nuhost6 **bewusst nicht** — das ist
Infrastruktur außerhalb (Router, Firewall, DNS-Provider). Für einen
public erreichbaren Service braucht es:

1. **Öffentliche IP → VM-IP**: Port-Forwarding (NAT) oder direkte
   IP-Zuweisung.
2. **DNS**: A-Records für `*.<SUPERDOMAIN>` (Wildcard oder
   einzeln).
3. **Bridge-Firewall**: Ports in `[firewall]` freigeben.

Beispiel mit NAT (Beispieldaten): Der Pod sitzt intern auf
`192.0.2.200`; der Router forwardet 80/443 von der öffentlichen
`203.0.113.50` auf die Pod-IP. In der Instanz-Config wird das
dokumentiert als `public_ip` im `[network]`-Block.

## Pod- vs. Network-Modus

| Modus | Verhalten |
|-------|-----------|
| `mode=pod` (Default) | Alle Container teilen den Pod-Namespace; `localhost` reicht; `opencloud-net` und Compose-`aliases` werden ignoriert |
| `mode=network` | Jeder Container isoliert; internes Netzwerk mit aardvark-dns (`<target>_net`, `Internal=true`); Gateway-Service (Traefik) hängt an beiden Netzen |

Im Pod-Modus funktionieren Env-Variablen wie
`GATEWAY_GRPC_ADDR=opencloud:9142`, weil `opencloud` per
`--add-host` auf `127.0.0.1` aufgelöst wird.

## Multi-Node

Alle Nodes haben **identische Bridges und Podman-Netzwerke**.
Deshalb lässt sich ein Pod per `nu migrate <target> <node>` mit
gleicher IP und gleichem VLAN verschoben werden — ohne DNS-Änderung
([Skalierung](../universum/skalierung.md#weitere-nodes)).
