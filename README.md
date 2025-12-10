# nginx-quic

This repository builds an nginx image with the QUIC/TLS patches on top of Alpine and publishes it to Docker Hub. Published tags use the format `valtoni/nginx-quic:<nginx-version>-<quictls-ref>` (any characters outside `[A-Za-z0-9_.-]` are replaced with `-`) so it is clear which QUIC/TLS bundle was used.

## Build script
- `build.ps1` downloads the latest Alpine, NGINX and quictls references (unless provided) and pushes the resulting image to `valtoni/nginx-quic`, tagging it as the sanitized `$NginxVersion-$QuicTlsRef`.
- Pass `-MetadataPath build-meta.json` to store the resolved versions so other tooling (like the nightly job) can read them.
- Add `-DryRun` when you only want to refresh `build-meta.json` without building/pushing (the nightly workflow uses this to decide whether to skip a run).

```powershell
# Build with automatically detected versions
./build.ps1

# Build with explicit versions and capture metadata
./build.ps1 -AlpineVersion 3.20 -NginxVersion 1.27.1 -QuicTlsRef openssl-3.2.2+quic1 -MetadataPath build-meta.json

# Refresh metadata only (no build/push)
./build.ps1 -MetadataPath build-meta.json -DryRun
```

## Nightly build workflow
`.github/workflows/nightly-build.yaml` runs every day at 03:00 UTC (or manually) and will:
1. Resolve the next tag via `./build.ps1 -DryRun` and bail out early if `valtoni/nginx-quic:<nginx-version>-<quictls-ref>` already exists on Docker Hub.
2. When the tag is new, execute the build/push with `build.ps1`.
3. Read `build-meta.json`.
4. Insert a line in the table below with the versions and timestamps.
5. Commit the updated README.

## Nightly builds
<!-- BEGIN_NIGHTLY_BUILDS -->
| Date | Alpine | NGINX | QUIC-TLS | Image | Start (UTC) | End (UTC) | Logs |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2025-12-10 | 3.23 | 1.29.4 | openssl-3.3.2 | [valtoni/nginx-quic:1.29.4-openssl-3.3.2](https://hub.docker.com/layers/valtoni/nginx-quic/1.29.4-openssl-3.3.2/) | 2025-12-10T03:33:01Z | 2025-12-10T03:41:41Z | [Logs](https://github.com/valtoni/nginx-quic/actions/runs/20086370484) |
| 2025-11-09 | 3.22 | 1.29.3 | openssl-3.3.2 | [valtoni/nginx-quic:1.29.3-openssl-3.3.2](https://hub.docker.com/layers/valtoni/nginx-quic/1.29.3-openssl-3.3.2/) | 2025-11-09T01:06:20Z | 2025-11-09T01:14:46Z | [Logs](https://github.com/valtoni/nginx-quic/actions/runs/19201148266) |
| 2025-11-09 | 3.22 | 1.29.3 | openssl-3.3.2 | [valtoni/nginx-quic:1.29.3-openssl-3.3.2](https://hub.docker.com/layers/valtoni/nginx-quic/1.29.3-openssl-3.3.2/) | 2025-11-09T00:41:37Z | 2025-11-09T00:50:09Z | [Logs](https://github.com/valtoni/nginx-quic/actions/runs/19200874401) |
<!-- END_NIGHTLY_BUILDS -->
