#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}⚙️ Setting up configurations...${NC}"

# Setup bolt.diy configs
cd ~/bolt.diy || exit 1

# Install dependencies
echo -e "${CYAN}Installing bolt.diy dependencies...${NC}"
pnpm install

# Create .env.local if it doesn't exist
if [ ! -f .env.local ]; then
    cat > .env.local << 'ENVEOF'
THEBLOKE_API_BASE_URL=http://localhost:8000
THEBLOKE_API_KEY=sk-1234567890
OPENAI_LIKE_API_BASE_URL=http://localhost:8000
VITE_LOG_LEVEL=debug
DEFAULT_NUM_CTX=8192
VITE_DEFAULT_SYSTEM_PROMPT="You are a helpful AI assistant."
INSTALL_DIR=/home/flintx/llm-server
BOLT_DIR=/home/flintx/bolt.diy
MODELS_DIR=/home/flintx/models
PORT=3000
HOST=0.0.0.0
ENVEOF
    echo -e "${GREEN}✅ Created .env.local${NC}"
fi

# Hand off to server setup
echo -e "${CYAN}Moving to server setup...${NC}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
chmod +x "${SCRIPT_DIR}/server_setup.sh"
exec "${SCRIPT_DIR}/server_setup.sh"
