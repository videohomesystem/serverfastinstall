#!/bin/bash
#   1 - clear /etc/motd                => cat /dev/null > /etc/motd
#   2 - create /etc/profile.d/hello.sh => touch /etc/profile.d/hello.sh
#   4 - copy ALL to /etc/profile.d/hello.sh
#   3 - enjoy!
#
#        Hello message
#        execute > /etc/profile.d/hello.sh
#        tested on Denian 13
#"\033[93m\n yellow text -\e[1;37m white text \033[0m\n"
#
hostname=$(hostname) 
dspace=$(df -h / | awk 'NR==2{print "📦 " $2 " total | 💾 " $3 " used | 🆓 " $4 " free | 📊 " $5}')
uptime=$(uptime -p)
localip=$(hostname --ip-address)
ufws=$(ufw status verbose)
#fail2=$(fail2ban-client status | grep 'banned')
#echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
printf "\n\e[1;37m------------------------*|||*------------------------\033[0m\n"
printf "\n\033[93m [[[[---- Welcome to\e[1;37m> $hostname <\033[93m ----]]]] \033[0m\n"
echo " "
printf "%b" "\033[93m Disk space: \e[1;37m $dspace \033[0m\n"
printf "\033[93m Uptime: \e[1;37m $uptime \033[0m\n"
printf "\033[93m IP: \e[1;37m $localip \033[0m\n"
printf "\033[93m*-=-=-=-=-=-=-=-=-\e[1;37m> UFW STATUS <\033[93m-=-=-=-=-=-=-=-=-* \033[0m\n"
printf "%b" "\033[93m ufw: \e[1;37m $ufws \033[0m"
printf "\n\e[1;37m------------------------*...*------------------------\033[0m\n"
