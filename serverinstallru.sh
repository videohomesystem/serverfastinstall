#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   printf "${C_WHITE} run script as${C_YELLOW} root${C_RESET}\n"
   exit 1
fi
#============================================================================================================================
# RU --------------------- Скрипт делает основные действительно важные вещи, далее - сами.
# А че делаем?
# - вносим изменения в сорц.лист, т.к. он пустой
# - обновляемся
# - ставим аппсы: apt-transport-https, ca-certificates, после - fail2ban, mcedit, curl
# - поскольку у нас подразумевается лень и\или обычный юзер - руками apt upgrade никто не делает - автоматизируем сервисами, нативно, без софта
# - напомню, что обновления, это ОЧЕНЬ важно
# - вносим очень важный твик ядра, который --ЗНАЧИТЕЛЬНО-- увеличит производительность сетевой составляющей сервера, это особенно заметно, если подключений будет >> несколько
# - чистим старые пакеты
# - ставим 3x-ui и отдаем управление этому скрипту
# - ОБЯЗАТЕЛЬНО ребутаемся
#-- Я ОЧЕНЬ РЕКОМЕНДУЮ! Обновить файл Hosts под свои адреса и задачи
#
# https://wiki.archlinux.org/title/Sysctl_(%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9)
#============================================================================================================================
srcl="/etc/apt/sources.list"                            #-- переменная сорц листа
srcdeb="/etc/apt/sources.list.d/50-off-deb.sources"    #-- Сорцы дебиана
sysctlc="/etc/sysctl.conf"                              #-- переменная сисцтл, куда внесем изменения для твика ядра
sysctl13="/usr/lib/sysctl.d/50-custom.conf"             #-- DEBIAN 13 - переменная сисцтл, куда внесем изменения для твика ядра
appinst=(fail2ban mcedit curl ufw apt-transport-https ca-certificates) #-- переменная цикла -- Тут пишем аппсы, БЕЗ запятых, ТОЛЬКО с пробелами и они будут установлены
hellosh="/etc/profile.d/hello.sh"                       #-- Приветственный скрипт SSH
motdd="/etc/motd"                                       #-- Это надо очистить
#---------------------------------------
autostscr="/usr/local/bin/autostart.sh"                 #-- переменная для скрипта автообновления
autoservc="/etc/systemd/system/AutoUpdate.service"      #-- переменная для сервиса автообновления
autotimer="/etc/systemd/system/AutoUpdate.timer"        #-- переменная для таймера автообновления
#---------------------------------------
failsrc="/etc/fail2ban/jail.local"                      #-- переменная для создания файла конфигурации fail2ban
vercheck=$(cat /etc/debian_version 2>/dev/null | tr -d ' ' | head -n1)
#vercheck=$(cut -d. -f1 /etc/debian_version)

#ufwbefore="/etc/ufw/before.rules"                      #-- UFW
#hallow="/etc/hosts.allow"                              #-- 
#hdeny="/etc/hosts.deny"                                #-- 
#localip=$(hostname --ip-address)                       #-- 
#appremove=(vim cron) #-- не люблю вим, снимаю с себя погоны айти за это с:
#echo -e "" >> $var #-- кртл + с

#     [ -f $sshdconf ] || touch $sshdconf
#        -f	существует ли файл
#        -d	существует ли каталог
#        -e	существует ли что угодно (файл, каталог, симлинк)
#        -s	файл существует и не пустой
#        -L	существует ли символическая ссылка
C_RED="\033[91m"
C_YELLOW="\033[93m"
C_WHITE="\e[1;37m"
C_RESET="\033[0m"
#
#       ${C_RED}
#       ${C_YELLOW}
#       ${C_WHITE}
#       ${C_RESET}
#------------------------------------




#------------------------------------

# hellosh="/etc/profile.d/hello.sh"  
[ -f $hellosh ] || touch $hellosh | printf "${C_WHITE} Создаем файл: ${C_YELLOW}- $hellosh \033[0m${C_RESET}\n"

# autostscr="/usr/local/bin/autostart.sh"
[ -f $autostscr ] || touch $autostscr | printf "${C_WHITE} Создаем файл: ${C_YELLOW}- $autostscr \033[0m${C_RESET}\n"

# autoservc="/etc/systemd/system/AutoUpdate.service"
[ -f $autoservc ] || touch $autoservc | printf "${C_WHITE} Создаем файл: ${C_YELLOW}- $autoservc \033[0m${C_RESET}\n"

