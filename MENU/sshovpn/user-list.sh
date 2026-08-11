# Created by ReddvpnSSH
#wget https://github.com/${GitUser}/

#IZIN SCRIPT
MYIP=$(curl -sS ipv4.icanhazip.com)
MYIP=$(curl -s ipinfo.io/ip )
MYIP=$(curl -sS ipv4.icanhazip.com)
MYIP=$(curl -sS ifconfig.me )
echo -e "\e[32mloading...\e[0m"
clear
# Valid Script

get_user_speed_limit() {
    local user="$1"
    if [ -f /root/user_speed_limits.txt ]; then
        local speed_limit
        speed_limit=$(grep -E "^${user}\|" /root/user_speed_limits.txt 2>/dev/null | head -n 1 | cut -d'|' -f2)
        if [ -n "$speed_limit" ]; then
            echo "$speed_limit Mbps"
            return
        fi
    fi
    echo "Unlimited"
}

get_user_quota_used() {
    local user="$1"
    local quota_val
    local quota_bytes
    local used_bytes
    local used_gb

    if [ -f /root/user_quota_metadata.txt ]; then
        quota_val=$(grep -E "^${user}\|" /root/user_quota_metadata.txt 2>/dev/null | head -n 1 | cut -d'|' -f3)
        if [ -n "$quota_val" ]; then
            quota_bytes="$quota_val"
            used_bytes=$(iptables -L OUTPUT -t mangle -n -v 2>/dev/null | awk -v user="$user" '
                $0 ~ "quota-user:" user {
                    for (i=1; i<=NF; i++) {
                        if ($i ~ /bytes/) {
                            print $(i-1)
                            exit
                        }
                    }
                }
            ' | head -n 1)
            if [ -n "$used_bytes" ] && [ "$used_bytes" != "0" ]; then
                used_gb=$(awk -v bytes="$used_bytes" 'BEGIN { printf "%.2f", bytes / 1024 / 1024 / 1024 }')
                echo "${used_gb} GB"
                return
            fi
            echo "0.00 GB"
            return
        fi
    fi
    echo "-"
}

clear
if [ -f /etc/debian_version ]; then
	UIDN=1000
elif [ -f /etc/redhat-release ]; then
	UIDN=500
else
	UIDN=500
fi
clear
echo " "
echo " "
echo "===========================================";
echo " "
echo "-----------------------------------"
echo "        USER ACCOUNTS LIST         "
echo "-----------------------------------"
echo "[USERNAME]   -   [DATE EXPIRED]  -  [SPEED]  -  [QUOTA USED]"
echo " "
while read ceklist
do
        AKUN="$(echo $ceklist | cut -d: -f1)"
        ID="$(echo $ceklist | grep -v nobody | cut -d: -f3)"
        exp="$(chage -l $AKUN | grep "Account expires" | awk -F": " '{print $2}')"
        if [[ $ID -ge $UIDN ]]; then
        speed_limit="$(get_user_speed_limit "$AKUN")"
        quota_used="$(get_user_quota_used "$AKUN")"
        printf "%-17s %-16s %-12s %-10s\n" "$AKUN" "$exp" "$speed_limit" "$quota_used"
        fi
done < /etc/passwd
JUMLAH="$(awk -F: '$3 >= '$UIDN' && $1 != "nobody" {print $1}' /etc/passwd | wc -l)"
echo "-------------------------------------"
echo "Number Of User Accounts: $JUMLAH USERS"
echo "-------------------------------------"
echo " "
echo "===========================================";
echo " ";
