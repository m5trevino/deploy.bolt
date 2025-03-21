#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔍 BOLT.DIY ENVIRONMENT CHECK${NC}"

# Detect shell
detect_shell() {
    if [[ "$SHELL" == *"zsh"* ]]; then
        echo "zsh"
        RC_FILE="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        echo "bash"
        RC_FILE="$HOME/.bashrc"
    else
        echo "sh"
        RC_FILE="$HOME/.profile"
    fi
}

# Check Node environment
check_node() {
    echo -e "\n${YELLOW}[+] Checking Node.js environment...${NC}"
    if ! command -v node &> /dev/null; then
        echo -e "${RED}[✗] Node.js not found!${NC}"
        return 1
    fi
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}[✗] npm not found!${NC}"
        return 1
    fi
    echo -e "${GREEN}[✓] Node.js environment OK${NC}"
    return 0
}

# Setup Node if needed
setup_node() {
    echo -e "\n${YELLOW}[+] Setting up Node.js...${NC}"
    sudo apt-get update
    sudo apt-get install nodejs npm -y
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    node -v
}

# Check pnpm
check_pnpm() {
    echo -e "\n${YELLOW}[+] Checking pnpm...${NC}"
    if ! command -v pnpm &> /dev/null; then
        echo -e "${RED}[✗] pnpm not found!${NC}"
        return 1
    fi
    echo -e "${GREEN}[✓] pnpm OK${NC}"
    return 0
}

# Setup pnpm if needed
setup_pnpm() {
    echo -e "\n${YELLOW}[+] Setting up pnpm...${NC}"
    curl -fsSL https://get.pnpm.io/install.sh | sh -
    source $RC_FILE
}

# Check bolt.diy
check_bolt() {
    echo -e "\n${YELLOW}[+] Checking bolt.diy installation...${NC}"
    if [[ ! -d "$HOME/bolt.diy" ]]; then
        echo -e "${RED}[✗] bolt.diy not found!${NC}"
        return 1
    fi
    if [[ ! -f "$HOME/bolt.diy/package.json" ]]; then
        echo -e "${RED}[✗] bolt.diy installation incomplete!${NC}"
        return 1
    fi
    echo -e "${GREEN}[✓] bolt.diy OK${NC}"
    return 0
}

# Main flow
main() {
    # Detect shell first
    SHELL_TYPE=$(detect_shell)
    echo -e "${GREEN}[✓] Detected shell: $SHELL_TYPE${NC}"

    # Check/Setup Node
    if ! check_node; then
        setup_node
    fi

    # Check/Setup pnpm
    if ! check_pnpm; then
        setup_pnpm
    fi

    # Check bolt.diy
    if ! check_bolt; then
        echo -e "${YELLOW}[!] bolt.diy needs setup${NC}"
        return 1
    fi

    echo -e "\n${GREEN}[✓] Environment check complete!${NC}"
    return 0
}

main