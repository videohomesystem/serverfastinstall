#!/bin/bash
#
#        Hello message
#   /etc/profile.d/hello.sh
#
#
#"\033[93m\n yellow text -\e[1;37m white text \033[0m\n"
hostname=$(hostname) 
dspace=$(df -h / | awk 'NR==2{print "📦 " $2 " total | 💾 " $3 " used | 🆓 " $4 " free | 📊 " $5}')
uptime=$(uptime -p)
localip=$(hostname --ip-address)
#===================================
printf "\n\033[93m ####---- Welcome to \e[1;37m $hostname \033[93m ----#### \033[0m\n"
echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
printf "%b" "\033[93m Disk space: \e[1;37m $dspace \033[0m\n"
printf "\033[93m Uptime: \e[1;37m $uptime \033[0m\n"
printf "\033[93m IP: \e[1;37m $localip \033[0m\n"
printf " \033[0m"
echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
