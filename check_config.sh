#!/bin/bash
# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔍 Checking setup...${NC}"

# Check directories
for dir in "/home/flintx/deploy.bolt" "/home/flintx/bolt.diy" "/home/flintx/models"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✅ Found: $dir${NC}"
    else
        echo -e "${RED}❌ Missing: $dir${NC}"
    fi
done

# Check model files
if ls /home/flintx/models/*.gguf 1> /dev/null 2>&1; then
    echo -e "${GREEN}✅ Found model files${NC}"
else
    echo -e "${RED}❌ No model files found${NC}"
fi

# Check configs
if ls /home/flintx/deploy.bolt/configs/llm_configs/*.json 1> /dev/null 2>&1; then
    echo -e "${GREEN}✅ Found LLM configs${NC}"
else
    echo -e "${RED}❌ No LLM configs found${NC}"
fi

# Check venv
if [ -d "/home/flintx/deploy.bolt/venv" ]; then
    echo -e "${GREEN}✅ Found Python venv${NC}"
else
    echo -e "${RED}❌ Missing Python venv${NC}"
fi
