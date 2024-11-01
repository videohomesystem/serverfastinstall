#!/bin/bash
# ===================================================== Должно работать =====================================================
FILE="/etc/apt/sources.list" #--переменная сорц листа
#
###########################################################################################################################
#-----------------------Этап 2 - чистим файл сорц, вводим нормальные репы ------------------------------------------------
printf "\033[93m Изменение репозиториев... \033[0m"
#- чистим файл
echo -e "" > $FILE
# Добавляем новые строки в файл
echo -e "deb http://deb.debian.org/debian bookworm main non-free-firmware" >> $FILE
echo -e "deb-src http://deb.debian.org/debian bookworm main non-free-firmware" >> $FILE
#
echo -e "deb http://security.debian.org/debian-security bookworm-security main non-free-firmware" >> $FILE
echo -e "deb-src http://security.debian.org/debian-security bookworm-security main non-free-firmware" >> $FILE

echo -e "deb http://deb.debian.org/debian bookworm-updates main non-free-firmware" >> $FILE
echo -e "deb-src http://deb.debian.org/debian bookworm-updates main non-free-firmware" >> $FILE
#
###########################################################################################################################
#
printf "\033[93m Запускается обновление системы... \033[0m"
apt update && apt upgrade -y # - индексирует содержимое репозиториев > обновляет систему > скипает вопросы установщика
printf "\033[93m Система обновлена \033[0m"
#
printf "\033[93m Выполняется установка приложений.. \033[0m"
applications=(apt-transport-https ca-certificates fail2ban mcedit) #------ Тут пишем аппсы, БЕЗ запятых, ТОЛЬКО с пробелами
#
for app in "${applications[@]}"
do
    sudo apt install -y "$app"
done
###########################################################################################################################
sysctlc="/etc/sysctl.conf"
echo "net.core.default_qdisc=fq" >> $sysctlc
echo "net.ipv4.tcp_congestion_control=bbr" >> $sysctlc
sysctl -p
SYSRESULT="$(sysctl -a | grep congestion)"
printf "\033[93m Изменения в ядро $SYSRESULT внесены  \033[0m"
###########################################################################################################################
#--- 3x UI
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
#============================================================================"
#
printf "\033[93m Запуск очистки системы от старых пакетов... \033[0m"
apt autoremove -y #--- чистим старые пакеты автоудалятором
#
printf "\033[93m Готово. \033[0m"
read -p "Задачи завершены. После нажатия ENTER сервер ребутнется"
reboot
