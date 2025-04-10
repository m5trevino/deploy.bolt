#!/bin/bash

# Colors for that street style
GREEN="\033[32m"
CYAN="\033[36m"
RED="\033[31m"
RESET="\033[0m"

print_header() {
    clear
    echo -e "$CYAN"
    echo "    ╔══════════════════════════════════════╗"
    echo "    ║          VERIFY CUSTOM               ║"
    echo "    ╚══════════════════════════════════════╝"
    echo -e "$RESET"
}

check_step() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}[-] Failed: $1${RESET}"
        exit 1
    fi
    echo -e "${GREEN}[✓] Success: $1${RESET}"
}

# Get model name from temp_model_info
MODEL_NAME=$(grep "MODEL_NAME=" /home/flintx/deploy.bolt/custom/temp_model_info | cut -d'=' -f2 | tr '[:upper:]' '[:lower:]')

# Main execution
print_header

# Check if all required files exist
echo -e "${CYAN}[+] Verifying files...${RESET}"

FILES=(
    "/home/flintx/bolt.diy/app/lib/modules/llm/registry.ts"
    "/home/flintx/bolt.diy/app/lib/modules/llm/types.ts"
    "/home/flintx/bolt.diy/app/lib/modules/llm/providers/${MODEL_NAME}-local.ts"
    "/home/flintx/bolt.diy/.env.local"
    "/home/flintx/bolt.diy/vite.config.ts"
    "/home/flintx/bolt.diy/api/${MODEL_NAME}.py"  # Added API file check
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}[✓] Found: $file${RESET}"
    else
        echo -e "${RED}[×] Missing: $file${RESET}"
        exit 1
    fi
done

# Archive the config files
echo -e "\n${CYAN}[+] Archiving config files...${RESET}"

# Create archive directory
ARCHIVE_DIR="/home/flintx/deploy.bolt/archive/${MODEL_NAME}"
mkdir -p "$ARCHIVE_DIR"
check_step "Creating archive directory"

# Archive files with their original names
declare -A files=(
    ["/home/flintx/bolt.diy/app/lib/modules/llm/registry.ts"]="registry.ts"
    ["/home/flintx/bolt.diy/app/lib/modules/llm/types.ts"]="types.ts"
    ["/home/flintx/bolt.diy/app/lib/modules/llm/providers/${MODEL_NAME}-local.ts"]="${MODEL_NAME}-local.ts"
    ["/home/flintx/bolt.diy/.env.local"]=".env.local"
    ["/home/flintx/bolt.diy/vite.config.ts"]="vite.config.ts"
    ["/home/flintx/bolt.diy/api/${MODEL_NAME}.py"]="${MODEL_NAME}.py"  # Added API file archiving
)

for src in "${!files[@]}"; do
    dst="$ARCHIVE_DIR/${files[$src]}"
    cp "$src" "$dst"
    check_step "Archiving ${files[$src]}"
done

echo -e "\n${GREEN}[✓] All config files verified and archived!${RESET}"
echo -e "${CYAN}[+] Archive location: ${ARCHIVE_DIR}${RESET}"

echo -e "\n${GREEN}[✓] Verification complete! Ready for model download.${RESET}"
echo -e "${CYAN}[+] Handing off to get.model.py...${RESET}"

# Launch get.model.py in new terminal
xfce4-terminal --title="GET.MODEL" --command="python3 /home/flintx/deploy.bolt/spin/get.model.py"
