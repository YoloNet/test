#!/bin/bash
#Autoscript-Lite By YoLoNET
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
none="$(cat ~/log-install.txt | grep -w "VLESS WS None TLS" | cut -d: -f2|sed 's/ //g')"

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
    local encoded_message=$(urlencode "$message")
    curl -s -X POST "$url" -d "chat_id=$chat_id" -d "text=$encoded_message" -d "parse_mode=Markdown"
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

# Restart Service
systemctl restart xray
systemctl restart xray@config
systemctl restart xray@vless
systemctl restart xray@none
service cron restart

vlesstls="vless://${uuid}@${domain}:${tls}?type=ws&encryption=none&security=tls&host=${domain}&path=/ws&allowInsecure=1&sni=${domain}#XRAY_VLESS_TLS_${user}"
vlessnontls="vless://${uuid}@${domain}:${none}?type=ws&encryption=none&security=none&host=${domain}&path=/ws#XRAY_VLESS_NON_TLS_${user}"

digi_apn="vless://${uuid}@mobile.useinsider.com:80?security=none&encryption=none&type=ws&headerType=none&path=/ws&host=${domain}#redvpn(Digi Apn)"
digi_booster="vless://${uuid}@162.159.133.61:80?security=none&encryption=none&type=ws&headerType=none&path=/ws&host=${domain}#redvpn(Digi Booster)"
celcom_booster="vless://${uuid}@104.17.148.22:80?security=none&encryption=none&type=ws&headerType=none&path=/ws&host=www.speedtest.net.${domain}#redvpn(Celcom 0Basic/Booster)"
maxis_sabah="vless://${uuid}@ookla.com:80?security=none&encryption=none&type=ws&headerType=none&path=/ws&host=${fastly_domain}#redvpn(Maxsit Bypass Sabah)"
maxis_freeze="vless://${uuid}@ookla.com:443?security=tls&encryption=none&type=ws&headerType=none&path=/ws&sni=ookla.com&host=${fastly_domain}#redvpn(Maxis Freeze)"
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
📱 Config 3 (Digi APN): 

\`\`\`
${digi_apn}
\`\`\`

==================================
🚀 Config 4 (Digi Booster): 

\`\`\`
${digi_booster}
\`\`\`

==================================
🔵 Config 5 (Celcom Booster): 

\`\`\`
${celcom_booster}
\`\`\`

==================================
📡 Config 6 (Maxis Sabah): 

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
✅ Done"

send_telegram_message "$telegram_message"

echo "Message sent to Telegram successfully!"

# Display info to user
clear
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