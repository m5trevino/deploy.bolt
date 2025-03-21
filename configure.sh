#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${PURPLE}${BOLD}Configuration Wizard${NC}"

# Detect installation directory
if [ -d "/workspace/llm-server" ]; then
    INSTALL_DIR="/workspace/llm-server"
elif [ -d "$HOME/llm-server" ]; then
    INSTALL_DIR="$HOME/llm-server"
else
    echo -e "${CYAN}Enter your installation directory:${NC}"
    read -r INSTALL_DIR
fi

ENV_FILE="${INSTALL_DIR}/.env"
TOKENS_FILE="${INSTALL_DIR}/.tokens"

# Create files if they don't exist
if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE"
    chmod 600 "$ENV_FILE"
fi

if [ ! -f "$TOKENS_FILE" ]; then
    touch "$TOKENS_FILE"
    chmod 600 "$TOKENS_FILE"
fi

# Function to get a configuration value
get_config() {
    local key="$1"
    local default="$2"
    local prompt="$3"
    local current=""
    
    # Check if the key exists in the .env file
    if [ -f "$ENV_FILE" ]; then
        current=$(grep "^$key=" "$ENV_FILE" | cut -d= -f2)
    fi
    
    # If current is empty, use default
    if [ -z "$current" ]; then
        current="$default"
    fi
    
    # Prompt user for input
    echo -e "${YELLOW}$prompt (current: $current):${NC}"
    read -r value
    
    # If user didn't enter anything, use current value
    if [ -z "$value" ]; then
        value="$current"
    fi
    
    echo "$value"
}

# Function to update a configuration value
update_config() {
    local key="$1"
    local value="$2"
    
    # Check if the key exists in the .env file
    if [ -f "$ENV_FILE" ] && grep -q "^$key=" "$ENV_FILE"; then
        # Use awk instead of sed for more reliable replacement
        awk -v key="$key" -v val="$value" '{
            if ($0 ~ "^"key"=") {
                print key"="val
            } else {
                print $0
            }
        }' "$ENV_FILE" > "${ENV_FILE}.tmp" && mv "${ENV_FILE}.tmp" "$ENV_FILE"
    else
        # Add the key
        echo "$key=$value" >> "$ENV_FILE"
    fi
}

# Function to save a token
save_token() {
    local key="$1"
    local value="$2"
    
    # Check if the key exists in the tokens file
    if grep -q "^$key=" "$TOKENS_FILE"; then
        # Use awk instead of sed for more reliable replacement
        awk -v key="$key" -v val="$value" '{
            if ($0 ~ "^"key"=") {
                print key"="val
            } else {
                print $0
            }
        }' "$TOKENS_FILE" > "${TOKENS_FILE}.tmp" && mv "${TOKENS_FILE}.tmp" "$TOKENS_FILE"
    else
        # Add the key
        echo "$key=$value" >> "$TOKENS_FILE"
    fi
}

# Main configuration menu
echo -e "${CYAN}Welcome to the configuration wizard!${NC}"
echo -e "${CYAN}This wizard will help you configure your LLM server.${NC}"

# Model configuration
echo -e "\n${PURPLE}${BOLD}Model Configuration${NC}"
echo -e "${CYAN}Select your model:${NC}"
echo -e "1) CodeLlama 7B (Recommended for most users)"
echo -e "2) CodeLlama 13B (Better but needs more VRAM)"
echo -e "3) DeepSeek Coder 6.7B"
echo -e "4) DeepSeek Coder 33B (Best but needs lots of VRAM)"
echo -e "5) Custom model"
read -r model_choice

case $model_choice in
    1) model="codellama/CodeLlama-7b-Instruct-hf" ;;
    2) model="codellama/CodeLlama-13b-Instruct-hf" ;;
    3) model="deepseek-ai/deepseek-coder-6.7b-instruct" ;;
    4) model="deepseek-ai/deepseek-coder-33b-instruct" ;;
    5) model=$(get_config "MODEL_NAME" "codellama/CodeLlama-7b-Instruct-hf" "Enter the model name") ;;
    *) model="codellama/CodeLlama-7b-Instruct-hf" ;;
