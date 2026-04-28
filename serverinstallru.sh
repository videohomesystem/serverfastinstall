#!/bin/bash
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
srcdrop="/etc/apt/sources.list.d/00-off-deb.sources"    #-- 
sysctlc="/etc/sysctl.conf"                              #-- переменная сисцтл, куда внесем изменения для твика ядра
sysctl13="/usr/lib/sysctl.d/50-custom.conf"             #-- DEBIAN 13 - переменная сисцтл, куда внесем изменения для твика ядра
appinst=(fail2ban mcedit curl ufw)                      #-- переменная цикла -- Тут пишем аппсы, БЕЗ запятых, ТОЛЬКО с пробелами и они будут установлены
#---------------------------------------
autostscr="/usr/local/bin/autostart.sh"                 #-- переменная для скрипта автообновления
autoservc="/etc/systemd/system/AutoUpdate.service"      #-- переменная для сервиса автообновления
autotimer="/etc/systemd/system/AutoUpdate.timer"        #-- переменная для таймера автообновления
#---------------------------------------
failsrc="/etc/fail2ban/jail.local"                      #-- переменная для создания файла конфигурации fail2ban
vercheck=$(cat /etc/debian_version 2>/dev/null | tr -d ' ' | head -n1)

#ufwbefore="/etc/ufw/before.rules"                      #-- UFW
#hallow="/etc/hosts.allow"                              #-- 
#hdeny="/etc/hosts.deny"                                #-- 
#localip=$(hostname --ip-address)                       #-- 
#appremove=(vim cron) #-- не люблю вим, снимаю с себя погоны айти за это с:
#echo -e "" >> $var #-- кртл + с
#============================================================================================================================
if [[ $EUID -ne 0 ]]; then
   printf "\033[93m run script as\e[1;37m root\033[0m\n"
   exit 1
fi
#============================================================================================================================
printf "\033[93m Изменение репозиториев... \033[0m\n"

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
 cat /dev/null > /etc/apt/sources.list
 [ -f $srcdrop ] || touch $srcdrop

cat > $srcdrop << EOF

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
    printf "\033[91m \nОШИБКА! Версия Debian: $vercheck - репозитории не настроены, т.к. поддерживаются только 12 и 13 релизы. \033[0m \n"
    read -p "ОШИБКА РАБОТЫ СКРИПТА!"
    exit 1
fi

#============================================================================================================================
printf "\033[93m Запускается обновление системы... \033[0m\n"

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
printf "\033[93m Система обновлена.\033[0m\n"

#
printf "\033[93m Выполняется установка приложений... \033[0m\n"
for app in "${appinst[@]}"
do
    sudo apt install -y "$app"
done
printf "\033[93m Установка приложений завершена.\033[0m\n"
#============================================================================================================================
#---------------------------------------------- UFW --- /etc/ufw/before.rules
#============================================================================================================================
#cat $ufwrules | grep 'A ufw-before-forward -p icmp --icmp-type echo-request -j ACCEPT' | sed '/s/A ufw-before-forward -p icmp --icmp-type echo-request -j ACCEPT/#' >> $ufwrules
#============================================================================================================================
#
#============================================================================================================================
#======================== ----------------------Автоматизация обновлений
#============================================================================================================================
#-- создаем скрипт, который послужит точкой выполнения автоапдейта по пути: /usr/local/bin/autostart.sh
touch $autostscr

#echo -e "sleep 20" >> $autostscr #-- ждем
#echo -e "reboot" >> $autostscr #-- ребут сервера | НИ В КОЕМ СЛУЧАЕ!!!
#-
cat > $autostscr << EOF
#!/bin/bash
apt update && apt upgrade -y
apt autoremove -y
EOF
#--
chmod +x $autostscr #-- выдаем права на выполнение
#============================================================================================================================
#-- Создаем службу, которая будет выполнять скрипт выше по пути: /etc/systemd/system/AutoUpdate.service 
touch $autoservc
#-
cat > $autoservc << EOF
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
touch $autotimer
#-
cat > $autotimer << EOF
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
systemctl enable AutoUpdate.service
systemctl enable AutoUpdate.timer
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
echo "net.ipv4.tcp_max_syn_backlog = 2048" >> $sysctlc
echo "net.ipv4.tcp_synack_retries = 3" >> $sysctlc

