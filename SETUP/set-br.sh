#!/bin/bash
# Set-Backup Installation
# By YoLoNET
#-----------------------------
clear
red='\033[31;1m'
green='\033[32;1m'
purple='\033[35;1m'
orange='\033[33;1m'
tyblue='\033[36;1m'
NC='\033[0m'

green() { printf '%b' "${green}${*}${NC}"; }
red() { printf '%b' "${red}${*}${NC}"; }

Server_URL="$(cat /root/install_link.txt )"

curl https://rclone.org/install.sh | bash
printf "q\n" | rclone config
wget -O /root/.config/rclone/rclone.conf "https://${Server_URL}/rclone.conf"
git clone  https://github.com/MrMan21/wondershaper.git
cd wondershaper
make install
cd
rm -rf wondershaper
cd /usr/bin
wget -O backup "https://${Server_URL}/BACKUP/backup.sh"
wget -O backupgithub "https://${Server_URL}/BACKUP/backupgithub.sh"
wget -O backup_tele "https://${Server_URL}/BACKUP/backup_tele.sh"
wget -O restore "https://${Server_URL}/BACKUP/restore.sh"
wget -O restoregithub "https://${Server_URL}/BACKUP/restoregithub.sh"
wget -O restore_tele "https://${Server_URL}/BACKUP/restore_tele.sh"
wget -O cleaner "https://${Server_URL}/BACKUP/logcleaner.sh"
wget -O kumbang "https://${Server_URL}/OTHERS/kumbang.sh"
chmod +x /usr/bin/backup
chmod +x /usr/bin/backupgithub
chmod +x /usr/bin/restore
chmod +x /usr/bin/restoregithub
chmod +x /usr/bin/cleaner
chmod +x /usr/bin/kumbang
chmod +x /usr/bin/backup_tele
chmod +x /usr/bin/restore_tele
cd
if [ ! -f "/etc/cron.d/cleaner" ]; then
cat> /etc/cron.d/cleaner << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/2 * * * * root /usr/bin/cleaner
END
fi
service cron restart > /dev/null 2>&1
rm -f /root/set-br.sh