# autotimer="/etc/systemd/system/AutoUpdate.timer"
[ -f $autotimer ] || touch $autotimer | printf "${C_WHITE} Создаем файл: ${C_YELLOW}- $autotimer \033[0m${C_RESET}\n"

# failsrc="/etc/fail2ban/jail.local"  
[ -f $failsrc ] || touch $failsrc | printf "${C_WHITE} Создаем файл: ${C_YELLOW}- $failsrc \033[0m${C_RESET}\n"
#============================================================================================================================
printf "${C_WHITE} Изменение репозиториев... ${C_RESET}\n"

if [[ "$vercheck" == 12.* ]]; then
    tee /etc/apt/sources.list &>/dev/null << EOF
deb https://deb.debian.org/debian bookworm main non-free-firmware
deb-src https://deb.debian.org/debian bookworm main non-free-firmware

deb https://security.debian.org/debian-security bookworm-security main non-free-firmware
deb-src https://security.debian.org/debian-security bookworm-security main non-free-firmware

deb https://deb.debian.org/debian bookworm-updates main non-free-firmware
deb-src https://deb.debian.org/debian bookworm-updates main non-free-firmware
EOF

elif [[ "$vercheck" == 13.* ]]; then
 #cat /dev/null > /etc/apt/sources.list
    # srcdeb="/etc/apt/sources.list.d/50-off-deb.sources"
[ -f $srcdeb ] || touch $srcdeb | printf "${C_WHITE} Создаем файл: ${C_YELLOW}- $srcdeb \033[0m${C_RESET}\n"
cat > $srcdeb << EOF

Types: deb
URIs: https://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://security.debian.org/debian-security
Suites: trixie-security
Components: main non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

EOF

else
    printf "${C_RED} \nОШИБКА! Версия Debian: $vercheck - репозитории не настроены, поддерживаются только 12 и 13 релизы. ${C_RESET} \n"
    read -p "ОШИБКА РАБОТЫ СКРИПТА!"
    exit 1
fi

#============================================================================================================================
printf "${C_WHITE} Запускается обновление системы... ${C_RESET}\n"

