#!/bin/bash
#
#
#
#
#
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
printf "\n\033[93m Запускается обновление системы, это займет какое-то время \033[0m\n"
run_with_spinner "apt update -qq" "Обновление списков пакетов"

run_with_spinner "apt upgrade -y -qq" "Обновление системы"
printf "\n\033[93m Система обновлена \033[0m\n"
