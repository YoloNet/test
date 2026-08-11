# Xray Audit

`SETUP/ins-xray.sh` queries the official release API but discards the result. It downloads `YoloNet/Xray-core` release `1.8.19`, installs it as `/usr/local/bin/xray`, and runs it as root. No Xray source, Go files, commit, or patch metadata is present, so custom modifications cannot be determined.

Generated services are `xray.service` (`config.json`) and `xray@.service` (`%i.json`). Observed configuration includes VLESS TCP 443 with TLS certificates, Vision flow, sniffing and fallbacks to port 82 and `/ws` to 1312; VLESS WebSocket non-TLS on 1313; VLESS WS TLS files; freedom outbound; StatsService; and blocked bittorrent. REALITY was not observed. Legacy Nginx config mentions VMess/Trojan/gRPC paths. Caddy proxies `/ws` to 1313 and other paths to SSH websocket 2082.

ACME is downloaded from `acme-install.netlify.app` and writes the Xray certificate/key. Account changes restart systemd services; no verified API reload caller or consistent config validation exists.
