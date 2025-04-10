#!/bin/bash

# Colors for that street style
GREEN="\033[32m"
CYAN="\033[36m"
MAGENTA="\033[35m"
RED="\033[31m"
RESET="\033[0m"

print_header() {
    clear
    echo -e "$CYAN"
    echo "    ╔══════════════════════════════════════╗"
    echo "    ║            EXPOSE.BOLT               ║"
    echo "    ╚══════════════════════════════════════╝"
    echo -e "$RESET"
}

check_step() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}[-] Failed: $1${RESET}"
        exit 1
    fi
    echo -e "${GREEN}[✓] Success: $1${RESET}"
}

# Main execution
print_header

# Check ngrok installation
if ! command -v ngrok &> /dev/null; then
    echo -e "${RED}[!] ngrok not found! Installing...${RESET}"
    curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
        sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
        echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | \
        sudo tee /etc/apt/sources.list.d/ngrok.list && \
        sudo apt update && sudo apt install ngrok
    check_step "Installing ngrok"
fi

# Load ngrok token
source /home/flintx/deploy.bolt/custom/temp_model_info

# Configure ngrok
echo -e "${CYAN}[+] Configuring ngrok...${RESET}"
ngrok config add-authtoken "${NGROK_TOKEN}"
check_step "Configuring ngrok"

# Start ngrok
echo -e "${CYAN}[+] Starting ngrok tunnel...${RESET}"
ngrok http 5173 --log=stdout > /home/flintx/deploy.bolt/ngrok.log &
check_step "Starting ngrok tunnel"

# Wait for ngrok to start
sleep 5

# Get and display ngrok URL
echo -e "${CYAN}[+] Fetching ngrok URL...${RESET}"
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"[^"]*' | grep -o 'https://[^"]*')
echo -e "${GREEN}[✓] Ngrok URL: ${NGROK_URL}${RESET}"

echo -e "\n${GREEN}[✓] Exposure complete! Starting monitor...${RESET}"
echo -e "${CYAN}[+] Handing off to monitor.sh...${RESET}"

# Launch monitor in new window
xfce4-terminal --title="MONITOR" --command="bash /home/flintx/deploy.bolt/spin/monitor.sh"

