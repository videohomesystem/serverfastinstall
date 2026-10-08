


#======================== ----------------------Автоматизация обновлений
# Поскольку абсолютно очевиден факт - обычный юзер не будет раз в неделю (и даже раз в год) обновлять систему - автоматизируем
# совсем без обновлений жить нельзя
#- создаем скрипт, который послужит точкой выполнения автоапдейта по пути: /usr/local/bin/autostart.sh
#- autostscr="/usr/local/bin/autostart.sh"

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
