#!/bin/bash
#Autoscript-Lite By YoLoNET
clear
red='\033[31;1m'
green='\033[32;1m'
purple='\033[35;1m'
orange='\033[33;1m'
tyblue='\033[36;1m'
NC='\033[0m'
rm -f /var/lib/crot-script/ipvps.conf
rm -f /var/lib/premium-script/ipvps.conf
rm -f /usr/local/etc/xray/domain
rm -f /root/yoloautosc/domain
echo -e "Please Insert  Your Domain"
read -p "Hostname / Domain: " host
echo "$host" > /usr/local/etc/xray/domain
echo "$host" > /root/yoloautosc/domain
clear
echo -e "Renew Certificate Started . . . ."
echo start
sleep 0.5
domain=$(cat /root/yoloautosc/domain)
systemctl stop nginx
systemctl stop xray.service
systemctl stop xray@none.service
systemctl stop xray@vless.service
systemctl stop xray@xtls.service
echo -e "[ ${green}INFO${NC} ] Starting renew cert... "
rm -r /root/.acme.sh
sleep 1 
mkdir /root/.acme.sh
curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
chmod +x /root/.acme.sh/acme.sh
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d $domain -d sshws.$domain --standalone -k ec-256 --listen-v6
~/.acme.sh/acme.sh --installcert -d $domain -d sshws.$domain --fullchainpath /usr/local/etc/xray/xray.crt --keypath /usr/local/etc/xray/xray.key --ecc
chmod 755 /usr/local/etc/xray/xray.key;
service squid start
systemctl restart nginx
sleep 0.5;
clear;
echo -e "[ ${green}INFO${NC} ] Restart All Service" 
systemctl restart nginx
sleep 0.3
systemctl restart xray.service
sleep 0.3
systemctl restart xray@none.service
sleep 0.3
systemctl restart xray@vless.service
sleep 0.3
systemctl restart xray@xtls.service
sleep 0.3
echo -e "[ ${green}INFO${NC} ] All finished !" 
clear 
neofetch
echo ""
