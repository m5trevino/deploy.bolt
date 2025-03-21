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

echo -e "${CYAN}🔧 Setting up bolt.diy environment...${NC}"

# Check CUDA/GPU
if command -v nvidia-smi &> /dev/null; then
    echo -e "${GREEN}✅ NVIDIA GPU found${NC}"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
else
    echo -e "${YELLOW}⚠️ No NVIDIA GPU found - will run in CPU mode${NC}"
fi

# Create necessary directories
DIRS=(
    "$DEPLOY_DIR"
    "$BOLT_DIR"
    "$MODELS_DIR"
    "$DEPLOY_DIR/configs"
    "$DEPLOY_DIR/configs/llm_configs"
)

for dir in "${DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "${GREEN}✅ Created: $dir${NC}"
    fi
done

# Set permissions
chmod -R 755 "$DEPLOY_DIR"
chmod -R 755 "$BOLT_DIR"
chmod -R 755 "$MODELS_DIR"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python3 not found! Installing...${NC}"
    sudo apt update && sudo apt install -y python3 python3-pip python3-venv
fi

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found! Installing...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# Check pnpm
if ! command -v pnpm &> /dev/null; then
    echo -e "${RED}❌ pnpm not found! Installing...${NC}"
    curl -fsSL https://get.pnpm.io/install.sh | sh -
    source ~/.bashrc
fi

# Hand off to python setup
echo -e "${CYAN}Base environment ready! Moving to Python setup...${NC}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
chmod +x "${SCRIPT_DIR}/python_setup.sh"
exec "${SCRIPT_DIR}/python_setup.sh"
