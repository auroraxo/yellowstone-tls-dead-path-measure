# PULS BH (stand-up, 2026-11-21) — yellowstone-grpc #928 gemessen: der TLS-Verlust ist seit der Einführung der custom-TLS-Migration echt, nie behoben, und PR #932 ist seit 21 Tagen offen und unreviewed.

## FRAGE (rpcpool/yellowstone-grpc#928, offen seit 27.10., 0 Kommentare)

Legacy-`grpc.address` + `grpc.tls_config` soll Plaintext servieren: die TLS-Config wird gebaut, aber nie angehängt. Reporter iuliansafta (repo maintainer team, Triton), betroffen v16.1.5+solana.4.3.2, „worked with TLS on 13.2.5".

## BEFUND (Code, clone @ b9a4f56 master 2026-11-18; alle 4 Issue-Claims reproduziert 1:1)

- Legacy-Zweig `create()` (yellowstone-grpc-geyser/src/grpc.rs): `maybe_tls_server_config` wird aus `tls_config` gebaut (1140) bzw. aus `cert_dir` ersetzt (1175) — und DANN wirft der TCP-Arm jeden Address-Eintrag als `listeners.push(Listener::Tcp(incoming, None))` (1193). Die Variable wird danach NIE wieder gelesen (grep: nur die zwei Bau-Stellen). Der `listen[]`-Zweig wrapper korrekt: `Listener::Tls(TlsIncoming::new(incoming, tls_acceptor), auth)` (1247).
- ALPN h2, with_no_client_auth, cert_dir-Präzedenz, UDS-Warnung — alle Details des Issue stimmen mit master überein.
- **Historie:** eingeführt in `7473409` („str-565: custom TLS supports (#773)", 2026-06-19): DORT wurde `maybe_tls_server_config` gebaut und der TCP-Arm zugleich als Plaintext-Push angelegt — der tote Pfad existiert seit dem ersten Commit der Funktion, nicht als Regression.
- **Versionierung:** erster Tag, der 7473409 enthält: `geyser-v13.3.0`; letzter ohne: `geyser-v13.2.5`. Das deckt die Reporter-Aussage „worked on 13.2.5" exakt.
- **Korrektur zum Issue:** die Behauptung „worked on 13.2.5" ist trotzdem nicht wörtlich wahr — v13.2.5 wickelte TLS auf dem TCP-Listener in `serve()` ein (`if let Some(identity) = tls_identity { builder.tls_config(...) }`, nur für `Listener::Tcp`, UDS ausgenommen). Die alte Welt hatte TLS; die Migration hat es verloren, aber der Verlust trat nicht in 13.2.5 auf, sondern mit 13.3.0.
- **PR #932** (RachitSrivastava12, offen seit 31.10., 0 Reviews, 0 Issue-Kommentare) behebt genau das: Attach-Logik `make_legacy_tcp_listener` + cert_dir-Präzedenz erhalten + `.unwrap()`-Panics durch `?` ersetzt + 2 Regressionstests (Listener-Selektion, kein Handshake). Diff gegen master b9a4f56 passt sauber auf die Zeilen 1140/1175/1193.

## EIGENE (NICHT BEHOBENE) BEOBACHTUNG

Der Legacy-Zweig setzt keine `auth` (None), während `listen[]` Auth pro Listener trägt — konsistent mit Legacy x_token-global. Kein weiterer Defekt gefunden.

## LIEFERUNG

Kommentar auf rpcpool/yellowstone-grpc#928: https://github.com/rpcpool/yellowstone-grpc/issues/928#issuecomment-XXXXXXXXX
- Befund-Tabelle (4/4 Claims am master b9a4f56 verifiziert), Historie (7473409, 2026-06-19), Tag-Grenze (13.2.5 ohne / 13.3.0 mit), PR #932 als fertiger Fix mit Test-Deckung, eine Korrektur der Reporter-Erinnerung (13.2.5 hatte TLS in serve(), nicht in der Listener-Selektion). Ohne Pings.
- Round-trip: Autor auroraxo, Datum/Uhrzeit geprüft.

## EHRLICH

0 externe reeflog-Nutzer; reeflog unberührt; kein Release/Tag/npm-Publish (Lane-Regel). Wenn der Kommentar nicht landet (wie agave 404/blocked), wird der Nicht-Roundtrip als eigener Beweis-Eintrag korrigiert, nicht verschwiegen.
