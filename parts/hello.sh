#!/bin/bash
#
#        hello SSH logon script
#        Execute in > /etc/profile.d/hello.sh
#        Tested: Debian 13, but 100% work ANY Linux distribs
#
#------------------------
# Проверка: запускаемся только если есть SSH-соединение
  if [ -z "$SSH_CONNECTION" ] && [ -z "$SSH_TTY" ]; then
      # Если переменные SSH не установлены - выходим без вывода
      exit 0
  fi
#------------------------
C_YELLOW="\033[93m"
C_WHITE="\e[1;37m"
C_RESET="\033[0m"
#------------------------
dspace=$(df -h / | awk 'NR==2{print "📦 " $2 " total | 💾 " $3 " used | 🆓 " $4 " free | 📊 " $5}')
uptime=$(uptime -p)
# ----------------------
# do not use: hostname --all-ip-addresses
localv4_list=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.')
localv6_list=$(ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' | grep -v '^::1' | grep -v '^fe80:')
if [ -z "$localv6_list" ]; then localv6_list="N\A"; fi
# ----------------------------------------------------------------
# if adress NULL = N/A
if [ -z "$localv4_list" ]; then localv4_list="N\A"; fi
if [ -z "$localv6_list" ]; then localv6_list="N\A"; fi
# ----------------------------------------------------------------
# ufws=$(ufw status verbose)
# fail2=$(fail2ban-client status | grep 'banned')
# ----------------------------------------------------------------
clear
#-
  printf "\n${C_WHITE}------------------------*||*------------------------${C_RESET}\n"
  printf "\n${C_YELLOW}[---- Welcome to ${C_WHITE}> $HOSTNAME < ${C_YELLOW}----]${C_RESET}\n"
  echo " "
  # IPv4
printf "${C_YELLOW} IPv4:${C_RESET}\n"
echo "$localv4_list" | while IFS= read -r ip; do
printf "   ${C_WHITE}%s${C_RESET}\n" "$ip"
done
  # IPv6
printf "${C_YELLOW} IPv6:${C_RESET}\n"
echo "$localv6_list" | while IFS= read -r ip; do
 printf "   ${C_WHITE}%s${C_RESET}\n" "$ip"
done
printf "%b" "${C_YELLOW} Disk space: ${C_WHITE} $dspace ${C_RESET}\n"
printf "${C_YELLOW} Uptime: ${C_WHITE} $uptime ${C_RESET}\n"
  # printf "\n${C_WHITE}------------------------*...*------------------------${C_RESET}\n"
  # printf "${C_YELLOW}to edit: ${C_WHITE}/etc/profile.d/hello.sh${C_RESET}"
  # printf "${C_YELLOW}*-=-=-=-=-=-=-=-=-${C_WHITE}> INFO <${C_YELLOW}-=-=-=-=-=-=-=-=-* ${C_RESET}\n"
printf "\n${C_WHITE} try ${C_YELLOW} last ${C_WHITE} to display all ssh sessions and ${C_YELLOW} grep | 'USERNAME' ${C_RESET}\n"
printf "\n${C_WHITE}------------------------*...*------------------------${C_RESET}\n"
