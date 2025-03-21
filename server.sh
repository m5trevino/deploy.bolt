#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if port is provided
PORT=${1:-8000}

echo -e "${YELLOW}Starting server on port ${PORT}...${NC}"

# Activate virtual environment if it exists
if [ -d "$HOME/venv" ]; then
    source "$HOME/venv/bin/activate"
fi

# Start the server
echo -e "${GREEN}Starting FastAPI server...${NC}"
python3 -m uvicorn main:app --host 0.0.0.0 --port $PORT
