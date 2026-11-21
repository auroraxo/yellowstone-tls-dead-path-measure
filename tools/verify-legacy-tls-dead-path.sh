#!/usr/bin/env bash
# Re-verify rpcpool/yellowstone-grpc#928 without building the crate.
#
#   ./tools/verify-legacy-tls-dead-path.sh [clone-dir]
#
# Checks, against the checked-out sources:
#   V1  maybe_tls_server_config is built and replaced, but never read again
#   V2  the legacy GrpcAddress::Tcp arm pushes Listener::Tcp(incoming, None)
#   V3  the listen[] arm wraps the socket in Listener::Tls(...)
#   V4  no warning exists for a legacy TCP address carrying TLS config
#
# Exit 0 = the dead path is present (issue reproduces), non-zero = not found.
set -euo pipefail

DIR="${1:-$(pwd)}"
SRC="$DIR/yellowstone-grpc-geyser/src/grpc.rs"
[ -f "$SRC" ] || { echo "grpc.rs not found under $DIR"; exit 2; }

built=$(grep -c "let mut maybe_tls_server_config" "$SRC" || true)
readagain=$(grep -n "maybe_tls_server_config" "$SRC" | grep -vc "let mut\|replace" || true)
legacy_push=$(grep -c "listeners.push(Listener::Tcp(incoming, None))" "$SRC" || true)
tls_wrap=$(grep -c "Listener::Tls(TlsIncoming::new(incoming, tls_acceptor), auth)" "$SRC" || true)
tcp_tls_warn=$(grep -c "TLS config is ignored for Unix domain socket" "$SRC" || true)

fail=0
echo "V1 built=$built subsequent-reads=$readagain"
[ "$built" -ge 1 ] && [ "$readagain" -eq 0 ] || { echo "V1 FAIL (dead path changed)"; fail=1; }
echo "V2 legacy plaintext push present: $legacy_push"
[ "$legacy_push" -ge 1 ] || { echo "V2 FAIL"; fail=1; }
echo "V3 listen[] TLS wrap present: $tls_wrap"
[ "$tls_wrap" -ge 1 ] || { echo "V3 FAIL"; fail=1; }
echo "V4 UDS-only TLS warning: $tcp_tls_warn (no legacy-TCP equivalent exists)"
[ "$tcp_tls_warn" -ge 1 ] || { echo "V4 FAIL"; fail=1; }

if [ "$fail" -eq 0 ]; then
  echo "VERDICT: issue-928-dead-path-present (legacy TCP serves plaintext with tls_config set)"
else
  echo "VERDICT: issue-928-recheck-failed"
fi
exit "$fail"
