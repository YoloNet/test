# User Management Audit

Xray users are identified by username marker and ordinal list position, not an internal ID or database record. UUIDs are in JSON client objects. Expiry/name are marker comments `### username YYYY-MM-DD`; VLESS WS also uses username as JSON email. SSH users are separate Linux accounts.

- Add VLESS: `XRAY/add-vless.sh` validates a name, generates a kernel UUID, computes expiry, inserts into `vless.json` and `none.json` with `sed`, restarts units, prints links/YAML, and optionally sends Telegram.
- Trial: `add-trialvless.sh` creates a random name/UUID with one-day expiry, updates both files, restarts, and sends Telegram.
- Delete: `del-vless.sh` removes marker-to-client blocks from both files, deletes YAML, and restarts `xray@vless`/`xray@none`.
- Renew: `renew-vless.sh` extends remaining plus requested days and updates both markers; it restarts `xray@vless` and likely legacy/typo `xray@vnone`.
- TCP Vision-named flow: `add-xray.sh`, `del-xray.sh`, `renew-xray.sh`, `cek-xray.sh`, and `user-xray.sh` operate against `config.json`, marker order, and YAML, while also referencing legacy `xtls.json`/`xray@xtls`.

There is no general edit, rename, UUID-change, or first-class search. Expiry is metadata and is not verified as enforced by Xray. Changes use text mutation/restarts without atomic writes, schema validation, rollback, or consistent errors.
