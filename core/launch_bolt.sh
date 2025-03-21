#!/bin/zsh

# Cyberpunk colors
NEON_GREEN='\033[38;5;10m'
CYBER_PURPLE='\033[38;5;165m'
CYBER_PINK='\033[38;5;201m'
CYBER_BLUE='\033[38;5;51m'
NC='\033[0m'

# Directories
BOLT_DIR="/home/flintx/bolt.diy"
DEPLOY_DIR="/home/flintx/deploy.bolt"

# Activate pyenv
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
pyenv activate bolt-env

echo -e "${CYBER_PURPLE}╔════════════════════════════════════════╗${NC}"
echo -e "${CYBER_PURPLE}║${NEON_GREEN} 🚀 BOLT.DIY LAUNCH SEQUENCE INITIATED ${CYBER_PURPLE}║${NC}"
echo -e "${CYBER_PURPLE}╚════════════════════════════════════════╝${NC}"

# Function to check if a process is running on a port
port_in_use() {
    lsof -i :$1 >/dev/null 2>&1
}

# Kill any existing processes
if port_in_use 8000; then
    echo -e "${CYBER_PINK}[!] Port 8000 in use. Terminating process...${NC}"
    sudo kill $(lsof -t -i:8000)
fi

if port_in_use 3000; then
    echo -e "${CYBER_PINK}[!] Port 3000 in use. Terminating process...${NC}"
    sudo kill $(lsof -t -i:3000)
fi

# Start bolt.diy server
echo -e "${NEON_GREEN}[+] Launching bolt.diy...${NC}"
mate-terminal --title="BOLT.DIY Server" --command="zsh -c 'cd \"$BOLT_DIR\" && npm run dev; read \"?Press Enter to close...\"'" &

# Start ngrok tunnel
echo -e "${NEON_GREEN}[+] Establishing secure tunnel...${NC}"
mate-terminal --title="NGROK Tunnel" --command="zsh -c 'eval \"\$(pyenv init -)\" && eval \"\$(pyenv virtualenv-init -)\" && pyenv activate bolt-env && cd \"$DEPLOY_DIR\" && ngrok http 3000; read \"?Press Enter to close...\"'" &

# Give terminals time to open
sleep 2

# Start LLM server
echo -e "${NEON_GREEN}[+] Initializing LLM Server...${NC}"
echo -e "${CYBER_BLUE}[*] Starting in current terminal...${NC}"
nice -n 10 sudo -E python3 core/main.py
