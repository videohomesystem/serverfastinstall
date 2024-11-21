#!/bin/bash
# RU ---------------------
# А че делаем?
# 1 - вносим изменения в сорц.лист, поскольку авторы дебиана за каким-то решили, что делать этот файл пустым - идея хорошая. Желаем им добра и меняем на нормальные
# 2 - обновляемся
# 3 - ставим аппсы: apt-transport-https, ca-certificates, fail2ban, mcedit, curl
# - поскольку у нас подразумевается лень ИЛИ обычный юзер - руками apt upgrade никто не делает - автоматизируем сервисами, нативно, без софта
#  - вносим очень важный твик ядра, который --ЗНАЧИТЕЛЬНО-- увеличит производительность сетевой составляющей сервера, это особенно заметно, если подключений будет много
#  - чистим старые пакеты
#  - ставим 3x-ui и отдаем управление этому скрипту
#  - ребутаемся и все
# ENG ---------------------

#============================================================================================================================
srcl="/etc/apt/sources.list" #--переменная сорц листа
sysctlc="/etc/sysctl.conf" #-- переменная сисцтл, куда внесем изменения для твика ядра
appinst=(fail2ban mcedit curl) #-- переменная цикла -- Тут пишем аппсы, БЕЗ запятых, ТОЛЬКО с пробелами
autostscr="/usr/local/bin/autostart.sh" #--
autoservc="/etc/systemd/system/AutoUpdate.service" #--
autotimer="/etc/systemd/system/AutoUpdate.timer" #--
#appremove=(vim cron) #-- не люблю вим, фу
#echo -e "" >> $var #-- кртл + с
#============================================================================================================================
printf "\033[93m Изменение репозиториев... \033[0m"
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
printf "\033[93m Запускается обновление системы... \033[0m"
apt update && apt upgrade -y # - индексирует содержимое репозиториев > обновляет систему > скипает вопросы установщика
printf "\033[93m Система обновлена \033[0m"
#
printf "\033[93m Выполняется установка приложений.. \033[0m"
for app in "${appinst[@]}"
do
    sudo apt install -y "$app"
done
#============================================================================================================================
#-- Меняем на редактор, который не будет приводить в такой сильный шок обычных юзеров
#-- Что-то из этого сработает:
echo "export EDITOR=/usr/bin/vim" >> ~/.bashrc
export EDITOR=mcedit
#============================================================================================================================
#======================== ----------------------Автоматизация обновлений
#============================================================================================================================
#-- создаем скрипт, который послужит точкой выполнения автоапдейта
touch $autostscr
echo -e '#!/bin/bash' >> $autostscr
echo -e "apt update && apt upgrade -y" >> $autostscr
#--
chmod +x $autostscr
#============================================================================================================================
#-- Создаем службу, которая будет выполнять скрипт выше
touch $autoservc
echo -e "[Unit]" >> $autoservc
echo -e "Description="AutoUpdate Service"" >> $autoservc
echo -e "[Service]" >> $autoservc
echo -e "User=root" >> $autoservc
echo -e "ExecStart=/usr/local/bin/autostart.sh" >> $autoservc
echo -e "[Install]" >> $autoservc
echo -e "WantedBy=multi-user.target" >> $autoservc
#============================================================================================================================
#-- Создаем таймер, который будет запускать этот сервис раз в месяц, в 12 часов ночи
touch $autotimer
echo -e "[Timer]" >>
echo -e "OnCalendar=Weekly" >> $autotimer
echo -e "Unit=AutoUpdate.service" >> $autotimer
#----------------------------------------------------------------------------------------------------------------------------
systemd-analyze verify /etc/systemd/system/AutoUpdate.timer
systemctl start $autotimer
systemctl start $autostscr
#============================================================================================================================
#============================================================================================================================
#for app in "${appremove[@]}"
#do
#    sudo apt remove -y "$app"
#done
#============================================================================================================================
#-- чрезвычайно важный твик ядра для сервера, НА ПОРЯДКИ! Увеличивает пропускную способность. src: https://joyreactor.cc/post/5761728
echo "net.core.default_qdisc=fq" >> $sysctlc 
echo "net.ipv4.tcp_congestion_control=bbr" >> $sysctlc
sysctl -p
#SYSRESULT="$(/usr/sbin/sysctl -a | grep congestion)"
#/usr/sbin/sysctl -p - для дебиан 12 в варианте десктопа
#printf "\033[93m Изменения в ядро $SYSRESULT внесены  \033[0m"
#============================================================================================================================
printf "\033[93m Запуск очистки системы от старых пакетов... \033[0m"
apt autoremove -y #--- чистим старые пакеты автоудалятором
#============================================================================================================================
printf "\033[93m А теперь внимательно - сейчас управление будет передано 3x-ui. \033[0m"
printf "\033[93m ОЧЕНЬ внимательно читаем, че там будет написано. \033[0m"
printf "\033[93m Он спросит - настроить-ли панель управления? НЕТ - идеально, т.к. нам нужно скрыть факт нахождения впн на своем сервере \033[0m"
printf "\033[93m Потом, там появится информация, которая НЕОБХОДИМА для подключения к твоему серверу \033[0m"
read -p "Прочитал? Точно? Жми Энтер."
read -p "С первого раза обычно не читают, а это важно. Вот теперь начинаем установку после нажатия enter."
#============================================================================================================================
#--- 3x UI
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
#============================================================================================================================
#
printf "\033[93m Готово. \033[0m"
read -p "Задачи завершены. ОБЯЗАТЕЛЬНО сделай перезагрузку ПОСЛЕ того, как сохранишь данные для подключения"
