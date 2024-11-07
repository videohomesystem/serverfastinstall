#!/bin/bash
#============================================================================================================================
srcl="/etc/apt/sources.list" #--переменная сорц листа
sysctlc="/etc/sysctl.conf" #-- переменная сисцтл, куда внесем изменения для твика ядра
applications=(apt-transport-https ca-certificates fail2ban mcedit curl) #------ Тут пишем аппсы, БЕЗ запятых, ТОЛЬКО с пробелами
#============================================================================================================================
printf "\033[93m Изменение репозиториев... \033[0m"
#- чистим файл
echo -e "" > $srcl
# Добавляем новые строки в файл
echo -e "deb http://deb.debian.org/debian bookworm main non-free-firmware" >> $srcl
echo -e "deb-src http://deb.debian.org/debian bookworm main non-free-firmware" >> $srcl
#
echo -e "deb http://security.debian.org/debian-security bookworm-security main non-free-firmware" >> $srcl
echo -e "deb-src http://security.debian.org/debian-security bookworm-security main non-free-firmware" >> $srcl

echo -e "deb http://deb.debian.org/debian bookworm-updates main non-free-firmware" >> $srcl
echo -e "deb-src http://deb.debian.org/debian bookworm-updates main non-free-firmware" >> $srcl
#
#============================================================================================================================
printf "\033[93m Запускается обновление системы... \033[0m"
apt update && apt upgrade -y # - индексирует содержимое репозиториев > обновляет систему > скипает вопросы установщика
printf "\033[93m Система обновлена \033[0m"
#
printf "\033[93m Выполняется установка приложений.. \033[0m"
for app in "${applications[@]}"
do
    sudo apt install -y "$app"
done
printf "\033[93m Приложения установлены \033[0m"
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
#--- 3x UI
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
#============================================================================================================================
#
printf "\033[93m Готово. \033[0m"
read -p "Задачи завершены. После нажатия ENTER сервер ребутнется"
reboot
