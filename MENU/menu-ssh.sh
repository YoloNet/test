#!/bin/bash
# Simple SSH & OpenVPN Menu (Plain Text)

clear
MYIP=$(wget -qO- ifconfig.me/ip)

echo ""
echo "==============================================="
echo "            SSH & OpenVPN MENU                 "
echo "==============================================="
echo "  (1)  Create SSH & OpenVPN Account"
echo "  (2)  Trial Account SSH & OpenVPN"
echo "  (3)  Renew SSH & OpenVPN Account"
echo "  (4)  Delete SSH & OpenVPN Account"
echo "  (5)  Check User Login SSH & OpenVPN"
echo "  (6)  List Member SSH & OpenVPN"
echo "  (7)  Delete Expired SSH & OpenVPN User"
echo "  (8)  Setup AutoKill SSH"
echo "  (9)  Check Multi-Login Users SSH"
echo " (10)  User List"
echo " (11)  User Lock"
echo " (12)  User Unlock"
echo " (13)  Change User Password"
echo " (14)  Restart Dropbear, Squid, OpenVPN, SSH"
echo ""
echo "==============================================="
echo "   (x)  Back to Main Menu"
echo "==============================================="
echo ""
read -p "   Please Input Number [1-14 or x]: " ssh
echo ""

case $ssh in
  1) add-ssh ;;
  2) trial ;;
  3) renew-ssh ;;
  4) del-ssh ;;
  5) cek-ssh ;;
  6) member ;;
  7) delete ;;
  8) autokill ;;
  9) ceklim ;;
  10) user-list ;;
  11) user-lock ;;
  12) user-unlock ;;
  13) user-password ;;
  14) restart ;;
  x) menu ;;
  *) echo "Please enter a correct number" ;;
esac
