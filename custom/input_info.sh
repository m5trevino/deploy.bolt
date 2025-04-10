#!/bin/bash

# Colors and styling
GREEN="\033[32m"
CYAN="\033[36m"
MAGENTA="\033[35m"
RED="\033[31m"
RESET="\033[0m"

print_header() {
    clear
    echo -e "\033[35m"
    echo "╔══════════════════════════════════════╗"
    echo "║          INPUT MODEL INFO            ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "\033[0m"
}

# Store collected info
declare -A model_info

collect_info() {
    print_header
    
    echo -e "${CYAN}[+] Enter Model Details${RESET}"
    read -p "Model Name (e.g., Mistral-7B-Instruct): " model_info[name]
    read -p "Provider (e.g., TheBloke): " model_info[provider]
    read -p "Full Repo Path (e.g., TheBloke/Mistral-7B-Instruct-v0.1-GGUF): " model_info[repo]
    read -p "Minimum RAM Required (in GB): " model_info[ram]
    
    # Check for existing tokens
    if [ -f "/home/flintx/deploy.bolt/custom/tokens/hf_token" ]; then
        model_info[hf_token]=$(cat /home/flintx/deploy.bolt/custom/tokens/hf_token)
        echo -e "${GREEN}[✓] Found existing HuggingFace token${RESET}"
    else
        read -p "HuggingFace Token: " model_info[hf_token]
        echo "${model_info[hf_token]}" > /home/flintx/deploy.bolt/custom/tokens/hf_token
    fi
    
    if [ -f "/home/flintx/deploy.bolt/custom/tokens/ngrok_token" ]; then
        model_info[ngrok_token]=$(cat /home/flintx/deploy.bolt/custom/tokens/ngrok_token)
        echo -e "${GREEN}[✓] Found existing Ngrok token${RESET}"
    else
        read -p "Ngrok Token: " model_info[ngrok_token]
        echo "${model_info[ngrok_token]}" > /home/flintx/deploy.bolt/custom/tokens/ngrok_token
    fi

    # Save all info to a temp file for other scripts
    echo "MODEL_NAME=${model_info[name]}" > /home/flintx/deploy.bolt/custom/temp_model_info
    echo "PROVIDER=${model_info[provider]}" >> /home/flintx/deploy.bolt/custom/temp_model_info
    echo "REPO_PATH=${model_info[repo]}" >> /home/flintx/deploy.bolt/custom/temp_model_info
    echo "MIN_RAM=${model_info[ram]}" >> /home/flintx/deploy.bolt/custom/temp_model_info
    echo "HF_TOKEN=${model_info[hf_token]}" >> /home/flintx/deploy.bolt/custom/temp_model_info
    echo "NGROK_TOKEN=${model_info[ngrok_token]}" >> /home/flintx/deploy.bolt/custom/temp_model_info

    echo -e "\n${GREEN}[✓] Information collected successfully!${RESET}"
    echo -e "${CYAN}[+] Handing off to create_custom.sh...${RESET}"
    
    bash /home/flintx/deploy.bolt/custom/create_custom.sh
}

collect_info
