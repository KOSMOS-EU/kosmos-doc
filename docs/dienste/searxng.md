---
icon: octicons/search-24
---

# SearXNG

[SearXNG](https://github.com/searxng/searxng) ist die
**Meta-Suchmaschine** der Edition — Websuche-Grundlage für die
KI-Frontends (Open WebUI, Agent-Funktionen).

## Besonderheit: separates Target

SearXNG läuft **nicht im Pod**, sondern als eigenes Target
(`<target>_searxng`, `[services.separate]`) — eigener Pod, kein
Traefik-Routing, nur intern erreichbar.

| | |
|---|---|
| Image | `searxng/searxng` |
| Config | `settings.yml` (ro-Mount, im Compose-Dir) |
| Volumes | `searxng-config`, `searxng-cache` |

## Warum extern

Meta-Suche erzeugt laufenden External-Traffic (Queries an
Suchmaschinen). Als separates Target bleibt der Datenort-Pod
unberührt: eigene Lebenszyklen, eigene Firewall, und ein Ausfall
betrifft nie die Kern-Dienste. Die Pod-Konvergenz (endlich viele
Kern-Container) bleibt erhalten
([Skalierung](../universum/skalierung.md)).
