#!/bin/bash
# Autoscript-Lite By YoLoNET
clear
red='\033[31;1m'
green='\033[32;1m'
purple='\033[35;1m'
orange='\033[33;1m'
tyblue='\033[36;1m'
NC='\033[0m'

domain=$(cat /root/yoloautosc/domain)
fastly_domain=$(cat /root/yoloautosc/fastly_domain)
tls="$(cat ~/log-install.txt | grep -w "VLESS WS TLS" | cut -d: -f2|sed 's/ //g')"
none="$(cat /root/log-install.txt | grep -w "VLESS WS None TLS" | cut -d: -f2|sed 's/ //g')"
tls="${tls:-443}"
none="${none:-80}"

# Function to URL encode a string
urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * )               printf -v o '%%%02x' "'$c"
        esac
        encoded+="${o}"
    done
    echo "${encoded}"
}

# Function to send message to Telegram
send_telegram_message() {
    local message="$1"
    local token=$(cat /root/yoloautosc/tele_token.txt)
    local chat_id=$(cat /root/yoloautosc/tele_id.txt)
    local url="https://api.telegram.org/bot$token/sendMessage"
    
    # Encode the message in UTF-8
    message=$(echo -n "$message" | jq -sRr @uri)
    
    # Send the message
    curl -s -X POST "$url" \
         -d "chat_id=$chat_id" \
         -d "text=$message" \
         -d "parse_mode=Markdown"
}

apply_user_speed_limit() {
    local username="$1"
    local limit_mbps="$2"
    local iface
    local uid
    local mark
    local rate_kbps
    local burst_kbps

    command -v tc >/dev/null 2>&1 || {
        apt-get update -y >/dev/null 2>&1
        apt-get install -y iproute2 >/dev/null 2>&1 || {
            echo -e "\e[31mUnable to install traffic control tools. Speed limit was not applied.\e[0m"
            return 1
        }
    }

    command -v iptables >/dev/null 2>&1 || {
        apt-get install -y iptables >/dev/null 2>&1 || {
            echo -e "\e[31mUnable to install iptables. Speed limit was not applied.\e[0m"
            return 1
        }
    }

    uid=$(id -u "$username" 2>/dev/null) || {
        echo -e "\e[31mUser '$username' not found. Unable to apply speed limit.\e[0m"
        return 1
    }

    iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
    if [ -z "$iface" ]; then
        echo -e "\e[31mUnable to detect default interface. Speed limit was not applied.\e[0m"
        return 1
    fi

    mark=$((1000 + uid))
    rate_kbps=$((limit_mbps * 1024))
    burst_kbps=$((rate_kbps * 2))

    tc qdisc show dev "$iface" 2>/dev/null | grep -q "htb" || tc qdisc add dev "$iface" root handle 1: htb default 1
    if ! tc class show dev "$iface" 2>/dev/null | grep -q "classid 1:${mark}"; then
        tc class add dev "$iface" parent 1: classid "1:${mark}" htb rate "${rate_kbps}kbit" ceil "${rate_kbps}kbit" burst "${burst_kbps}kbit"
    fi

    iptables -t mangle -C OUTPUT -m owner --uid-owner "$uid" -j MARK --set-mark "$mark" >/dev/null 2>&1 || \
    iptables -t mangle -A OUTPUT -m owner --uid-owner "$uid" -j MARK --set-mark "$mark"

    if ! tc filter show dev "$iface" parent 1: 2>/dev/null | grep -q "fwmark ${mark}"; then
        tc filter add dev "$iface" parent 1: protocol ip prio 1 handle "$mark" fw classid "1:${mark}"
    fi

    echo -e "\e[32mSpeed limit set: $username = ${limit_mbps} Mbps on interface $iface\e[0m"
}

