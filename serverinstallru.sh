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
# ENG --------------------- I'll realy tried it
#============================================================================================================================
srcl="/etc/apt/sources.list"                            #--переменная сорц листа
sysctlc="/etc/sysctl.conf"                              #-- переменная сисцтл, куда внесем изменения для твика ядра
appinst=(fail2ban mcedit curl ufw)                      #-- переменная цикла -- Тут пишем аппсы, БЕЗ запятых, ТОЛЬКО с пробелами и они будут установлены
autostscr="/usr/local/bin/autostart.sh"                 #-- переменная для скрипта автообновления
autoservc="/etc/systemd/system/AutoUpdate.service"      #-- переменная для сервиса автообновления
autotimer="/etc/systemd/system/AutoUpdate.timer"        #-- переменная для таймера автообновления
failsrc="/etc/fail2ban/jail.local"                      #-- переменная для создания файла конфигурации fail2ban
#ufwbefore="/etc/ufw/before.rules"                      #-- UFW
#hallow="/etc/hosts.allow"                              #-- 
#hdeny="/etc/hosts.deny"                                #-- 
#localip=$(hostname --ip-address)                       #-- 
#appremove=(vim cron) #-- не люблю вим, снимаю с себя погоны айти за это с:
#echo -e "" >> $var #-- кртл + с
#============================================================================================================================
printf "\033[93m Изменение репозиториев... 
\033[0m"
#- чистим файл
echo -e "" > $srcl
# Добавляем новые строки в файл БЕЗ HTTP-S- - это нужно как временное решение для установки сертов, если их нет, а их скорее всего и нет :с
echo -e "\n# Основной репозиторий" >> $srcl
echo "deb http://deb.debian.org/debian bookworm main non-free-firmware" >> $srcl
apt update && apt install ca-certificates -y && apt install apt-transport-https -y
# чистим файл вновь
echo -e "" > $srcl 
# Добавляем новые строки в файл
echo -e "deb https://deb.debian.org/debian bookworm main non-free-firmware" >> $srcl
echo -e "deb-src https://deb.debian.org/debian bookworm main non-free-firmware" >> $srcl
#
echo -e "deb https://security.debian.org/debian-security bookworm-security main non-free-firmware" >> $srcl
echo -e "deb-src https://security.debian.org/debian-security bookworm-security main non-free-firmware" >> $srcl
#
echo -e "deb https://deb.debian.org/debian bookworm-updates main non-free-firmware" >> $srcl
echo -e "deb-src https://deb.debian.org/debian bookworm-updates main non-free-firmware" >> $srcl
#
#============================================================================================================================
printf "\033[93m Запускается обновление системы... 
\033[0m"
apt update && apt upgrade -y # - индексирует содержимое репозиториев > обновляет систему > скипает вопросы установщика
printf "\033[93m Система обновлена.
\033[0m"
#
printf "\033[93m Выполняется установка приложений... 
\033[0m"
for app in "${appinst[@]}"
do
    sudo apt install -y "$app"
done
printf "\033[93m Установка приложенйи завершена.
\033[0m"
#============================================================================================================================
#---------------------------------------------- UFW --- /etc/ufw/before.rules
#============================================================================================================================
#cat $ufwrules | grep 'A ufw-before-forward -p icmp --icmp-type echo-request -j ACCEPT' | sed '/s/A ufw-before-forward -p icmp --icmp-type echo-request -j ACCEPT/#' >> $ufwrules
#============================================================================================================================
#-- Меняем на редактор, который не будет приводить в такой сильный шок обычных юзеров
#-- Что-то из этого сработает:
#echo "export EDITOR=/usr/bin/vim" >> ~/.bashrc
#export EDITOR=mcedit
update-alternatives --set editor /usr/bin/mcedit
#============================================================================================================================
#======================== ----------------------Автоматизация обновлений
#============================================================================================================================
#-- создаем скрипт, который послужит точкой выполнения автоапдейта по пути: /usr/local/bin/autostart.sh
touch $autostscr
#-
echo -e '#!/bin/bash' >> $autostscr
echo -e "apt update && apt upgrade -y" >> $autostscr #-- обновление дистрибутивов && апгрейд системы с пропуском вопросов
echo -e "apt autoremove -y" >> $autostscr #-- авточистка после обновления
#echo -e "sleep 20" >> $autostscr #-- ждем
#echo -e "reboot" >> $autostscr #-- ребут сервера | НИ В КОЕМ СЛУЧАЕ!!!
echo -e "exit 0" >> $autostscr
#--
chmod +x $autostscr #-- выдаем права на выполнение
#============================================================================================================================
#-- Создаем службу, которая будет выполнять скрипт выше по пути: /etc/systemd/system/AutoUpdate.service 
touch $autoservc
#-
echo -e "[Unit]" >> $autoservc
echo -e "Description=AutoUpdate Service" >> $autoservc
echo -e "Wants=autoupdate.timer" >> $autoservc
#-
echo -e "[Service]" >> $autoservc
echo -e  "User=root" >> $autoservc
echo -e  "Type=oneshot" >> $autoservc
echo -e  "ExecStart="/usr/local/bin/autostart.sh"" >> $autoservc
#-
echo -e "[Install]" >> $autoservc
echo -e "WantedBy=multi-user.target" >> $autoservc
#============================================================================================================================
#-- Создаем таймер, который будет запускать этот сервис раз в неделю, в 12 часов ночи. Путь: /etc/systemd/system/AutoUpdate.timer
#-- Поясню - Раз в неделю, значит каждый понедельник, независимо от того, когда таймер был запущен. Если вы впервые запустили его в пятницу, значит,
#-- он в любом случае будет вновь запущен в понедельник.
touch $autotimer
#-
echo -e "[Unit]" >> $autotimer
echo -e "Description=AutoUpdateTimer" >> $autotimer
echo -e "Requires=AutoUpdate.service" >> $autotimer
#-
echo -e "[Timer]" >> $autotimer
echo -e "Unit=AutoUpdate.service" >> $autotimer
echo -e "OnCalendar=weekly" >> $autotimer
echo -e "Persistent=true" >> $autotimer
#-
echo -e "[Install]" >> $autotimer
echo -e "WantedBy=timers.target" >> $autotimer
#
#---------------- Чет как будто работает, надо проверить, что после ребута он действительно запустился
#=======--------- Работает оО
systemctl daemon-reload
#systemd-analyze verify /etc/systemd/system/AutoUpdate.timer #-- оно точно надо?
systemctl enable $autostscr
systemctl enable $autotimer
#-
systemctl start $autostscr
systemctl start $autotimer
#============================================================================================================================
#============================================= --------- SECURE ------------------------------------------
#============================================= SYSCTL /etc/sysctl.conf
#
#------------------------- чрезвычайно важный твик ядра для сервера, --== ЗНАЧИТЕЛЬНО! ==-- Увеличивает пропускную способность. 
# BBR enable
echo "net.core.default_qdisc=fq" >> $sysctlc 
echo "net.ipv4.tcp_congestion_control=bbr" >> $sysctlc
#ICMP ingore
echo "net.ipv4.icmp_ignore_bogus_error_responses = 1" >> $sysctlc
# block SYN-flood Attack 
echo "net.ipv4.tcp_syncookies = 1" >> $sysctlc
echo "net.ipv4.tcp_max_syn_backlog = 2048" >> $sysctlc
echo "net.ipv4.tcp_synack_retries = 3" >> $sysctlc
# mitm route attack
echo "net.ipv4.conf.all.accept_source_route = 0" >> $sysctlc
echo "net.ipv4.conf.default.accept_source_route = 0" >> $sysctlc
# ipv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> $sysctlc
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> $sysctlc
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> $sysctlc
#
sysctl -p
#SYSRESULT="$(/usr/sbin/sysctl -a | grep congestion)"
#/usr/sbin/sysctl -p - для дебиан 12 в варианте десктопа
#printf "\033[93m Изменения в ядро $SYSRESULT внесены  \033[0m"

#==================================================--- Простенькая настройка Fail2Ban
touch $failsrc #-- Новый файл
#-
echo -e "[DEFAULT]" >> $failsrc #-- заголовок
#echo -e " " >> $failsrc #-- просто для удобства
echo -e "[ssh]" >> $failsrc #-- заголовок
echo -e "findtime = 300" >> $failsrc #-- окно срабатывания 
echo -e "maxretry = 3" >> $failsrc #-- количество траев внутри окна
echo -e "bantime = 365d" >> $failsrc #-- бантайм
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
printf "\033[93m Запуск очистки системы от старых пакетов... 
\033[0m"
apt autoremove -y #--- чистим старые пакеты автоудалятором
#============================================================================================================================
printf "\033[93m А теперь внимательно - сейчас управление будет передано 3x-ui. 

\033[0m"

printf "\033[93m ОЧЕНЬ внимательно читаем, че там будет написано. 

\033[0m"

printf "\033[93m Он спросит - настроить-ли панель управления? НЕТ - идеально, т.к. нам нужно скрыть факт нахождения впн на своем сервере 

\033[0m"

printf "\033[93m Потом, там появится информация, которая НЕОБХОДИМА для подключения к твоему серверу 

\033[0m"

read -p "Прочитал? Точно? Жми Энтер.
"

read -p "С первого раза обычно не читают, а это важно. Вот теперь начинаем установку после нажатия enter.
"
#============================================================================================================================
#--- 3x UI
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
#============================================================================================================================
#
printf "\033[93m Готово. 
\033[0m"
printf "\033[93m Что бы воспользоваться командами VPN - набери x-ui и вооружись переводчиком. 
\033[0m"
read -p "Задачи завершены. ОБЯЗАТЕЛЬНО сделай перезагрузку ПОСЛЕ того, как сохранишь данные для подключения
"
exit 0
