#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Create dirs
mkdir -p /home/flintx/{deploy.bolt,bolt.diy,models}
mkdir -p /home/flintx/deploy.bolt/configs/llm_configs

# Setup Python venv
cd /home/flintx/deploy.bolt
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Fix permissions
chmod +x *.sh *.py
chown -R flintx:flintx /home/flintx/deploy.bolt
chown -R flintx:flintx /home/flintx/bolt.diy
chown -R flintx:flintx /home/flintx/models

echo -e "${GREEN}✅ Quick setup done!${NC}"