apply_user_quota() {
    local username="$1"
    local limit_gb="$2"
    local uid
    local quota_bytes
    local quota_file="/root/user_quota_metadata.txt"

    command -v iptables >/dev/null 2>&1 || {
        apt-get install -y iptables >/dev/null 2>&1 || {
            echo -e "\e[31mUnable to install iptables. Quota was not applied.\e[0m"
            return 1
        }
    }

    uid=$(id -u "$username" 2>/dev/null) || {
        echo -e "\e[31mUser '$username' not found. Unable to apply quota.\e[0m"
        return 1
    }

    quota_bytes=$((limit_gb * 1024 * 1024 * 1024))

    iptables -t mangle -C OUTPUT -m owner --uid-owner "$uid" -m quota --quota "$quota_bytes" -j ACCEPT >/dev/null 2>&1 || \
    iptables -t mangle -I OUTPUT 1 -m owner --uid-owner "$uid" -m quota --quota "$quota_bytes" -j ACCEPT

    iptables -t mangle -C OUTPUT -m owner --uid-owner "$uid" -m comment --comment "quota-user:$username" -j DROP >/dev/null 2>&1 || \
    iptables -t mangle -I OUTPUT 2 -m owner --uid-owner "$uid" -m comment --comment "quota-user:$username" -j DROP

    touch "$quota_file"
    grep -q "^${username}|${uid}|${quota_bytes}$" "$quota_file" || echo "$username|$uid|$quota_bytes" >> "$quota_file"

    echo -e "\e[32mQuota limit set: $username = ${limit_gb} GB\e[0m"
}

# New function to ask if the user wants to send the config to Telegram
ask_send_to_telegram() {
    while true; do
        read -p "HANTAR CONFIG KE BOT Telegram? (y/n): " choice
        case "$choice" in
            y|Y ) return 0 ;;
            n|N ) return 1 ;;
            * ) echo "Please answer y or n." ;;
        esac
    done
}

