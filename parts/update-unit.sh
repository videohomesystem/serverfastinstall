
#!/bin/bash
#---------------------------------------
autostscr="/usr/local/bin/autostart.sh"                 #-- переменная для скрипта автообновления
autoservc="/etc/systemd/system/AutoUpdate.service"      #-- переменная для сервиса автообновления
autotimer="/etc/systemd/system/AutoUpdate.timer"        #-- переменная для таймера автообновления
#---------------------------------------

C_RED="\033[91m"
C_YELLOW="\033[93m"
C_WHITE="\e[1;37m"
C_RESET="\033[0m"

#---------------------------------------
# autostscr="/usr/local/bin/autostart.sh"
[ -f $autostscr ] || touch $autostscr | printf "${C_WHITE} Создаем файл: ${C_YELLOW}$autostscr${C_RESET}\n"

# autoservc="/etc/systemd/system/AutoUpdate.service"
[ -f $autoservc ] || touch $autoservc | printf "${C_WHITE} Создаем файл: ${C_YELLOW}$autoservc${C_RESET}\n"

# autotimer="/etc/systemd/system/AutoUpdate.timer"
[ -f $autotimer ] || touch $autotimer | printf "${C_WHITE} Создаем файл: ${C_YELLOW}$autotimer${C_RESET}\n"

#============================================================================================================================
#======================== ----------------------Автоматизация обновлений
# Поскольку абсолютно очевиден факт - обычный юзер не будет раз в неделю (и даже раз в год) обновлять систему - автоматизируем
# совсем без обновлений жить нельзя
#- создаем скрипт, который послужит точкой выполнения автоапдейта по пути: /usr/local/bin/autostart.sh
#- autostscr="/usr/local/bin/autostart.sh"
printf "${C_WHITE}Создание скрипты для автоапдейта${C_RESET}\n"
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
printf "${C_WHITE}Создание юнита-службы${C_RESET}\n"
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
printf "${C_WHITE}Создание юнита-таймера${C_RESET}\n"
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
printf "${C_WHITE}Готово.${C_RESET}\n"
