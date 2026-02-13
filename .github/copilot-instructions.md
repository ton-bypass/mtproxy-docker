# Copilot instructions — mtproxy-docker

Purpose: give AI coding agents immediate, actionable knowledge to work on this small Dockerized MTProxy project.

## Big picture

- Single-container service that builds and runs Telegram MTProto proxy (MTProxy).
- Multi-stage Dockerfile: stage `build` clones Telegram's MTProxy repo and `make`s the binary; final image copies `mtproxyd` and provides `run.sh` to configure/launch.
- Runtime responsibilities: download Telegram proxy config/secret from core.telegram.org, manage runtime secrets and NAT info, then exec `mtproxyd`.

## Key files (read first)

- `Dockerfile` — multi-stage build producing `/usr/bin/mtproxyd`.
- `run.sh` — container entrypoint implementing env var-driven configuration and secret generation.

## Developer workflows (explicit commands)

- Build image: `docker build -t mtproxy-docker .`
- Run (example, bind host port 443 to container TLS port):
  - `docker run --rm -e SECRET=<32hex> -p 443:18443 -v $(pwd)/data:/data mtproxy-docker`
  - To let the container generate a secret: `-e SECRET_COUNT=2`
- Inspect generated secret: `cat data/secret` (persisted by `run.sh`).
- Enable shell-level debugging: set `DEBUG=1` to make `run.sh` use `set -x`.

## Important environment variables & rules (do not change silently)

- `SECRET` — comma-separated list of secrets; each must be 32 hex chars (16 bytes). Up to 16 entries.
- `SECRET_COUNT` — integer 1..16; triggers random-secret generation when `SECRET` is unset.
- `TAG` — optional 32-hex tag (validated in `run.sh`, non-conforming values are ignored).
- `WORKERS` — defaults to `2` if unset (used in `run.sh` currently only to set variable).
- `DEBUG` — any non-empty value sets `bash -x` for troubleshooting.

Validation rules (enforced in `run.sh`):

- SECRET regex: `^[0-9a-f]{32}(,[0-9a-f]{32}){,15}$` (case-insensitive accepted, converted to lower-case)
- TAG regex: `^[0-9a-fA-F]{32}$`

## Persistence & config locations

- `/data` — persisted secrets and `secret_cmd` are written here by `run.sh`.
- `/etc/telegram/backend.conf` — downloaded at runtime from `https://core.telegram.org/getProxyConfig`.
- `/etc/telegram/proxy-secret` — downloaded at runtime from `https://core.telegram.org/getProxySecret`.

## External integrations & runtime assumptions

- Downloads Telegram metadata from `core.telegram.org` at container start — requires outbound internet.
- Determines external IP via `https://digitalresistance.dog/myIp` and internal IP via `ip route` — both must succeed or container exits.
- `mtproxyd` is executed with `--aes-pwd` pointing to `/etc/telegram/proxy-secret` and `--nat-info "{INTERNAL_IP}:{EXTERNAL_IP}"`.

## Patterns & conventions to follow when changing code

- Keep entrypoint logic in `run.sh` (simple, single responsibility). If adding features, update `run.sh` tests/notes.
- Secrets must be validated and written to `/data/secret` and `/data/secret_cmd` as current script does — preserve file names/locations if other tooling depends on them.
- Preserve Docker multi-stage build: keep upstream `MTProxy` compilation in `build` stage and copy binary into final image.
- Do not change default runtime ports without updating `run.sh` link-generation and README examples (`tg://proxy` and `t.me/proxy` use port 443 in the script output).

## Troubleshooting hints (what to check first)

- If container exits early: check `docker logs` for errors downloading `getProxyConfig` / `getProxySecret`, or for IP-detection failures.
- If generated proxy links are incorrect: verify `EXTERNAL_IP` (external lookup) and `INTERNAL_IP` (route lookup).
- To reproduce locally without Docker: build MTProxy from upstream and run the `mtproxyd` command constructed in `run.sh`.

## Tests / CI

- No tests or CI present. When adding CI, ensure workflows:
  - Reproduce the multi-stage Docker build
  - Validate `run.sh` secret parsing (unit test shell logic or wrap in small test helper)

## Examples (copy-paste)

- Explicit secret: `docker run -e SECRET=0123...abcd -p 443:18443 -v $(pwd)/data:/data mtproxy-docker`
- Auto-generate two secrets and persist them: `docker run -e SECRET_COUNT=2 -p 443:18443 -v $(pwd)/data:/data mtproxy-docker`
- Debug run: `docker run -e DEBUG=1 -e SECRET_COUNT=1 -v $(pwd)/data:/data mtproxy-docker`

---

If any behavior or external command used by `run.sh` is incomplete or undocumented, tell me which part to expand — I will update this file accordingly. Please review for missing details or incorrect assumptions. 👍
