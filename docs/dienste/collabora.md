---
icon: octicons/file-24
---

# Collaboration

Office-Bearbeitung im KOSMOS besteht aus **zwei Containern**:

| Container      | Rolle                                        | Port |
|----------------|----------------------------------------------|------|
| `collabora`    | Collabora Online (Office-Rendering, WOPI)    | 9980 (HTTPS) |
| `collaboration`| App-Provider im Open Core (WOPI-Anbindung)   | 9300 |

- **collabora**: Image `collabora/code:25.04.2.1.1` (gepinnt),
  Domain `collabora.<SUPERDOMAIN>`.
- **collaboration**: Open-Core-Image als `opencloud collaboration
  server`, Domain `wopiserver.<SUPERDOMAIN>`; registriert
  `CollaboraOnline` als sicheren View-App-Handler.

## SSL (wichtig)

`ssl.enable=true` ist **Pflicht**: ohne liefert die Collabora-
Discovery `http://`-URLs, die Browser als Mixed Content blocken.

- Der Entrypoint erzeugt ein self-signed Cert
  (`coolconfig generate-proof-key`) — Collabora braucht ein Cert.
  `DONT_GEN_SSL_CERT` **nicht** zusammen mit `ssl.enable=true`
  setzen (Segfault).
- `extra_params` muss **einzeilig** sein (keine Backslash-
  Continuation — Podman-Env würde mehrzeilig interpretieren):

```
--o:ssl.enable=true --o:ssl.ssl_verification=false --o:ssl.termination=true --o:welcome.enable=false --o:net.frame_ancestors=https://cloud.<SUPERDOMAIN>/
```

- **Traefik-Backend**: mit `ssl.enable=true` lauscht Collabora auf
  HTTPS → `server.scheme=https`. Auf Instanzen ohne Let's Encrypt
  (Step-CA) ist das Collabora-Cert self-signed → Traefik braucht
  `insecureSkipVerify` für das Backend (File-Provider
  `serversTransports`). Auf Let's-Encrypt-Instanzen nicht nötig.

## Start-Timing

`collaboration` lädt beim Start die Discovery von `collabora`.
Collabora braucht 30–50 s zum Hochfahren; schlägt der Discovery-
Load fehl, wird der App-Provider **nicht** registriert — es gibt
keinen Retry. Fix: nach Pod-Start

```bash
systemctl restart <target>-collaboration.service
```

(im Compose ist `depends_on: collabora: service_healthy` gesetzt;
der Restart ist die Sicherheitsstufe.)

## CSP

Die CSP der Web UI erhält die Collabora-Domain als `frame-src`
(Platzhalter-Config, keine hardcodeden Domains).
