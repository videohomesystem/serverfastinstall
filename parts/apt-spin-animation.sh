#!/bin/bash
#
#
C_RED="\033[91m"
C_YELLOW="\033[93m"
C_WHITE="\e[1;37m"
C_RESET="\033[0m"
#
run_with_spinner() {
    local cmd="$1"
    local message="${2:-Command run}"
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
printf "${C_WHITE} System update is running ${C_RESET}\n"
run_with_spinner "apt update -qq" "Update packages"

run_with_spinner "apt-get dist-upgrade -y" "The system update start..."
printf "${C_WHITE} The system has been updated. ${C_RESET}\n"
