#!/bin/bash

TELEGRAM_BOT_TOKEN=$(cat /root/yoloautosc/tele_token.txt 2>/dev/null)
TELEGRAM_CHAT_ID=$(cat /root/yoloautosc/tele_id.txt 2>/dev/null)
QUOTA_FILE="/root/user_quota_metadata.txt"
LOG_FILE="/var/log/quota_check.log"

send_telegram_message() {
    local message="$1"
    [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ] || return 0
    curl -fsSL -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        --data-urlencode "chat_id=$TELEGRAM_CHAT_ID" \
        --data-urlencode "text=$message" >/dev/null 2>&1 || true
}

if [ ! -f "$QUOTA_FILE" ]; then
    exit 0
fi

while IFS='|' read -r username uid quota_bytes; do
    [ -n "$username" ] || continue
    if ! id "$username" >/dev/null 2>&1; then
        continue
    fi

    if ! command -v vnstat >/dev/null 2>&1; then
        continue
    fi

    user_bytes=$(vnstat --json 2>/dev/null | jq -r --arg user "$username" '.interfaces[]?.traffic[]? | select(.name == $user) | .total' 2>/dev/null || true)
    if [ -z "$user_bytes" ]; then
        user_bytes=$(vnstat -i eth0 2>/dev/null | awk '/total/ {print $2}' | head -n 1 2>/dev/null || echo 0)
    fi

    if [ -n "$user_bytes" ] && [ "$user_bytes" != "null" ]; then
        if [ "$user_bytes" -ge "$quota_bytes" ]; then
            usermod -L "$username" >/dev/null 2>&1 || true
            echo "$(date '+%F %T') Quota exceeded for $username ($user_bytes bytes >= $quota_bytes)" >> "$LOG_FILE"
            send_telegram_message "Quota exceeded for user: $username. Data used: $((user_bytes / 1024 / 1024 / 1024)) GB / ${quota_bytes%??} GB. Account locked."
        fi
    fi
done < "$QUOTA_FILE"
