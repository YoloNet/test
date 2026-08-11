#!/bin/bash
# Caddy + Xray universal setup script
# Tested on Debian/Ubuntu based systems

set -e

# Step 1: Install Caddy
echo "[*] Installing Caddy..."
apt install caddy -y

# Step 2: Create log directory
mkdir -p /var/log/caddy
chown -R caddy:caddy /var/log/caddy

# Step 3: Write Caddy configuration
cat >/etc/caddy/Caddyfile <<'EOF'
# Universal Caddy configuration with Xray VLESS + SSH WebSocket

:80, :8080 {
    # Route for Xray VLESS connections (WebSocket path /ws)
    @xray_vless {
        path /ws*
    }

    # Route for Xray XHTTP traffic
    @xray_xhttp {
        path /xhttp*
    }

    # Route for SSH WebSocket connections (anything not /ws or /xhttp)
    @ssh_websocket {
        not path /ws* /xhttp*
    }

    # Handle Xray VLESS WebSocket connections
    handle @xray_vless {
        reverse_proxy 127.0.0.1:1313 {
            transport http {
                read_timeout 0
                write_timeout 0
                keepalive 300s
                keepalive_idle_conns 100
            }

            # Pass ALL headers for Xray
            header_up * {http.request.header.*}
            flush_interval -1
        }
    }

    # Handle Xray XHTTP connections
    handle @xray_xhttp {
        reverse_proxy 127.0.0.1:10080 {
            transport http {
                read_timeout 0
                write_timeout 0
                keepalive 300s
                keepalive_idle_conns 100
            }

            header_up * {http.request.header.*}
            flush_interval -1
        }
    }

    # Handle SSH WebSocket connections
    handle @ssh_websocket {
        reverse_proxy 127.0.0.1:2082 {
            transport http {
                read_timeout 300s
                write_timeout 300s
                keepalive 300s
            }

            # Inject real client IP headers
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
        }
    }

    # Fallback for any other requests
    handle {
        respond "Service Available" 200
    }
}

# Alternative configuration with explicit domain
domain.com:80 {
    reverse_proxy 127.0.0.1:2082 {
        transport http {
            keepalive 30s
            keepalive_idle_conns 10
        }

        header_up Connection {http.request.header.Connection}
        header_up Upgrade {http.request.header.Upgrade}
        header_up Sec-WebSocket-Key {http.request.header.Sec-WebSocket-Key}
        header_up Sec-WebSocket-Version {http.request.header.Sec-WebSocket-Version}
        header_up Host {http.request.header.Host}
        header_up User-Agent {http.request.header.User-Agent}
    }
}

EOF

# Step 4: Restart & enable Caddy
echo "[*] Restarting Caddy..."
systemctl daemon-reload
systemctl enable caddy
systemctl restart caddy

echo "[+] Caddy installation & configuration complete!"
echo "    Config file: /etc/caddy/Caddyfile"
echo "    Logs:        /var/log/caddy/universal-xray.log"