# mitm route attack 
# Запрещает маршрутизацию через ваш сервер (source routing)
# Forbid routing throught your server (source routing)
echo "net.ipv4.conf.all.accept_source_route = 0" >> $sysctlc
echo "net.ipv4.conf.default.accept_source_route = 0" >> $sysctlc

# ipv6 disable
echo #"net.ipv6.conf.all.disable_ipv6 = 1" >> $sysctlc
echo #"net.ipv6.conf.default.disable_ipv6 = 1" >> $sysctlc
echo #"net.ipv6.conf.lo.disable_ipv6 = 1" >> $sysctlc
#
#printf "\033[93m Изменения systemctl $vercheck внесены  \033[0m"
sysctl -p

elif [[ "$vercheck" == 13.* ]]; then
 [ -f $sysctl13 ] || touch $sysctl13
 
 cat > $sysctl13 << EOF
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
net.ipv4.icmp_ignore_bogus_error_responses = 1

# block SYN-flood Attack
# Protects against DDoS attacks rich in TCP connections
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 3

# mitm route attack 
# Запрещает маршрутизацию через ваш сервер (source routing)
# Forbid routing throught your server (source routing)
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# ipv6 disable
#   net.ipv6.conf.all.disable_ipv6 = 1
#   net.ipv6.conf.default.disable_ipv6 = 1
#   net.ipv6.conf.lo.disable_ipv6 = 1
#

net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
EOF

#printf "\033[93m Изменения systemctl $vercheck внесены \033[0m"
/usr/sbin/sysctl --load $sysctl13
/sbin/sysctl --load $sysctl13
else
    printf "\033[91m \nSystemctl was not configured, unknown error\033[0m \n"
fi

#==================================================--- Простенькая настройка Fail2Ban
touch $failsrc #-- Новый файл
cat > $failsrc << EOF
[DEFAULT]
[ssh]
findtime = 300
maxretry = 3
bantime = 365d
EOF
systemctl restart fail2ban
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
printf "\033[93m Запуск очистки системы от старых пакетов... \033[0m\n"
apt autoremove -y #--- чистим старые пакеты автоудалятором
#============================================================================================================================
printf "\033[93m  Базовая настройка выполнена \033[0m\n"
#============================================================================================================================
printf "\033[93m А теперь внимательно - сейчас управление будет передано 3x-ui.\033[0m\n"
printf "\033[93m ОЧЕНЬ внимательно читаем, че там будет написано. \033[0m\n"
printf "\033[93m Он спросит - настроить-ли панель управления? НЕТ - идеально, т.к. нам нужно скрыть факт нахождения впн на своем сервере \033[0m\n"
printf "\033[93m Потом, там появится информация, которая НЕОБХОДИМА для подключения к твоему серверу \033[0m\n"
printf "\033[93m Что бы воспользоваться командами VPN - набери x-ui и вооружись переводчиком.\033[0m\n"

read -p "Прочитал? Точно? Жми Энтер.
"
printf "\033[93m Точно прочитал? Обычно не читают, теперь прочитаешь. \033[0m\n"
read -p "ENTER...?
"
#============================================================================================================================
#--- 3x UI
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
#============================================================================================================================
#
printf "\033[93m Готово. \033[0m\n"

printf "\033[93m Задачи завершены. ОБЯЗАТЕЛЬНО сделай перезагрузку ПОСЛЕ того, как сохранишь данные для подключения....\033[0m\n"
read -p "ENTER...?"
exit 0
