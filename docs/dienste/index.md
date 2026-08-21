---
icon: octicons/server-24
---

# Dienste

Alle Dienste der Edition laufen in **einem Pod** (Target
`cloud_<superdomain>`, Punkte durch `_` ersetzt) — ausgenommen die
**separaten Targets** (SearXNG, openworks-worker), die eigene Pods
bilden. Status im Standard-Rollout:

| Service          | Rolle                                  | Standard          | Port (Pod-intern) |
|------------------|----------------------------------------|-------------------|-------------------|
| traefik          | Reverse Proxy, TLS, Routen             | ja                | 80, 443, 8112     |
| opencloud        | **Open Core**: Storage, Spaces, Web    | ja                | 9200              |
| tika             | open_taki: Dokumenten-Engine           | ja                | 9998              |
| qdrant           | Vektordatenbank (Embeddings)           | ja                | 6333              |
| microllm         | LLM-Routing, Alias-Gruppen             | ja                | 8012              |
| collabora        | Office (Collabora Online, WOPI)        | ja                | 9980              |
| collaboration    | Office-App-Provider im Open Core       | ja                | 9300              |
| classes          | Classes-Service                        | ja                | 9181              |
| portal           | Intranet: Public-Links als Sites       | ja                | 8080              |
| radicale         | Kalender und Kontakte                  | ja                | —                 |
| open-webui       | Chat-UI                                | Option `with_ai`  | 8081              |
| open-aitool      | AI-CLI (Agent)                         | Option `with_ai`  | 3001              |
| openyard         | DMS-Microservice                       | Option `with_openyard` | 9201        |
| searxng          | Meta-Suche                             | separates Target  | — (intern)        |
| openworks-worker | JobEngine-Worker                       | separates Target  | —                 |

Jede Zeile ist eine eigene YAML im Compose-Dir
(`docker-compose.yml` + `tika.yml`, `microllm.yml`, …); Status und
Ziel (Pod / separates Target) definiert die
`compose.nuhost6.conf` (`[services.exclude]`,
`[services.separate]`).

## Aussortiert im Standard

Per Default sind diese Services **exkludiert** und können
einzelaktivierte werden —
[Optionale Dienste](optional.md):

`debug-collaboration-collabora`, `debug-collaboration-onlyoffice`,
`debug-opencloud`, `inbucket`, `minio`, `postgres`, `keycloak`,
`ldap-server`, `clamav`, `superdomain-redirect`

## Konvergenz

Der Dienst-Pool ist bewusst **endlich**: neue Last und neue
Funktionen wachsen über die Schichten Web-Apps, Worker und Modelle —
nicht über neue Container im Pod
([Skalierung](../universum/skalierung.md)).
