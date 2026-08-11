#!/bin/bash
#wget https://github.com/${GitUser}/


# // IZIN SCRIPT
export MYIP=$(curl -sS ipv4.icanhazip.com)
MYIP=$(curl -s ipinfo.io/ip )
MYIP=$(curl -sS ipv4.icanhazip.com)
MYIP=$(curl -sS ifconfig.me )
echo -e "\e[32mloading...\e[0m"
clear
echo -e "\e[32mloading...\e[0m"
clear

# // PROVIDED
export creditt=$(cat /root/provided)

# // TEXT ON BOX COLOUR
export box=$(cat /etc/box)

# // LINE COLOUR
export line=$(cat /etc/line)

# // BACKGROUND TEXT COLOUR
export back_text=$(cat /etc/back)

apply_user_speed_limit() {
    local username="$1"
    local limit_mbps="$2"
    local uid
    local iface
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

    uid=""
    for _ in 1 2 3 4 5; do
        uid=$(id -u "$username" 2>/dev/null)
        if [ -n "$uid" ]; then
            break
        fi
        sleep 1
    done
    if [ -z "$uid" ]; then
        echo -e "\e[31mUser '$username' not found. Unable to apply speed limit.\e[0m"
        return 1
    fi

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

    touch /root/user_speed_limits.txt
    grep -q "^${username}|${limit_mbps}$" /root/user_speed_limits.txt || echo "$username|${limit_mbps}" >> /root/user_speed_limits.txt

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

    echo "$username|$uid|$quota_bytes" >> "$quota_file"
    echo -e "\e[32mQuota limit set: $username = ${limit_gb} GB\e[0m"
}

clear
echo -e   "  \e[$line═══════════════════════════════════════════════════════\e[m"
echo -e   "  \e[$back_text           \e[30m[\e[$box CREATE USER SSH & OPENVPN\e[30m ]\e[1m               \e[m"
echo -e   "  \e[$line═══════════════════════════════════════════════════════\e[m"
read -p "   Username : " Login
read -p "   Password : " Pass
read -p "   Bug SNI/Host (Example : m.facebook.com) : " sni
read -p "   Expired (days): " masaaktif

domain=$(cat /usr/local/etc/xray/domain)

export ssl="$(cat ~/log-install.txt | grep -w "Stunnel4" | cut -d: -f2)"
export sqd="$(cat ~/log-install.txt | grep -w "Squid" | cut -d: -f2)"
export ovpn="$(netstat -nlpt | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)"
export ovpn2="$(netstat -nlpu | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)"
export ovpn3="$(cat ~/log-install.txt | grep -w "OHP OpenVPN" | cut -d: -f2|sed 's/ //g')"
export ovpn4="$(cat ~/log-install.txt | grep -w "OpenVPN SSL" | cut -d: -f2|sed 's/ //g')"
export ohpssh="$(cat ~/log-install.txt | grep -w "OHP SSH" | cut -d: -f2|sed 's/ //g')"
export ohpdrop="$(cat ~/log-install.txt | grep -w "OHP Dropbear" | cut -d: -f2|sed 's/ //g')"
export wsdropbear="$(cat ~/log-install.txt | grep -w "Websocket SSH(HTTP)" | cut -d: -f2|sed 's/ //g')"
export wsstunnel="$(cat ~/log-install.txt | grep -w "Websocket SSL(HTTPS)" | cut -d: -f2|sed 's/ //g')"
export wsovpn="$(cat ~/log-install.txt | grep -w "Websocket OpenVPN" | cut -d: -f2|sed 's/ //g')"
nsdomain1=$(cat /root/nsdomain)
pubkey1=$(cat /etc/slowdns/server.pub)

sleep 1
echo Ping Host
sleep 0.5
echo Create Acc: $Login
sleep 0.5
echo Setting Password: $Pass
sleep 0.5
clear

# // DATE
export harini=`date -d "0 days" +"%Y-%m-%d"`
useradd -e `date -d "$masaaktif days" +"%Y-%m-%d"` -s /bin/false -M $Login
export exp="$(chage -l $Login | grep "Account expires" | awk -F": " '{print $2}')"
export exp1=`date -d "$masaaktif days" +"%Y-%m-%d"`

cat > /home/vps/public_html/ssh-$Login.txt <<-END
====================================================================
             P R O J E C T  O F  N E V E R M O R E S S H
                       [Freedom Internet]
====================================================================
            https://github.com/yolonet/sapphire
====================================================================
              Format SSH OVPN Account - SPv2
====================================================================

