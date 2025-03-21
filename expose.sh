#!/bin/bash

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Starting ngrok tunnel...${NC}"

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo "Installing ngrok..."
    curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
    sudo apt update && sudo apt install ngrok
fi

# Start ngrok in background
nohup ngrok http 3000 > ngrok.log 2>&1 &

# Wait for ngrok to generate URL
sleep 5

# Get the ngrok URL
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"[^"]*' | grep -o 'https://[^"]*')

if [ -n "$NGROK_URL" ]; then
    echo -e "${GREEN}✅ Ngrok tunnel started at: ${NGROK_URL}${NC}"
else
    echo "❌ Failed to get ngrok URL"
    exit 1
fi

# Hand off to launch_bolt.sh
echo -e "${CYAN}Starting bolt.diy...${NC}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
chmod +x "${SCRIPT_DIR}/launch_bolt.sh"
exec "${SCRIPT_DIR}/launch_bolt.sh"
