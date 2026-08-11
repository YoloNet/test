#!/bin/bash

TELEGRAM_BOT_TOKEN=$(cat /root/yoloautosc/tele_token.txt 2>/dev/null)
TELEGRAM_CHAT_ID=$(cat /root/yoloautosc/tele_id.txt 2>/dev/null)
CPU_LIMIT=85
MEM_LIMIT=80
PROXY_LIMIT=20
LOG_FILE="/var/log/anti-highusage.log"

send_telegram_message() {
    local message="$1"
    [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ] || return 0
    curl -fsSL -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        --data-urlencode "chat_id=$TELEGRAM_CHAT_ID" \
        --data-urlencode "text=$message" >/dev/null 2>&1 || true
}

get_server_ip() {
    hostname -I | awk '{print $1}'
}

restart_proxy_services() {
    echo "$(date '+%F %T') Restarting proxy services due to high load" >> "$LOG_FILE"

    systemctl stop ws-http ws-https ws-ovpn 2>/dev/null || true
    pkill -f "/usr/local/bin/ws-http\|/usr/local/bin/ws-https\|/usr/local/bin/ws-ovpn" 2>/dev/null || true
    sleep 1

    systemctl restart ws-http ws-https ws-ovpn 2>/dev/null || true
    systemctl restart xray.service xray@config.service xray@none.service xray@vless.service 2>/dev/null || true
    systemctl restart nginx 2>/dev/null || true
    sleep 2
}

check_usage() {
    local cpu_usage mem_usage proxy_count

    cpu_usage=$(top -bn1 | awk '/%Cpu/ {print $2 + $4 + $6 + $8}' | cut -d. -f1 | head -n 1)
    mem_usage=$(free | awk '/Mem/{printf("%.0f", $3/$2*100)}')
    proxy_count=$(ps -eo comm --no-headers | grep -E "ws-http|ws-https|ws-ovpn|xray" | wc -l)

    echo "CPU Usage: ${cpu_usage:-0}%"
    echo "Memory Usage: ${mem_usage:-0}%"
    echo "Proxy/Xray count: $proxy_count"

    if [ "${cpu_usage:-0}" -gt "$CPU_LIMIT" ] || [ "${mem_usage:-0}" -gt "$MEM_LIMIT" ] || [ "$proxy_count" -gt "$PROXY_LIMIT" ]; then
        local ip
        ip=$(get_server_ip)
        send_telegram_message "Server $ip triggered auto-recovery: CPU=${cpu_usage:-0}% MEM=${mem_usage:-0}% ProxyCount=${proxy_count}. Restarting proxy/Xray services."
        restart_proxy_services

        cpu_usage_after=$(top -bn1 | awk '/%Cpu/ {print $2 + $4 + $6 + $8}' | cut -d. -f1 | head -n 1)
        mem_usage_after=$(free | awk '/Mem/{printf("%.0f", $3/$2*100)}')

        echo "After restart: CPU=${cpu_usage_after:-0}% MEM=${mem_usage_after:-0}%"

        if [ "${cpu_usage_after:-0}" -gt "$CPU_LIMIT" ] || [ "${mem_usage_after:-0}" -gt "$MEM_LIMIT" ]; then
            send_telegram_message "Server $ip still overloaded after auto-recovery. Rebooting system."
            reboot
        fi
    else
        echo "CPU and Memory usage are within limits."
    fi
}

check_usage
