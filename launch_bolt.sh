#!/bin/bash
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check and get tokens
check_tokens() {
    # Check HuggingFace token
    if [ ! -f ~/.huggingface/token ]; then
        echo -e "${YELLOW}⚠️  HuggingFace token not found${NC}"
        read -p "Enter your HuggingFace token (hf_...): " hf_token
        mkdir -p ~/.huggingface
        echo "$hf_token" > ~/.huggingface/token
        echo -e "${GREEN}✅ HuggingFace token saved${NC}"
    else
        echo -e "${GREEN}✅ HuggingFace token found${NC}"
    fi

    # Check ngrok token
    if ! ngrok config check >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  ngrok token not configured${NC}"
        read -p "Enter your ngrok authtoken: " ngrok_token
        ngrok config add-authtoken "$ngrok_token"
        echo -e "${GREEN}✅ ngrok token configured${NC}"
    else
        echo -e "${GREEN}✅ ngrok token found${NC}"
    fi
}

# Kill any existing processes first
pkill -f "pnpm dev"
pkill -f "ngrok"
sleep 2

echo -e "${CYAN}🚀 Checking required tokens...${NC}"
check_tokens

echo -e "${CYAN}🚀 Setting up model config...${NC}"

# Make sure configs directory exists
mkdir -p /home/flintx/deploy.bolt/configs

# Copy selected model config to active_model.json
cp /home/flintx/deploy.bolt/configs/llm_configs/mistral-7b.json /home/flintx/deploy.bolt/configs/active_model.json

# Update model path in active_model.json to point to /root/models
sed -i 's|"model_path": ".*"|"model_path": "/root/models/mistral-7b-v0.1.Q4_K_M.gguf"|' /home/flintx/deploy.bolt/configs/active_model.json

echo -e "${CYAN}Starting LLM Server in current terminal...${NC}"
echo -e "${YELLOW}Loading model shards and CUDA setup - this might take a minute...${NC}"
cd /home/flintx/deploy.bolt

# Check if llama-cpp-python is installed
if ! pip show llama-cpp-python > /dev/null; then
    echo -e "${YELLOW}Installing llama-cpp-python with CUDA support...${NC}"
    CMAKE_ARGS="-DLLAMA_CUBLAS=on" pip install llama-cpp-python
fi

# Verify model exists
if [ ! -f "/root/models/mistral-7b-v0.1.Q4_K_M.gguf" ]; then
    echo -e "${RED}❌ Model not found at /root/models/mistral-7b-v0.1.Q4_K_M.gguf${NC}"
    exit 1
fi

python3 main.py &
LLM_PID=$!

# Wait a bit to make sure LLM is loading
sleep 3

# Terminal 1 - bolt.diy
echo -e "${CYAN}Starting bolt.diy in new terminal...${NC}"
mate-terminal --title="bolt.diy" --command="bash -c 'cd /home/flintx/bolt.diy && echo -e \"${CYAN}Starting bolt.diy dev server...${NC}\" && pnpm dev; read -p \"Press Enter to close...\"'" &

# Terminal 2 - ngrok (on port 5173)
echo -e "${CYAN}Starting ngrok tunnel in new terminal...${NC}"
mate-terminal --title="ngrok" --command="bash -c 'echo -e \"${CYAN}Starting ngrok tunnel...${NC}\" && ngrok http 5173; read -p \"Press Enter to close...\"'" &

echo -e "${GREEN}✅ Services starting up:${NC}"
echo -e "${YELLOW}1. LLM Server: Running in this terminal${NC}"
echo -e "${YELLOW}2. bolt.diy: Check new terminal${NC}"
echo -e "${YELLOW}3. ngrok: Check new terminal${NC}"

# Show ngrok URL after a few seconds
sleep 5
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"[^"]*' | grep -o 'https://[^"]*')
if [ -n "$NGROK_URL" ]; then
    echo -e "${GREEN}✅ Ngrok URL: ${NGROK_URL}${NC}"
fi

# Keep the script running and show LLM output
wait $LLM_PID
