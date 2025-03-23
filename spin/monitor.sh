#!/bin/bash

# Colors for that street style
GREEN="\033[32m"
CYAN="\033[36m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

print_header() {
    clear
    echo -e "$CYAN"
    echo "    ╔══════════════════════════════════════╗"
    echo "    ║             MONITOR                  ║"
    echo "    ╚══════════════════════════════════════╝"
    echo -e "$RESET"
}

check_process() {
    if pgrep -f "$1" > /dev/null; then
        echo -e "${GREEN}[✓] $2 is running${RESET}"
    else
        echo -e "${RED}[×] $2 is not running${RESET}"
    fi
}

check_port() {
    if netstat -tuln | grep ":$1 " > /dev/null; then
        echo -e "${GREEN}[✓] Port $1 is open${RESET}"
    else
        echo -e "${RED}[×] Port $1 is closed${RESET}"
    fi
}

check_resources() {
    echo -e "\n${CYAN}[+] System Resources:${RESET}"
    echo -e "${YELLOW}CPU Usage:${RESET} $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
    echo -e "${YELLOW}Memory Usage:${RESET} $(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}')"
    echo -e "${YELLOW}Disk Usage:${RESET} $(df -h / | awk 'NR==2{print $5}')"
}

while true; do
    print_header
    echo -e "\n${CYAN}[+] Checking Services:${RESET}"
    check_process "llama_cpp.server" "Model Server"
    check_process "pnpm run dev" "Bolt.DIY"
    check_process "ngrok" "Ngrok"
    
    echo -e "\n${CYAN}[+] Checking Ports:${RESET}"
    check_port "8000"  # Model Server
    check_port "5173"  # Bolt.DIY
    check_port "4040"  # Ngrok UI
    
    check_resources
    
    # Show ngrok URL if available
    if [[ -f "/home/flintx/deploy.bolt/ngrok.log" ]]; then
        NGROK_URL=$(grep -o 'https://.*\.ngrok-free\.app' "/home/flintx/deploy.bolt/ngrok.log" | tail -n1)
        if [[ ! -z "$NGROK_URL" ]]; then
            echo -e "\n${CYAN}[+] Ngrok URL:${RESET} $NGROK_URL"
        fi
    fi
    
    sleep 5
    clear
done
