# yellowstone-tls-dead-path-measure

Independent verification artifacts for rpcpool/yellowstone-grpc#928: with the
legacy `grpc.address` + `grpc.tls_config` config, the built rustls server config
is never attached, so the TCP listener serves plaintext gRPC.

- `tools/verify-legacy-tls-dead-path.sh <clone>` — 4 source checks, no build needed
- `research/tls-dead-path-confirmed-2026-11-21.json` — claim results, history
  (introduced 2026-06-19 with the custom-TLS support itself; last clean tag
  geyser-v13.2.5, first affected geyser-v13.3.0), and the delivered comment