esac
update_config "MODEL_NAME" "$model"

# System paths configuration
echo -e "\n${PURPLE}${BOLD}System Paths Configuration${NC}"
cache_dir=$(get_config "TRANSFORMERS_CACHE" "$HOME/.cache/huggingface" "Enter the HuggingFace cache directory")
update_config "TRANSFORMERS_CACHE" "$cache_dir"
update_config "HF_HOME" "$cache_dir"

# Model parameters
echo -e "\n${PURPLE}${BOLD}Model Parameters${NC}"
ctx=$(get_config "DEFAULT_NUM_CTX" "4096" "Enter the context window size (2048-8192)")
update_config "DEFAULT_NUM_CTX" "$ctx"

max_tokens=$(get_config "DEFAULT_MAX_TOKENS" "2000" "Enter the maximum tokens to generate")
update_config "DEFAULT_MAX_TOKENS" "$max_tokens"

temp=$(get_config "DEFAULT_TEMPERATURE" "0.7" "Enter the temperature (0.1-1.0)")
update_config "DEFAULT_TEMPERATURE" "$temp"

top_p=$(get_config "DEFAULT_TOP_P" "0.95" "Enter the top_p value (0.1-1.0)")
update_config "DEFAULT_TOP_P" "$top_p"

# GPU Configuration
echo -e "\n${PURPLE}${BOLD}GPU Configuration${NC}"
if command -v nvidia-smi &> /dev/null; then
    echo -e "${GREEN}NVIDIA GPU detected!${NC}"
    nvidia-smi
    echo -e "${CYAN}Enter GPU device number (0 for first GPU, all for all GPUs):${NC}"
    read -r gpu_choice
    update_config "CUDA_VISIBLE_DEVICES" "${gpu_choice:-0}"
else
    echo -e "${YELLOW}No GPU detected, using CPU mode${NC}"
    update_config "CUDA_VISIBLE_DEVICES" ""
fi

# API Keys
echo -e "\n${PURPLE}${BOLD}API Keys${NC}"
echo -e "${CYAN}Do you want to configure HuggingFace API key? (y/n)${NC}"
read -r configure_hf
if [[ $configure_hf == "y" || $configure_hf == "Y" ]]; then
    hf_key=$(get_config "HUGGINGFACE_API_KEY" "" "Enter your HuggingFace API key")
    update_config "HUGGINGFACE_API_KEY" "$hf_key"
    save_token "HUGGINGFACE_API_KEY" "$hf_key"
fi

# Ngrok configuration
echo -e "\n${PURPLE}${BOLD}Ngrok Configuration${NC}"
echo -e "${CYAN}Do you want to configure Ngrok? (y/n)${NC}"
read -r configure_ngrok
if [[ $configure_ngrok == "y" || $configure_ngrok == "Y" ]]; then
    ngrok_token=$(get_config "NGROK_AUTH_TOKEN" "" "Enter your Ngrok auth token")
    update_config "NGROK_AUTH_TOKEN" "$ngrok_token"
    save_token "NGROK_AUTH_TOKEN" "$ngrok_token"
    
    echo -e "${CYAN}Select ngrok region:${NC}"
    echo -e "1) United States (us) [default]"
    echo -e "2) Europe (eu)"
    echo -e "3) Asia/Pacific (ap)"
    echo -e "4) Australia (au)"
    echo -e "5) South America (sa)"
    echo -e "6) Japan (jp)"
    echo -e "7) India (in)"
    read -r region_choice

    case $region_choice in
        2) ngrok_region="eu" ;;
        3) ngrok_region="ap" ;;
        4) ngrok_region="au" ;;
        5) ngrok_region="sa" ;;
        6) ngrok_region="jp" ;;
        7) ngrok_region="in" ;;
        *) ngrok_region="us" ;;
    esac
    update_config "NGROK_REGION" "$ngrok_region"
fi

echo -e "\n${GREEN}Configuration completed!${NC}"
echo -e "${CYAN}Your settings have been saved to:${NC}"
echo -e "  ${YELLOW}Config: ${ENV_FILE}${NC}"
echo -e "  ${YELLOW}Tokens: ${TOKENS_FILE}${NC}"