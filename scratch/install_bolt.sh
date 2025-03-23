#!/bin/bash

# Function for that cyberpunk header
print_header() {
    echo -e "\033[35m"
    cat /home/flintx/deploy.bolt/ascii/install_bolt.ascii.txt
    echo -e "\033[0m"
}

# Function to check if command succeeded
check_step() {
    if [ $? -ne 0 ]; then
        echo -e "\033[31mFailed at: $1\033[0m"
        exit 1
    fi
}

print_header

echo -e "\033[36m[+] Starting bolt.diy installation...\033[0m"

# Clone bolt.diy
cd /home/flintx
git clone -b stable https://github.com/stackblitz-labs/bolt.diy
check_step "Cloning bolt.diy"

cd bolt.diy
check_step "Changing to bolt.diy directory"

# Install system dependencies
echo -e "\033[36m[+] Installing system dependencies...\033[0m"
sudo apt-get update
check_step "apt-get update"
sudo apt-get install nodejs npm -y
check_step "Installing nodejs and npm"

# Install nvm
echo -e "\033[36m[+] Setting up nvm...\033[0m"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
check_step "Installing nvm"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node LTS
echo -e "\033[36m[+] Installing Node LTS...\033[0m"
nvm install --lts
check_step "Installing Node LTS"

# Install pnpm
echo -e "\033[36m[+] Installing pnpm...\033[0m"
curl -fsSL https://get.pnpm.io/install.sh | sh -
check_step "Installing pnpm"
export PNPM_HOME="\$HOME/.local/share/pnpm"
export PATH="\$PNPM_HOME:\$PATH"

# Install project dependencies
echo -e "\033[36m[+] Installing project dependencies...\033[0m"
pnpm install
check_step "pnpm install"

echo -e "\033[32m[✓] bolt.diy installation complete!\033[0m"

# Hand off to dependencies.sh
echo -e "\033[36m[+] Handing off to dependencies setup...\033[0m"
bash /home/flintx/deploy.bolt/scratch/dependencies.sh
