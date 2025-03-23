#!/bin/bash

# Colors for that street style
GREEN="\033[32m"
CYAN="\033[36m"
MAGENTA="\033[35m"
RED="\033[31m"
RESET="\033[0m"

# Function to print that cyberpunk header
print_header() {
    echo -e "$MAGENTA"
    cat /home/flintx/deploy.bolt/ascii/dependencies.ascii.txt
    echo -e "$RESET"
}

# Error checking function
check_step() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}[-] Failed: $1${RESET}"
        exit 1
    fi
    echo -e "${GREEN}[✓] Success: $1${RESET}"
}

print_header
echo -e "${CYAN}[+] Setting up your Python environment...${RESET}\n"

# List them environments
echo -e "${MAGENTA}Available Python versions:${RESET}"
pyenv versions | nl
echo -e "\n${CYAN}Choose your move:${RESET}"
echo "1. Use existing pyenv"
echo "2. Create new venv"
echo -e "3. Exit\n"

read -p "Select option (1-3): " choice

case $choice in
    1)
        echo -e "\n${CYAN}Select version number from list above:${RESET}"
        read -p "> " version_num
        selected_version=$(pyenv versions | sed -n "${version_num}p" | awk "{print \$1}")
        if [ -z "$selected_version" ]; then
            echo -e "${RED}[-] Invalid version selected${RESET}"
            exit 1
        fi
        echo -e "${CYAN}[+] Activating $selected_version${RESET}"
        pyenv global $selected_version
        check_step "Pyenv activation"
        ;;
    2)
        echo -e "\n${CYAN}Name your new environment:${RESET}"
        read -p "> " venv_name
        echo -e "${CYAN}[+] Creating new environment: $venv_name${RESET}"
        mkdir -p /home/flintx/deploy.bolt/$venv_name
        python -m venv /home/flintx/deploy.bolt/$venv_name
        check_step "Environment creation"
        source /home/flintx/deploy.bolt/$venv_name/bin/activate
        check_step "Environment activation"
        ;;
    3)
        echo -e "${CYAN}Peace out!${RESET}"
        exit 0
        ;;
    *)
        echo -e "${RED}[-] Invalid choice my guy!${RESET}"
        exit 1
        ;;
esac

# Upgrade pip in the selected environment
echo -e "\n${CYAN}[+] Upgrading pip...${RESET}"
python -m pip install --upgrade pip
check_step "Pip upgrade"

# Install requirements
echo -e "\n${CYAN}[+] Installing requirements...${RESET}"
pip install -r requirements.txt
check_step "Requirements installation"

echo -e "\n${GREEN}[✓] Environment setup complete!${RESET}"
echo -e "${CYAN}[+] You ready to cook! 🚀${RESET}\n"
