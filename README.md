# nginx-quic

This repository builds an nginx image with the QUIC/TLS patches on top of Alpine and publishes it to Docker Hub. Published tags use the format `valtoni/nginx-quic:<nginx-version>-<quictls-ref>` so it is clear which QUIC/TLS bundle was used.

## Build script
- `build.ps1` downloads the latest Alpine, NGINX and quictls references (unless provided) and pushes the resulting image to `valtoni/nginx-quic`, tagging it as `$NginxVersion-$QuicTlsRef`.
- Pass `-MetadataPath build-meta.json` to store the resolved versions so other tooling (like the nightly job) can read them.

```powershell
# Build with automatically detected versions
./build.ps1

# Build with explicit versions and capture metadata
./build.ps1 -AlpineVersion 3.20 -NginxVersion 1.27.1 -QuicTlsRef openssl-3.2.2+quic1 -MetadataPath build-meta.json
```

## Nightly build workflow
`.github/workflows/nightly-build.yaml` runs every day at 03:00 UTC (or manually) and will:
1. Execute `build.ps1`.
2. Read `build-meta.json`.
3. Insert a line in the table below with the versions and timestamps.
4. Commit the updated README.

## Nightly builds
<!-- BEGIN_NIGHTLY_BUILDS -->
| Date | Alpine | NGINX | Start (UTC) | End (UTC) | Logs |
| --- | --- | --- | --- | --- | --- |
<!-- END_NIGHTLY_BUILDS -->
