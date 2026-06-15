#!/bin/bash
#   1 - Очистить /etc/motd                => cat /dev/null > /etc/motd
#   2 - Создать /etc/profile.d/hello.sh   => touch /etc/profile.d/hello.sh
#   3 - Скопировать ВСЁ В /etc/profile.d/hello.sh
#
#        Приветственный SSH логон-скрипт
#        Выполняется в > /etc/profile.d/hello.sh
#        Протестировано: Debian 13, Astra 1.7.x
#
#"\033[93m\n yellow text -\e[1;37m white text \033[0m\n"
#

hostname=$(hostname) 
dspace=$(df -h / | awk 'NR==2{print "📦 " $2 " total | 💾 " $3 " used | 🆓 " $4 " free | 📊 " $5}')
uptime=$(uptime -p)

# ----------- FIX: корректное получение списка адресов -----------
# Вместо hostname --all-ip-addresses
localv4_list=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.')
localv6_list=$(ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' | grep -v '^::1' | grep -v '^fe80:')
if [ -z "$localv6_list" ]; then localv6_list="N\A"; fi
# ----------------------------------------------------------------
# Если адресов нет, подставляем N/A
if [ -z "$localv4_list" ]; then localv4_list="N\A"; fi
if [ -z "$localv6_list" ]; then localv6_list="N\A"; fi
# ----------------------------------------------------------------
#ufws=$(ufw status verbose)
#fail2=$(fail2ban-client status | grep 'banned')
# ----------------------------------------------------------------
clear
#-
printf "\n\e[1;37m------------------------*|||*------------------------\033[0m\n"
printf "\n\033[93m [---- Welcome to\e[1;37m > $hostname <\033[93m ----] \033[0m\n"
echo " "

# Вывод IPv4 (каждый с новой строки)
printf "\033[93m IPv4:\033[0m\n"
echo "$localv4_list" | while IFS= read -r ip; do
    printf "   \e[1;37m%s\033[0m\n" "$ip"
done

# Вывод IPv6 (каждый с новой строки)
printf "\033[93m IPv6:\033[0m\n"
echo "$localv6_list" | while IFS= read -r ip; do
    printf "   \e[1;37m%s\033[0m\n" "$ip"
done

echo " "
printf "%b" "\033[93m Disk space: \e[1;37m $dspace \033[0m\n"
printf "\033[93m Uptime: \e[1;37m $uptime \033[0m\n"
printf "\n\e[1;37m------------------------*...*------------------------\033[0m\n"
printf "\033[93mto edit: \e[1;37m/etc/profile.d/hello.sh\033[0m\n"
#printf "\033[93m*-=-=-=-=-=-=-=-=-\e[1;37m> UFW STATUS <\033[93m-=-=-=-=-=-=-=-=-* \033[0m\n"
#printf "%b" "\033[93m ufw: \e[1;37m $ufws \033[0m"
printf "\n\e[1;37m------------------------*...*------------------------\033[0m\n"
