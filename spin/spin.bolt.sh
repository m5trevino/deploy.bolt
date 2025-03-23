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
    echo "    ║             SPIN.BOLT                ║"
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

# Check if bolt.diy exists
if [ ! -d "/home/flintx/bolt.diy" ]; then
    echo -e "${RED}[!] bolt.diy not found! Cloning...${RESET}"
    git clone https://github.com/abacus-ai/bolt.diy.git /home/flintx/bolt.diy
    check_step "Cloning bolt.diy"
fi

# Setup bolt.diy
cd /home/flintx/bolt.diy || exit 1

echo -e "${CYAN}[+] Installing dependencies...${RESET}"
pnpm install
check_step "Installing dependencies"

# Copy over our custom files
echo -e "${CYAN}[+] Setting up custom files...${RESET}"
mkdir -p app/lib/modules/llm/providers
check_step "Creating provider directory"

# Start bolt.diy
echo -e "${GREEN}[+] Starting bolt.diy...${RESET}"
pnpm run dev &
check_step "Starting bolt.diy server"

# Wait a bit to ensure server starts
sleep 5

echo -e "\n${GREEN}[✓] Bolt.DIY is spinning up!${RESET}"
echo -e "${CYAN}[+] Handing off to expose.bolt.sh...${RESET}"

# Launch expose.bolt.sh in new window
xfce4-terminal --title="EXPOSE.BOLT" --command="bash /home/flintx/deploy.bolt/spin/expose.bolt.sh"

