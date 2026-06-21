#!/bin/bash

vercheck=$(cat /etc/debian_version 2>/dev/null | tr -d ' ' | head -n1)
sysctlc="/etc/sysctl.conf"                              #-- 12
sysctl13="/usr/lib/sysctl.d/50-custom.conf"             #-- 13

#======================================================
#sysctlc="/etc/sysctl.conf" 

if [[ "$vercheck" == 12.* ]]; then
# BBR enable
# BBR - современный алгоритм Google, увеличивает пропускную способность на 20-40% при высоких задержках
# BBR - modern google algorithm, incrased bandwitch of network over 20-40%, under high latency conditions
echo "net.core.default_qdisc = fq" >> $sysctlc 
echo "net.ipv4.tcp_congestion_control = bbr" >> $sysctlc

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
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

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

printf "\033[93m Изменения systemctl $vercheck внесены \033[0m"
/sbin/sysctl --load $sysctl13
else
    printf "\033[91m \nSystemctl was not configured, unknown error\033[0m \n"
fi
