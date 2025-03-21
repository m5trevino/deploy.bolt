#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔥 STARTING PROJECT FIXER 🔥${NC}"

# Fix permissions
echo -e "${YELLOW}Fixing permissions...${NC}"
sudo chown -R $USER:$USER .
sudo chmod -R 755 .
sudo chmod +x *.sh

# Clean up duplicate configs
echo -e "${YELLOW}Cleaning config structure...${NC}"
rm -rf config/
mkdir -p configs/llm_configs

# Fix config files
echo -e "${YELLOW}Setting up configs...${NC}"
for config in configs/llm_configs/*.json; do
    if [ -f "$config" ]; then
        chmod 644 "$config"
    fi
done

# Create active model symlink
echo -e "${YELLOW}Setting up active model...${NC}"
cd configs
rm -f active_model.json
ln -sf llm_configs/codellama.json active_model.json
cd ..

# Fix provider files
echo -e "${YELLOW}Setting up providers...${NC}"
mkdir -p providers
chmod 755 providers/*.ts

# Setup environment
echo -e "${YELLOW}Creating environment file...${NC}"
cat > .env.local << EOF
OPENAI_LIKE_API_BASE_URL=http://localhost:8000
VITE_LOG_LEVEL=debug
DEFAULT_NUM_CTX=8192
EOF
chmod 600 .env.local

# Update launch script
echo -e "${YELLOW}Updating launch script...${NC}"
cat > launch_bolt.sh << 'EOF'
#!/bin/bash
source venv/bin/activate
if [ -f "configs/active_model.json" ]; then
    ./server.sh &
    sleep 2
    cd bolt.diy && pnpm dev
else
    echo "No active model config found!"
    exit 1
fi
EOF
chmod +x launch_bolt.sh

# Update server script
echo -e "${YELLOW}Updating server script...${NC}"
cat > server.sh << 'EOF'
#!/bin/bash
source venv/bin/activate
python server.py
EOF
chmod +x server.sh

echo -e "${GREEN}✅ FIXES APPLIED!${NC}"
echo -e "${YELLOW}Run these commands:${NC}"
echo -e "1. ./bolt_setup.sh"
echo -e "2. ./launch_bolt.sh"