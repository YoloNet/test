# IP Restriction Audit

- `setup-lite.sh` prints “CHECKING IP PERMISSION” and performs root/OpenVZ checks, but the visible code has no local license decision.
- SSH scripts source `/var/lib/premium-script/ipvps.conf`, storing an `IP=` value based on the supplied host/domain; trial flow prints “Permission Accepted.” Full authorization meaning is uncertain.
- `BACKUP/backupgithub.sh` fetches a GitHub `access` list and matches public IP to derive a customer name. This is a real external IP-bound backup dependency.
- `OTHERS/nginx.conf` trusts hardcoded Cloudflare ranges for `CF-Connecting-IP`; this is proxy client-IP handling, not license authorization.

No explicit Xray client IP whitelist/blacklist was found. Do not remove `ipvps.conf` or GitHub access behavior until live callers and remote installer behavior are captured.