====================================================================
Premium Account SSH & OpenVPN
====================================================================
Username         : $Login
Password         : $Pass
Created          : $harini
Expired          : $exp1
====================================================================
Domain           : $domain
Name Server(NS)  : $nsdomain1
Pubkey           : $pubkey1
IP/Host          : $MYIP
OpenSSH          : 22
Dropbear         : 143, 109
SSL/TLS          :$ssl
SlowDNS          : 22,80,443,53,5300
SSH-UDP          : 1-65535
WS SSH(HTTP)     : $wsdropbear
WS SSL(HTTPS)    : $wsstunnel
WS OpenVPN(HTTP) : $wsovpn
OHP Dropbear     : $ohpdrop
OHP OpenSSH      : $ohpssh
OHP OpenVPN      : $ovpn3
Port Squid       :$sqd
Badvpn(UDPGW)    : 7100-7300
====================================================================
CONFIG SSH WS
SSH 22      : $(cat /usr/local/etc/xray/domain):22@$Login:$Pass
SSH 80      : $(cat /usr/local/etc/xray/domain):80@$Login:$Pass
SSH 443     : $(cat /usr/local/etc/xray/domain):443@$Login:$Pass
SSH 1-65535 : $(cat /usr/local/etc/xray/domain):1-65535@$Login:$Pass
====================================================================
CONFIG OPENVPN
OpenVPN TCP : $ovpn http://$MYIP:81/client-tcp-$ovpn.ovpn
OpenVPN UDP : $ovpn2 http://$MYIP:81/client-udp-$ovpn2.ovpn
OpenVPN SSL : $ovpn4 http://$MYIP:81/client-tcp-ssl.ovpn
OpenVPN OHP : $ovpn3 http://$MYIP:81/client-tcp-ohp1194.ovpn
====================================================================
PAYLOAD WS       : GET / HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf][crlf]"
====================================================================
PAYLOAD WSS      : GET wss://$sni/ HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf][crlf]"
====================================================================
PAYLOAD WS OVPN  : GET wss://$sni/ HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf][crlf]"
====================================================================

END

echo -e "$Pass\n$Pass\n"|passwd $Login &> /dev/null

speed_limit_choice="n"
read -p "Limit speed for this user? [y/N]: " speed_limit_choice
if [[ "$speed_limit_choice" =~ ^[Yy]$ ]]; then
    while true; do
        read -p "Set speed limit in Mbps (example: 5): " speed_limit_value
        if [[ "$speed_limit_value" =~ ^[0-9]+$ ]] && (( speed_limit_value > 0 )); then
            apply_user_speed_limit "$Login" "$speed_limit_value"
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
            apply_user_quota "$Login" "$quota_limit_value"
            break
        fi
        echo -e "\e[31mInvalid value. Please enter a number greater than 0 GB.\e[0m"
    done
else
    echo -e "\e[33mNo quota cap applied. User has unlimited data.\e[0m"
fi

echo -e ""
echo -e "\e[$line═══════════════════════════════════════════════════════\e[m"
echo -e "\e[$back_text         \e[30m[\e[$box Premium Account SSH & OpenVPN\e[30m ]\e[1m           \e[m"
echo -e "\e[$line═══════════════════════════════════════════════════════\e[m"
echo -e "Username         : $Login"
echo -e "Password         : $Pass"
echo -e "Created          : $harini"
echo -e "Expired          : $exp1"
echo -e "\e[$line═══════════════════════════════════════════════════════\e[m"
echo -e "Domain           : $domain"
echo -e "Name Server(NS)  : $nsdomain1"
echo -e "Pubkey           : $pubkey1"
echo -e "IP/Host          : $MYIP"
echo -e "OpenSSH          : 22"
echo -e "Dropbear         : 143, 109"
echo -e "SSL/TLS          :$ssl"
echo -e "SlowDNS          : 22,80,443,53,5300"
echo -e "SSH-UDP          : 1-65535"
echo -e "WS SSH(HTTP)     : $wsdropbear"
echo -e "WS SSL(HTTPS)    : $wsstunnel"
echo -e "WS OpenVPN(HTTP) : $wsovpn"
echo -e "OHP Dropbear     : $ohpdrop"
echo -e "OHP OpenSSH      : $ohpssh"
echo -e "OHP OpenVPN      : $ovpn3"
echo -e "Port Squid       :$sqd"
echo -e "Badvpn(UDPGW)    : 7100-7300"
echo -e "\e[$line═══════════════════════════════════════════════════════\e[m"
echo -e "CONFIG SSH WS"
echo -e "SSH Config  : http://${domain}:81/ssh-$Login.txt"
echo -e "SSH 22      : $(cat /usr/local/etc/xray/domain):22@$Login:$Pass"
echo -e "SSH 80      : $(cat /usr/local/etc/xray/domain):80@$Login:$Pass"
echo -e "SSH 443     : $(cat /usr/local/etc/xray/domain):443@$Login:$Pass"
echo -e "SSH 1-65535 : $(cat /usr/local/etc/xray/domain):1-65535@$Login:$Pass"
echo -e "\e[$line═══════════════════════════════════════════════════════\e[m"
echo -e "CONFIG OPENVPN"
echo -e "--------------"
echo -e "OpenVPN TCP : $ovpn http://$MYIP:81/client-tcp-$ovpn.ovpn"
echo -e "OpenVPN UDP : $ovpn2 http://$MYIP:81/client-udp-$ovpn2.ovpn"
echo -e "OpenVPN SSL : $ovpn4 http://$MYIP:81/client-tcp-ssl.ovpn"
echo -e "OpenVPN OHP : $ovpn3 http://$MYIP:81/client-tcp-ohp1194.ovpn"
echo -e "\e[$line═══════════════════════════════════════════════════════\e[m"
echo -e "PAYLOAD WS       : GET / HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf][crlf]"
echo -e "\e[$line═══════════════════════════════════════════════════════\e[m"
echo -e "PAYLOAD WSS      : GET wss://$sni/ HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf][crlf]"
echo -e "\e[$line═══════════════════════════════════════════════════════\e[m"
echo -e "PAYLOAD WS OVPN  : GET wss://$sni/ HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf]Connection: Keep-Alive[crlf][crlf]"
echo -e "\e[$line═══════════════════════════════════════════════════════\e[m"
echo ""
read -n 1 -s -r -p "Press any key to back on menu SSH"