run_with_spinner() {
    local cmd="$1"
    local message="${2:-Выполнение команды}"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    echo -n "$message "
    
    eval "$cmd" > /dev/null 2>&1 &
    local pid=$!
    
    while kill -0 $pid 2>/dev/null; do
        printf "\r%s %s" "$message" "${spin:$i:1}"
        i=$(((i+1) % ${#spin}))
        sleep 0.1
    done
    wait $pid
    
    if [ $? -eq 0 ]; then
        printf "\r%s ✓\n" "$message"
    else
        printf "\r%s ✗\n" "$message"
        return 1
    fi
}
run_with_spinner "apt update -qq" "Обновление списков пакетов"


run_with_spinner "apt upgrade -y -qq" "Обновление системы"
printf "${C_WHITE}Система обновлена.${C_RESET}\n"

#
printf "${C_WHITE} Выполняется установка приложений... ${C_RESET}\n"
for app in "${appinst[@]}"
do
    sudo apt install -y "$app"
done
printf "${C_WHITE} Установка приложений завершена.${C_RESET}\n"
#============================================================================================================================
#---------------------------------------------- HELLO SHH --- /etc/profile.d/hello.sh
#============================================================================================================================
   tee $motdd &>/dev/null/
   tee $hellosh &>/dev/null << 'EOF'
#!/bin/bash
#   1 - Clear /etc/motd                => cat /dev/null > /etc/motd
#   2 - make the sctirpt /etc/profile.d/hello.sh   => touch /etc/profile.d/hello.sh
#   3 - Cply ALL to /etc/profile.d/hello.sh
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
EOF

chmod +x $hellosh

#============================================================================================================================
#---------------------------------------------- UFW --- /etc/ufw/before.rules
#============================================================================================================================
#cat $ufwrules | grep 'A ufw-before-forward -p icmp --icmp-type echo-request -j ACCEPT' | sed '/s/A ufw-before-forward -p icmp --icmp-type echo-request -j ACCEPT/#' >> $ufwrules
#============================================================================================================================
#
#============================================================================================================================
#======================== ----------------------Автоматизация обновлений
#-- создаем скрипт, который послужит точкой выполнения автоапдейта по пути: /usr/local/bin/autostart.sh

#echo -e "sleep 20" >> $autostscr #-- ждем
#echo -e "reboot" >> $autostscr #-- ребут сервера | НИ В КОЕМ СЛУЧАЕ!!!
#- autostscr="/usr/local/bin/autostart.sh" 
#cat > $autostscr << EOF
tee $autostscr &>/dev/null << EOF
#!/bin/bash
apt update && apt upgrade -y
apt autoremove -y
EOF
#--
chmod +x $autostscr #-- выдаем права на выполнение
#============================================================================================================================
#-- Создаем службу, которая будет выполнять скрипт выше по пути: /etc/systemd/system/AutoUpdate.service 
#-
#cat > $autoservc << EOF
tee $autoservc &>/dev/null << EOF
[Unit]
Description=AutoUpdateService
Wants=AutoUpdate.timer

[Service]
User=root
Type=oneshot
ExecStart="/usr/local/bin/autostart.sh"

[Install]
WantedBy=multi-user.target
EOF
#============================================================================================================================
#-- Создаем таймер, который будет запускать этот сервис раз в неделю, в 12 часов ночи. Путь: /etc/systemd/system/AutoUpdate.timer
#-- Поясню - Раз в неделю, значит каждый понедельник, независимо от того, когда таймер был запущен. Если вы впервые запустили его в пятницу, значит,
#-- он в любом случае будет вновь запущен в понедельник.

#touch $autotimer
#- autotimer="/etc/systemd/system/AutoUpdate.timer"  
#cat > $autotimer << EOF
tee $autotimer &>/dev/null << EOF
[Unit]
Description=AutoUpdateTimer
Requires=AutoUpdate.service

[Timer]
Unit=AutoUpdate.service
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF
#
systemctl daemon-reload
#-
systemctl enable AutoUpdate.service
systemctl enable AutoUpdate.timer
#-
#============================================================================================================================
#============================================= --------- SECURE ------------------------------------------
#============================================= SYSCTL /etc/sysctl.conf
#
#------------------------- чрезвычайно важный твик ядра для сервера, --== ЗНАЧИТЕЛЬНО! ==-- Увеличивает пропускную способность. 

#sysctlc="/etc/sysctl.conf" 

if [[ "$vercheck" == 12.* ]]; then
# BBR enable
# BBR - современный алгоритм Google, увеличивает пропускную способность на 20-40% при высоких задержках
# BBR - modern google algorithm, incrased bandwitch of network over 20-40%, under high latency conditions
echo "net.core.default_qdisc=fq" >> $sysctlc 
echo "net.ipv4.tcp_congestion_control=bbr" >> $sysctlc

#ICMP ingore - optional
# echo "net.ipv4.icmp_ignore_bogus_error_responses=1" >> $sysctlc

# block SYN-flood Attack
# Protects against DDoS attacks rich in TCP connections
echo "net.ipv4.tcp_syncookies = 1" >> $sysctlc
echo "net.ipv4.tcp_max_syn_backlog = 4096" >> $sysctlc
echo "net.ipv4.tcp_synack_retries = 3" >> $sysctlc

# mitm route attack 
# Запрещает маршрутизацию через ваш сервер (source routing)
# Forbid routing throught your server (source routing)
echo "net.ipv4.conf.all.accept_source_route = 0" >> $sysctlc
echo "net.ipv4.conf.default.accept_source_route = 0" >> $sysctlc

# ipv6 disable
echo "# net.ipv6.conf.all.disable_ipv6 = 1" >> $sysctlc
echo "# net.ipv6.conf.default.disable_ipv6 = 1" >> $sysctlc
echo "# net.ipv6.conf.lo.disable_ipv6 = 1" >> $sysctlc
#
#printf "${C_WHITE} Изменения systemctl $vercheck внесены  ${C_RESET}"
sysctl -p

elif [[ "$vercheck" == 13.* ]]; then
 [ -f $sysctl13 ] || touch $sysctl13
 
 #cat > $sysctl13 << EOF
 tee $sysctl13 &>/dev/null << EOF
#
#       Small Sysctl debian tweaks
#       Небольшие sysctl твики
#
#
# NOT READY
#
# BBR enable
# BBR - современный алгоритм Google, увеличивает пропускную способность на 20-40% при высоких задержках
# BBR - modern google algorithm, incrased bandwitch of network over 20-40%, under high latency conditions
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

#ICMP ingore - optional
# net.ipv4.icmp_ignore_bogus_error_responses = 1

# block SYN-flood Attack
# Protects against DDoS attacks rich in TCP connections
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_synack_retries = 3

# mitm route attack 
# Запрещает маршрутизацию через ваш сервер (source routing)
# Forbid routing throught your server (source routing)
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

#------- DO NOTE DISABLE IPV6 HERE
#
# ipv6 disable 
#   net.ipv6.conf.all.disable_ipv6 = 1
#   net.ipv6.conf.default.disable_ipv6 = 1
#   net.ipv6.conf.lo.disable_ipv6 = 1
#
#------- DO NOTE DISABLE IPV6 HERE

net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Увеличение лимитов для высоконагруженных серверов
net.core.somaxconn=65535
net.core.netdev_max_backlog=65535
net.ipv4.ip_local_port_range=1024 65535

# Ускорение закрытия соединений
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_tw_reuse=1

# Защита от Small SYN flood
net.ipv4.tcp_mtu_probing=1
EOF

#printf "${C_WHITE} Изменения systemctl $vercheck внесены ${C_RESET}"
/usr/sbin/sysctl --load $sysctl13
/sbin/sysctl --load $sysctl13
else
    printf "${C_RED} \nSystemctl Не был сконфигурирован${C_RESET} \n"
fi

#==================================================--- Простенькая настройка Fail2Ban

#touch $failsrc 
#cat > $failsrc << EOF
tee $sysctl13 &>/dev/null << EOF
[DEFAULT]
[ssh]
findtime = 300
maxretry = 3
bantime = 365d
EOF
#------ лучше тут сами
systemctl restart fail2ban
systemctl stop fail2ban
ufw allow ssh
ufw disable
#
#==================================================----- UFW
#------------- ufwbefore = /etc/ufw/before.rules
# игнор эхо запросов. Отключена часть скрипта, потому что не работает полученичение порта SSH, а значит, включение фаерволла заблокирует себя. Можно сделать вручную
# -A ufw-before-input -p icmp --icmp-type echo-request -j DROP
#-- console
# ufw deny in from any to any proto ipv6
#============================================================================================================================
#------------------- ------ ------ hosts - Желательно сделать
#    #/etc/hosts.allow
#echo -e "ALL: localhost" >> $hallow
#echo -e "ALL: $localip" >> $hallow

    #/etc/hosts.deny
####--------------------- NO echo -e "SSHD: ALL" >> $hdeny
#echo -e "mysqld: ALL" >> $hdeny
#echo -e "postgres: ALL" >> $hdeny
#echo -e "apache2: ALL" >> $hdeny
#echo -e "nginx: ALL" >> $hdeny
#echo -e "httpd: ALL" >> $hdeny
#echo -e "cupsd: ALL" >> $hdeny
#echo -e "ntpd: ALL" >> $hdeny
#echo -e "syslog: ALL" >> $hdeny

#============================================================================================================================
printf "${C_WHITE} Запуск очистки системы от старых пакетов... ${C_RESET}\n"
apt autoremove -y #--- чистим старые пакеты автоудалятором
#============================================================================================================================
printf "${C_WHITE}  Базовая настройка выполнена ${C_RESET}\n"
#============================================================================================================================
#printf "${C_WHITE} А теперь внимательно - сейчас управление будет передано 3x-ui.${C_RESET}\n"
#printf "${C_WHITE} ОЧЕНЬ внимательно читаем, че там будет написано. ${C_RESET}\n"
#printf "${C_WHITE} Он спросит - настроить-ли панель управления? НЕТ - идеально, т.к. нам нужно скрыть факт нахождения впн на своем сервере ${C_RESET}\n"
#printf "${C_WHITE} Потом, там появится информация, которая НЕОБХОДИМА для подключения к твоему серверу ${C_RESET}\n"
#printf "${C_WHITE} Что бы воспользоваться командами VPN - набери x-ui и вооружись переводчиком.${C_RESET}\n"
#read -p "Прочитал? Точно? Жми Энтер."

printf "${C_WHITE} Для установки 3x-ui Нужно нажать ENTER.${C_RESET}\n"
printf "${C_WHITE} также, советую включить fail2ban и ufw.${C_RESET}\n"
read -p "ENTER..?"
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
