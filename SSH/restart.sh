#!/bin/bash
#Autoscript-Lite By YoLoNET
clear

restart_service() {
    local svc="$1"
    if systemctl list-unit-files "$svc.service" >/dev/null 2>&1; then
        systemctl restart "$svc.service" >/dev/null 2>&1 || true
    elif systemctl list-unit-files "$svc" >/dev/null 2>&1; then
        systemctl restart "$svc" >/dev/null 2>&1 || true
    elif command -v service >/dev/null 2>&1; then
        service "$svc" restart >/dev/null 2>&1 || true
    fi
}

restart_service ssh
restart_service dropbear
restart_service stunnel4
restart_service cron
restart_service nginx
restart_service squid
restart_service fail2ban
restart_service openvpn
restart_service openvpn-server@server-tcp-1194
restart_service openvpn-server@server-udp-2200
restart_service xray
restart_service xray@none
restart_service xray@config
restart_service xray@vless
restart_service xray@xhttp
restart_service ws-http
restart_service ws-https
restart_service ohp
restart_service ohpd
restart_service ohps

screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 1000
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 1000
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;41;36m       All Services Restarted      \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
sleep 1
clear