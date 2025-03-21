#!/bin/bash
# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

cd /home/flintx/deploy.bolt || exit 1
source venv/bin/activate

echo -e "${CYAN}Starting FastAPI server...${NC}"
python3 main.py
