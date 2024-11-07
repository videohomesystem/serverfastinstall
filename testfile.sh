#!/bin/bash
#============================================================================================================================
srcl="/etc/apt/sources.list" #--переменная сорц листа
sysctlc="/etc/sysctl.conf"
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

#
printf "\033[93m Готово. \033[0m"
read -p "Задачи завершены. После нажатия ENTER сервер ребутнется"
