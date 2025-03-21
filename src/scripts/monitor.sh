#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

DEPLOY_DIR="/home/flintx/deploy.bolt"
BOLT_DIR="/home/flintx/bolt.diy"
MODELS_DIR="/home/flintx/models"

check_process() {
    if pgrep -f "$1" > /dev/null; then
        echo -e "${GREEN}✅ $2 is running${NC}"
        return 0
    else
        echo -e "${RED}❌ $2 is not running${NC}"
        return 1
    fi
}

check_port() {
    if netstat -tuln | grep ":$1 " > /dev/null; then
        echo -e "${GREEN}✅ Port $1 is open${NC}"
        return 0
    else
        echo -e "${RED}❌ Port $1 is not open${NC}"
        return 1
    fi
}

echo -e "${CYAN}🔍 Checking system status...${NC}"

# Check directories
for dir in "$DEPLOY_DIR" "$BOLT_DIR" "$MODELS_DIR"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✅ Directory exists: $dir${NC}"
    else
        echo -e "${RED}❌ Directory missing: $dir${NC}"
    fi
done

# Check processes
check_process "server.sh" "LLM Server"
check_process "pnpm dev" "Bolt.DIY UI"
check_process "ngrok" "Ngrok Tunnel"

# Check ports
check_port "8000"  # LLM Server
check_port "3000"  # Bolt.DIY
check_port "4040"  # Ngrok admin

# Check ngrok URL
if [ -f "$DEPLOY_DIR/ngrok.log" ]; then
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"[^"]*' | grep -o 'https://[^"]*')
    if [ -n "$NGROK_URL" ]; then
        echo -e "${GREEN}✅ Ngrok URL: ${NGROK_URL}${NC}"
    else
        echo -e "${RED}❌ Ngrok URL not found${NC}"
    fi
fi

# Check available models
echo -e "\n${CYAN}Available Models:${NC}"
for config in "$DEPLOY_DIR"/configs/llm_configs/*.json; do
    if [ -f "$config" ]; then
        model_name=$(basename "$config" .json)
        if grep -q "name" "$config"; then
            model_name=$(grep "name" "$config" | cut -d'"' -f4)
        fi
        echo -e "${GREEN}✅ $model_name${NC}"
    fi
done

# Check logs for errors
for log in "$DEPLOY_DIR"/{server.log,bolt.log,ngrok.log}; do
    if [ -f "$log" ]; then
        if grep -i "error\|exception\|failed" "$log" > /dev/null; then
            echo -e "${YELLOW}⚠️ Found errors in $(basename "$log")${NC}"
        else
            echo -e "${GREEN}✅ No errors in $(basename "$log")${NC}"
        fi
    fi
done

# Check memory usage
MEM_USAGE=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
echo -e "${YELLOW}💾 Memory usage: ${MEM_USAGE}${NC}"

# Check GPU usage
if command -v nvidia-smi &> /dev/null; then
    GPU_USAGE=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits | awk -F', ' '{print $1"% GPU, "$2"MB/"$3"MB VRAM"}')
    echo -e "${YELLOW}🎮 GPU usage: ${GPU_USAGE}${NC}"
fi

echo -e "\n${CYAN}💡 Use option 5 to clean shutdown when done${NC}"
