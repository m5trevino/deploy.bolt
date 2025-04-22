#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

echo "─────────────────── Installing Bolt.diy and Ngrok ───────────────────"

# Navigate to the deploy.bolt directory
cd /home/flintx/deploy.bolt

# --- Install Bolt.diy ---
echo "\n[+] Cloning Bolt.diy repository..."
git clone -b stable https://github.com/stackblitz-labs/bolt.diy /home/flintx/deploy.bolt/bolt.diy
echo "✓ Bolt.diy cloned."

# Change into Bolt.diy directory for further setup
cd /home/flintx/deploy.bolt/bolt.diy

echo "\n[+] Updating package list and installing Node.js and npm..."
sudo apt-get update
sudo apt-get install nodejs npm -y
echo "✓ Node.js and npm installed."

echo "\n[+] Installing NVM (Node Version Manager)..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash

# Source nvm explicitly in the script to make it available
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
echo "✓ NVM installed."

echo "\n[+] Installing Node.js LTS via NVM..."
# NOTE: Running nvm install with sudo can cause permission issues.
# It's generally recommended to run this as the regular user.
# Assuming user is running this script with sudo, this might inherit root.
# If permissions issues arise, this step might need adjustment or manual execution by the user.
sudo nvm install --lts # <-- Potential source of permission issues if run as root
node_version=$(node -v)
echo "✓ Node.js LTS installed: $node_version"

echo "\n[+] Installing pnpm..."
curl -fsSL https://get.pnpm.io/install.sh | sh -

# Add pnpm to PATH explicitly in the script
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
echo "✓ pnpm installed."

# Ensure we are in the Bolt.diy directory for pnpm install
cd /home/flintx/deploy.bolt/bolt.diy

echo "\n[+] Running pnpm install in Bolt.diy directory..."
pnpm install
echo "✓ pnpm dependencies installed."

# Navigate back to the deploy.bolt directory
cd /home/flintx/deploy.bolt
echo "✓ Returned to deploy.bolt directory."

# --- Install Ngrok ---
echo "\n────────────────────── Installing Ngrok ──────────────────────"
echo "\n[+] Downloading Ngrok..."
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz -O /tmp/ngrok.tgz
echo "✓ Ngrok downloaded to /tmp."

echo "\n[+] Extracting Ngrok..."
tar -xvzf /tmp/ngrok.tgz -C /tmp/
echo "✓ Ngrok extracted to /tmp."

echo "\n[+] Moving ngrok executable to /usr/local/bin..."
sudo mv /tmp/ngrok /usr/local/bin/
echo "✓ ngrok moved to /usr/local/bin."

echo "\n[+] Cleaning up..."
rm /tmp/ngrok.tgz
echo "✓ Cleanup complete."

echo "\n[+] Verifying Ngrok installation..."
ngrok_version=$(ngrok version)
echo "✓ Ngrok installed: $ngrok_version"

echo "\n────────────────── Installation Complete ──────────────────"

# This script finishes here. The next step (tokens.py) is launched by run.py or another orchestrator.
