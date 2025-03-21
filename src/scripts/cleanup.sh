#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🧹 Cleaning up processes...${NC}"

# Function to kill process and its children
kill_process() {
    local pattern=$1
    local name=$2
    if pgrep -f "$pattern" > /dev/null; then
        pkill -f "$pattern"
        sleep 1
        if ! pgrep -f "$pattern" > /dev/null; then
            echo -e "${GREEN}✅ Stopped $name${NC}"
        else
            echo -e "${RED}❌ Failed to stop $name${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✅ $name not running${NC}"
    fi
}

# Kill processes in reverse order
kill_process "ngrok" "ngrok"
kill_process "pnpm dev" "bolt.diy"
kill_process "server.sh" "LLM server"

# Clean log files
cd /home/flintx/deploy.bolt
rm -f ngrok.log server.log bolt.log
echo -e "${GREEN}✅ Cleaned log files${NC}"

# Clean ports
for port in 3000 4040 8000; do
    if netstat -tuln | grep ":$port " > /dev/null; then
        fuser -k "$port/tcp" 2>/dev/null
        echo -e "${GREEN}✅ Freed port $port${NC}"
    fi
done

echo -e "${GREEN}✅ All processes stopped and cleaned up!${NC}"
