#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${PURPLE}${BOLD}🚀 Launching bolt.diy LLM Server...${NC}"

# Check for active model config
ACTIVE_CONFIG="configs/active_model.json"
if [ ! -f "$ACTIVE_CONFIG" ]; then
    echo -e "${RED}❌ No active model config found!${NC}"
    echo -e "${YELLOW}Run bolt_custom.sh to set up a model first, my guy!${NC}"
    exit 1
fi

# Function to check if jq is installed
check_jq() {
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}Installing jq for JSON parsing...${NC}"
        sudo apt-get update && sudo apt-get install -y jq
    fi
}

# Function to load active LLM configuration
load_llm_config() {
    echo -e "${CYAN}Loading active LLM configuration...${NC}"
    export SELECTED_MODEL=$(jq -r '.name' "$ACTIVE_CONFIG")
    export MODEL_PATH=$(jq -r '.settings.model_path' "$ACTIVE_CONFIG")
    export QUANTIZATION=$(jq -r '.settings.quantization // "4-bit"' "$ACTIVE_CONFIG")
    echo -e "${GREEN}Selected Model: $SELECTED_MODEL${NC}"
}

# Ask for bolt directory if not specified
if [ -z "$BOLT_DIR" ]; then
    if [ -d "$HOME/bolt.diy" ]; then
        BOLT_DIR="$HOME/bolt.diy"
    else
        echo -e "${CYAN}Where's your bolt.diy installed? (default: $HOME/bolt.diy)${NC}"
        read -r BOLT_DIR_INPUT
        BOLT_DIR=${BOLT_DIR_INPUT:-"$HOME/bolt.diy"}
    fi
fi

# Set up Node environment
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Check if bolt.diy exists
if [ ! -d "$BOLT_DIR" ]; then
    echo -e "${RED}❌ bolt.diy directory not found at ${BOLT_DIR}${NC}"
    echo -e "${YELLOW}Run bolt_setup.sh first, my guy!${NC}"
    exit 1
fi

# Check system resources
echo -e "${CYAN}Checking system resources...${NC}"
TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
GPU_INFO=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null || echo "0")
GPU_MEM=$((GPU_INFO / 1024))

echo -e "${CYAN}Available RAM: ${GREEN}${TOTAL_MEM}GB${NC}"
if [ "$GPU_MEM" -gt "0" ]; then
    echo -e "${CYAN}Available GPU Memory: ${GREEN}${GPU_MEM}GB${NC}"
else
    echo -e "${YELLOW}No GPU detected - Running in CPU mode${NC}"
fi

# Install dependencies and load config
check_jq
load_llm_config

# Start the LLM server first
echo -e "${CYAN}Starting LLM Server...${NC}"
./server.sh &
SERVER_PID=$!

# Wait for server to be ready
echo -e "${YELLOW}Waiting for server to start...${NC}"
for i in {1..30}; do
    if curl -s http://localhost:8000/health > /dev/null; then
        echo -e "${GREEN}Server is ready!${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}Server failed to start!${NC}"
        kill $SERVER_PID 2>/dev/null
        exit 1
    fi
    sleep 1
done

# Check if we got enough resources for the selected model
MIN_RAM_NEEDED=8
if [ "$TOTAL_MEM" -lt "$MIN_RAM_NEEDED" ]; then
    echo -e "${RED}⚠️  Warning: Your system might not have enough RAM to run large models${NC}"
    echo -e "${YELLOW}Consider using a smaller model or increasing your RAM${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        kill $SERVER_PID 2>/dev/null
        exit 1
    fi
fi

# Start bolt.diy
echo -e "${CYAN}Starting bolt.diy with model: ${GREEN}$SELECTED_MODEL${NC}"
cd "$BOLT_DIR"

# Launch with the appropriate package manager
if command -v pnpm &> /dev/null; then
    echo -e "${GREEN}Launching with pnpm...${NC}"
    pnpm run dev &
else
    echo -e "${YELLOW}pnpm not found, using npm instead...${NC}"
    npm run dev &
fi
BOLT_PID=$!

# Setup ngrok if wanted
echo -e "\n${YELLOW}Want to expose your server with ngrok? (y/n)${NC}"
read -r use_ngrok
if [[ $use_ngrok == "y" || $use_ngrok == "Y" ]]; then
    ./expose.sh &
    NGROK_PID=$!
fi

echo -e "\n${GREEN}🚀 Everything is running!${NC}"
echo -e "${CYAN}Local URLs:${NC}"
echo -e "  ${YELLOW}bolt.diy UI: http://localhost:5173${NC}"
echo -e "  ${YELLOW}LLM Server: http://localhost:8000${NC}"

# Monitor and handle Ctrl+C
echo -e "\n${YELLOW}Press Ctrl+C to stop everything${NC}"
trap "kill $SERVER_PID $BOLT_PID $NGROK_PID 2>/dev/null; exit" SIGINT

# Monitor the processes
while true; do
    if ! kill -0 $SERVER_PID 2>/dev/null; then
        echo -e "${RED}Server crashed! Restarting...${NC}"
        ./server.sh &
        SERVER_PID=$!
    fi
    
    if ! kill -0 $BOLT_PID 2>/dev/null; then
        echo -e "${RED}bolt.diy crashed! Restarting...${NC}"
        cd "$BOLT_DIR"
        pnpm run dev &
        BOLT_PID=$!
    fi
    sleep 5
done