until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\E[0;41;36m     Add XRAY Vless WS Account     \E[0m"
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

    read -rp "Username : " -e user
    CLIENT_EXISTS=$(grep -w $user /usr/local/etc/xray/vless.json | wc -l)

    if [[ ${CLIENT_EXISTS} == '1' ]]; then
        clear
        echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo -e "\E[0;41;36m      Add XRAY Vless Account       \E[0m"
        echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo ""
        echo "A client with the specified name was already created, please choose another name."
        echo ""
        exit 1
    fi
done

uuid=$(cat /proc/sys/kernel/random/uuid)
read -p "Expired (days): " masaaktif
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
hariini=`date -d "0 days" +"%Y-%m-%d"`

sed -i '/#tls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/vless.json

sed -i '/#none$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/none.json

sed -i '/#xhttp$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/xhttp.json

# Restart Service
systemctl restart xray
systemctl restart xray@config
systemctl restart xray@vless
systemctl restart xray@none
systemctl restart xray@xhttp
service cron restart

speed_limit_choice="n"
read -p "Limit speed for this user? [y/N]: " speed_limit_choice
if [[ "$speed_limit_choice" =~ ^[Yy]$ ]]; then
    while true; do
        read -p "Set speed limit in Mbps (example: 5): " speed_limit_value
        if [[ "$speed_limit_value" =~ ^[0-9]+$ ]] && (( speed_limit_value > 0 )); then
            apply_user_speed_limit "$user" "$speed_limit_value"
            break
        fi
        echo -e "\e[31mInvalid value. Please enter a number greater than 0 Mbps.\e[0m"
    done
else
    echo -e "\e[33mNo speed cap applied. User can use max speed.\e[0m"
fi

quota_limit_choice="n"
read -p "Limit quota for this user in GB? [y/N]: " quota_limit_choice
if [[ "$quota_limit_choice" =~ ^[Yy]$ ]]; then
    while true; do
        read -p "Set quota in GB (example: 10): " quota_limit_value
        if [[ "$quota_limit_value" =~ ^[0-9]+$ ]] && (( quota_limit_value > 0 )); then
            apply_user_quota "$user" "$quota_limit_value"
            break
        fi
        echo -e "\e[31mInvalid value. Please enter a number greater than 0 GB.\e[0m"
    done
else
    echo -e "\e[33mNo quota cap applied. User has unlimited data.\e[0m"
fi

vlesstls="vless://${uuid}@${domain}:${tls}?type=ws&encryption=none&security=tls&host=${domain}&path=/ws&sni=${domain}&allowInsecure=1#XRAY_VLESS_TLS_${user}"
vlessnontls="vless://${uuid}@${domain}:${none}?type=ws&encryption=none&security=none&host=${domain}&path=/ws#XRAY_VLESS_NON_TLS_${user}"
vlessxhttp="vless://${uuid}@${domain}:80?type=xhttp&encryption=none&mode=auto&path=%2Fxhttp&host=${domain}#XRAY_VLESS_XHTTP_${user}"
# Pre Made Configs
digi_apn="vless://${uuid}@mobile.useinsider.com:80?security=none&encryption=none&type=ws&headerType=none&path=/ws&host=${domain}#redvpn(Digi Apn)"
digi_booster="vless://${uuid}@162.159.133.61:80?security=none&encryption=none&type=ws&headerType=none&path=/ws&host=${domain}#redvpn(Digi Booster)"
celcom_booster="vless://${uuid}@104.17.148.22:80?security=none&encryption=none&type=ws&headerType=none&path=/ws&host=www.speedtest.net.${domain}#redvpn(Celcom 0Basic/Booster)"
maxis_sabah="vless://${uuid}@ookla.com:80?security=none&encryption=none&type=ws&headerType=none&path=/ws&host=${fastly_domain}#redvpn(Maxsit Bypass Sabah)"
maxis_freeze="vless://${uuid}@speedtest.net:443?security=tls&encryption=none&type=ws&headerType=none&path=/ws&sni=speedtest.net&host=${fastly_domain}#redvpn(Maxis Freeze)"
umobile_funz="vless://${uuid}@${domain}:80?security=none&encryption=none&type=ws&headerType=none&path=/ws&host=m.pubgmobile.com#redvpn(UMOBILE FUNZ)"
yes_exp_live="vless://${uuid}@104.17.113.188:80?security=none&encryption=none&type=ws&headerType=none&path=/ws&host=tap-database.who.int.${domain}#redvpn(Yes Exp/Live)"
unifi_bypass="vless://${uuid}@opensignal.com.${domain}:80?security=none&encryption=none&type=ws&headerType=none&path=/ws&host=opensignal.com.${domain}#redvpn(Unifi NoSub)"

clear
echo -e "Choose config to display:"
echo -e "1. Basic config"
echo -e "2. Maxis config"
echo -e "3. Digi Config"
echo -e "4. Celcom Config"
echo -e "5. Umobile config"
echo -e "6. Yes config"
echo -e "7. Unifi config"
echo -e "8. Show All Config"
read -p "Enter your choice (1-8): " config_choice

# Prepare the Telegram message
telegram_message="
==================================
👤 USER : ${user}
⏳ EXPIRE : ${exp}
==================================
"

case $config_choice in
    1)
        telegram_message+="🔒 Config 1 (VLESS TLS):
\`\`\`
${vlesstls}
\`\`\`
==================================
🔓 Config 2 (VLESS Non-TLS): 
\`\`\`
${vlessnontls}
\`\`\`
==================================
🌐 Config 3 (VLESS XHTTP): 
\`\`\`
${vlessxhttp}
\`\`\`"
        ;;
    2)
        telegram_message+="📡 Config 1 (Maxis Sabah):
\`\`\`
${maxis_sabah}
\`\`\`
==================================
❄️ Config 2 (Maxis Freeze): 
\`\`\`
${maxis_freeze}
\`\`\`"
        ;;
    3)
        telegram_message+="📱 Config 1 (Digi APN):
\`\`\`
${digi_apn}
\`\`\`
==================================
🚀 Config 2 (Digi Booster): 

\`\`\`
${digi_booster}
\`\`\`"
        ;;
    4)
        telegram_message+="🔵 Config (Celcom Booster):
\`\`\`
${celcom_booster}
\`\`\`"
        ;;
    5)
        telegram_message+="🎮 Config (Umobile Funz):
\`\`\`
${umobile_funz}
\`\`\`"
        ;;
    6)
        telegram_message+="✅ Config (Yes Exp/Live):
\`\`\`
${yes_exp_live}
\`\`\`"
        ;;
    7)
        telegram_message+="🌐 Config (Unifi Bypass):
\`\`\`
${unifi_bypass}
\`\`\`"
        ;;
    8)
        telegram_message+="🔒 Config 1 (VLESS TLS):
\`\`\`
${vlesstls}
\`\`\`
==================================
🔓 Config 2 (VLESS Non-TLS): 
\`\`\`
${vlessnontls}
\`\`\`
==================================
🌐 Config 3 (VLESS XHTTP): 
\`\`\`
${vlessxhttp}
\`\`\`
==================================
📱 Config 4 (Digi APN): 
\`\`\`
${digi_apn}
\`\`\`
==================================
🚀 Config 5 (Digi Booster): 
\`\`\`
${digi_booster}
\`\`\`
==================================
🔵 Config 6 (Celcom Booster): 
\`\`\`
${celcom_booster}
\`\`\`
==================================
📡 Config 7 (Maxis Sabah): 
\`\`\`
${maxis_sabah}
\`\`\`
==================================
❄️ Config 7 (Maxis Freeze): 
\`\`\`
${maxis_freeze}
\`\`\`
==================================
🎮 Config 8 (Umobile Funz): 
\`\`\`
${umobile_funz}
\`\`\`
==================================
✅ Config 9 (Yes Exp/Live): 
\`\`\`
${yes_exp_live}
\`\`\`
==================================
🌐 Config 10 (Unifi Bypass): 
\`\`\`
${unifi_bypass}
\`\`\`"
        ;;
    *)
        telegram_message+="🔒 Config 1 (VLESS TLS):
\`\`\`
${vlesstls}
\`\`\`
==================================
🔓 Config 2 (VLESS Non-TLS): 
\`\`\`
${vlessnontls}
\`\`\`"
        ;;
esac
telegram_message+="
==================================
🖥️ Server by : @redvpn121
📢 Channel : @nolimitdata
👥 Group : @redvpngroup
==================================
⚠️ FOLLOW RULES OR BAN !
🚫 NO TORRENT
🚷 NO SHARING ID/MULTILOGIN
🔒 NO HACKING/ILLEGAL USE
🎮 NO PS4/XBOX
==================================
"

if ask_send_to_telegram; then
    send_telegram_message "$telegram_message"
    echo "Message sent to Telegram successfully!"
else
    echo "Message not sent to Telegram."
fi

# Display info to user

echo -e ""
echo -e "════════════[XRAY VLESS WS]════════════"
echo -e "Remarks           : ${user}"
echo -e "Domain            : ${domain}"
echo -e "Port TLS          : ${tls}"
echo -e "Port None TLS     : ${none}"
echo -e "ID                : ${uuid}"
echo -e "Security          : TLS"
echo -e "Encryption        : None"
echo -e "Network           : WS"
echo -e "Path TLS          : /ws"
echo -e "Path NTLS         : /ws"
echo -e "═══════════════════════════════════════"
echo -e "Link WS TLS       : ${vlesstls}"
echo -e "═══════════════════════════════════════"
echo -e "Link WS None TLS  : ${vlessnontls}"
echo -e "════════════════════════════════════════"
echo -e "Created On        : $hariini"
echo -e "Expired On        : $exp"
echo -e "═══════════════════════════════════════"
echo -e ""
echo -e "Autoscript By YoLoNET"
echo -e ""
