# Encoded and Obfuscated Files

No Base64, encrypted shell payload, hex source, decoded `eval` program, or compressed-script wrapper was found. `gzip` in Nginx is HTTP compression. `source` calls load plain config files.

Native/opaque payloads are `badvpn-udpgw64`, `SETUP/ohp`, `ohpd`, `ohps`, websocket executables, and `SSHWS-SETUP/vpn.zip`. Their source and provenance are absent. Dynamic downloads and generated configs are supply-chain/generation behavior, not encoding.
