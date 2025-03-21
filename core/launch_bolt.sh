#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to setup HuggingFace token
setup_hf_token() {
    echo -e "${CYAN}Enter your HuggingFace token:${NC}"
    read -r token
    mkdir -p ~/.huggingface
    echo "$token" > ~/.huggingface/token
    chmod 600 ~/.huggingface/token
    echo -e "${GREEN}✅ HuggingFace token saved!${NC}"
}

# Function to setup ngrok token
setup_ngrok_token() {
    echo -e "${CYAN}Enter your ngrok authtoken:${NC}"
    read -r token
    mkdir -p ~/.ngrok
    cat > ~/.ngrok/ngrok.yml << EOF
authtoken: $token
version: 2
EOF
    chmod 600 ~/.ngrok/ngrok.yml
    echo -e "${GREEN}✅ ngrok token saved!${NC}"
}

echo -e "${GREEN}🚀 Checking required tokens...${NC}"

# Check for HuggingFace token
if [ -f ~/.huggingface/token ]; then
    echo -e "${GREEN}✅ HuggingFace token found${NC}"
else
    echo -e "${YELLOW}⚠️  HuggingFace token not found!${NC}"
    while true; do
        echo -e "${CYAN}Do you want to set it up now? (y/n)${NC}"
        read -r answer
        case $answer in
            [Yy]* ) setup_hf_token; break;;
            [Nn]* ) echo -e "${RED}❌ HuggingFace token required!${NC}"; exit 1;;
            * ) echo "Please answer y or n.";;
        esac
    done
fi

# Check for ngrok token
if [ -f ~/.ngrok/ngrok.yml ]; then
    echo -e "${GREEN}✅ ngrok token found${NC}"
else
    echo -e "${YELLOW}⚠️  ngrok token not found!${NC}"
    while true; do
        echo -e "${CYAN}Do you want to set it up now? (y/n)${NC}"
        read -r answer
        case $answer in
            [Yy]* ) setup_ngrok_token; break;;
            [Nn]* ) echo -e "${RED}❌ ngrok token required!${NC}"; exit 1;;
            * ) echo "Please answer y or n.";;
        esac
    done
fi

echo -e "${GREEN}🚀 Setting up model config...${NC}"

# Check if we're in the venv
if [[ "$VIRTUAL_ENV" == "" ]]; then
    echo -e "${YELLOW}⚠️  Activating virtual environment...${NC}"
    source /home/flintx/venv/bin/activate
fi

# Copy selected model config to active_model.json
CONFIG_DIR="/home/flintx/deploy.bolt/src/configs"
if [ ! -f "$CONFIG_DIR/active_model.json" ]; then
    echo -e "${RED}❌ No active model config found!${NC}"
    exit 1
fi

echo -e "${GREEN}🚀 Starting services...${NC}"

echo -e "${CYAN}Starting LLM Server in current terminal...${NC}"
# Use python explicitly to run main.py
python /home/flintx/deploy.bolt/core/main.py &
SERVER_PID=$!

# Wait a bit for server to start
sleep 2

echo -e "${CYAN}Starting bolt.diy in new terminal...${NC}"
gnome-terminal -- bash -c "source /home/flintx/venv/bin/activate && /home/flintx/deploy.bolt/src/scripts/server.sh" &

echo -e "${CYAN}Starting ngrok tunnel in new terminal...${NC}"
gnome-terminal -- bash -c "source /home/flintx/venv/bin/activate && /home/flintx/deploy.bolt/src/scripts/expose.sh" &

echo -e "${GREEN}✅ Services starting up:${NC}"
echo "1. LLM Server: Running in this terminal"
echo "2. bolt.diy: Check new terminal"
echo "3. ngrok: Check new terminal"

# Wait for server process
wait $SERVER_PID