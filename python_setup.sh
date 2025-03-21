#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🐍 Setting up Python environment...${NC}"

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required packages
echo -e "${CYAN}Installing Python packages...${NC}"
pip install --upgrade pip
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install fastapi uvicorn huggingface_hub transformers

# Save venv path for later
echo "BOLT_VENV=$(pwd)/venv" > ~/.bolt_venvs.conf

# Test imports
echo -e "${CYAN}Testing Python setup...${NC}"
python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Python setup failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Python environment ready!${NC}"

# Hand off to config setup
echo -e "${CYAN}Moving to config setup...${NC}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
chmod +x "${SCRIPT_DIR}/setup_configs.sh"
exec "${SCRIPT_DIR}/setup_configs.sh"
