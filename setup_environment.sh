#!/bin/bash

# Cyberpunk-themed colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Parse command line arguments
MODE=""
for arg in "$@"; do
    case $arg in
        --mode=*)
        MODE="${arg#*=}"
        shift
        ;;
    esac
done

# ASCII Art Banner
echo -e "${PURPLE}"
cat << "EOF"
 _    _    __  __    ____  ____ ____    ____ ____
| |   | |   |  \/  |  / ___|| ____|  _ \ \   / / ____|  _ \ 
| |   | |   | |\/| |  \___ \|  _| | |_) \ \ / /|  _| | |_) |
| |___| |___| |  | |   ___) | |___|  _ < \ V / | |___|  _ < 
|____|____|_|  |_|  |____/|____|_| \_\ \_/  |____|_| \_\
  
EOF
echo -e "${CYAN}${BOLD}Universal Setup for bolt.diy with Local LLM Integration${NC}\n"

# Function to print section header
print_header() {
    echo -e "\n${PURPLE}${BOLD}[+] $1 ${NC}\n"
}

# Function to print step
print_step() {
    echo -e "${CYAN}[*] $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}[✗] $1${NC}"
    exit 1
}

# Function to check if bolt.diy exists
check_bolt_exists() {
    if [ -d "bolt.diy" ]; then
        if [ "$MODE" = "fresh" ]; then
            print_error "bolt.diy already exists! Use overwrite mode to replace it."
        elif [ "$MODE" = "overwrite" ]; then
            print_step "Removing existing bolt.diy..."
            rm -rf bolt.diy
        fi
    fi
}

# Function to check system requirements
check_system_requirements() {
    print_header "CHECKING SYSTEM REQUIREMENTS"
    
    # Check RAM
    TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    print_step "Available RAM: ${TOTAL_RAM}GB"
    
    if [ "$TOTAL_RAM" -lt 16 ]; then
        print_error "Less than 16GB RAM detected. Some models might not work properly."
    fi
    
    # Check disk space
    FREE_SPACE=$(df -h . | awk 'NR==2 {print $4}' | sed 's/G//')
    print_step "Available disk space: ${FREE_SPACE}GB"
    
    if [ "${FREE_SPACE%.*}" -lt 100 ]; then
        print_error "Less than 100GB free space. LLM models require significant storage."
    fi
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 not found. Please install Python 3.8 or higher"
    fi
    
    # Check pip
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 not found. Please install pip3"
    fi
    
    # Check git
    if ! command -v git &> /dev/null; then
        print_error "git not found. Please install git"
    fi
    
    print_success "System requirements checked"
}

# Function to setup Python environment
setup_python_env() {
    print_header "SETTING UP PYTHON ENVIRONMENT"
    
    # Create virtual environment
    python3 -m venv venv
    source venv/bin/activate
    
    # Install base requirements
    pip install --upgrade pip
    pip install torch transformers accelerate bitsandbytes fastapi uvicorn python-dotenv
    
    print_success "Python environment setup complete"
}

# Function to clone and setup bolt.diy
setup_bolt_diy() {
    print_header "SETTING UP BOLT.DIY"
    
    if [ "$MODE" = "fresh" ] || [ "$MODE" = "overwrite" ]; then
        git clone https://github.com/bolt-diy/bolt.diy.git
        cd bolt.diy || print_error "Failed to enter bolt.diy directory"
        npm install
        cd ..
    fi
    
    print_success "bolt.diy setup complete"
}

# Function to create directory structure
create_directory_structure() {
    print_header "CREATING DIRECTORY STRUCTURE"
    
    mkdir -p api-server
    mkdir -p llm-providers/providers
    mkdir -p models
    mkdir -p configs/llm_configs
    mkdir -p cache
    mkdir -p logs
    
    # Set permissions
    chmod -R 755 api-server
    chmod -R 755 llm-providers
    chmod -R 755 configs
    
    print_success "Directory structure created"
}

# Function to setup LLM configuration
setup_llm_config() {
    print_header "LLM CONFIGURATION"
    
    # GPU Detection
    if command -v nvidia-smi &> /dev/null; then
        echo -e "${GREEN}NVIDIA GPU detected!${NC}"
        nvidia-smi
        
        # Get GPU memory
        GPU_MEM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | awk '{print $1/1024}')
        echo -e "${CYAN}GPU Memory: ${GPU_MEM}GB${NC}"
        
        # Show available models based on GPU memory
        echo -e "${CYAN}Available LLM models:${NC}"
        if (( $(echo "$GPU_MEM < 8" | bc -l) )); then
            echo -e "1) Mistral-7B (Recommended for your GPU)"
            DEFAULT_MODEL="mistral-7b"
        elif (( $(echo "$GPU_MEM < 24" | bc -l) )); then
            echo -e "1) Mistral-7B"
            echo -e "2) Mixtral-8x7B"
            DEFAULT_MODEL="mixtral-8x7b"
        else
            echo -e "1) Mistral-7B"
            echo -e "2) Mixtral-8x7B"
            echo -e "3) CodeLlama-34B"
            DEFAULT_MODEL="codellama-34b"
        fi
    else
        echo -e "${YELLOW}No NVIDIA GPU found, defaulting to CPU mode${NC}"
        echo -e "1) Mistral-7B (Recommended for CPU)"
        DEFAULT_MODEL="mistral-7b"
    fi
    
    read -r model_choice
    
    case $model_choice in
        1) SELECTED_MODEL="mistral-7b" ;;
        2) SELECTED_MODEL="mixtral-8x7b" ;;
        3) SELECTED_MODEL="codellama-34b" ;;
        *) SELECTED_MODEL="$DEFAULT_MODEL" ;;
    esac
    
    # Create symlink to selected model config
    ln -sf "$(pwd)/configs/llm_configs/${SELECTED_MODEL}.json" "configs/active_model.json"
    
    print_success "Selected model: $SELECTED_MODEL"
}

# Function to setup environment files
setup_env_files() {
    print_header "SETTING UP ENVIRONMENT FILES"
    
    # Create .env.local
    cat > .env.local << EOF
# LLM Configuration
OPENAI_LIKE_API_BASE_URL=http://127.0.0.1:8000
VITE_LOG_LEVEL=debug

# Model Settings
DEFAULT_NUM_CTX=8192
EOF
    
    # HuggingFace token setup
    echo -e "${YELLOW}Want to set up your HuggingFace token? (recommended) (y/n)${NC}"
    read -r configure_hf
    if [[ $configure_hf == "y" || $configure_hf == "Y" ]]; then
        echo -e "${CYAN}Drop your HuggingFace token:${NC}"
        read -r hf_token
        echo "HUGGINGFACE_API_KEY=$hf_token" >> .env.local
    fi
    
    # ngrok setup
    echo -e "${YELLOW}Want to set up ngrok to expose your server? (y/n)${NC}"
    read -r configure_ngrok
    if [[ $configure_ngrok == "y" || $configure_ngrok == "Y" ]]; then
        echo -e "${CYAN}Drop your ngrok token:${NC}"
        read -r ngrok_token
        echo "NGROK_AUTH_TOKEN=$ngrok_token" >> .env.local
        
        echo -e "${CYAN}Pick your ngrok region (us, eu, ap, au, sa, jp, in) [default: us]:${NC}"
        read -r ngrok_region
        ngrok_region=${ngrok_region:-us}
        echo "NGROK_REGION=$ngrok_region" >> .env.local
    fi
    
    chmod 600 .env.local
    print_success "Environment files created"
}

# Main execution
print_header "BOLT.DIY SETUP SCRIPT"
echo -e "${CYAN}Mode: ${MODE}${NC}"

# Check mode
if [ -z "$MODE" ]; then
    print_error "No mode specified. Use --mode=fresh or --mode=overwrite"
fi

# Check system requirements
check_system_requirements

# Check and handle existing bolt.diy
check_bolt_exists

# Create directory structure
create_directory_structure

# Setup Python environment
setup_python_env

# Clone and setup bolt.diy
setup_bolt_diy

# Setup LLM configuration
setup_llm_config

# Setup environment files
setup_env_files

print_header "SETUP COMPLETE"
echo -e "${GREEN}Everything's ready to roll!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Start bolt.diy: ${CYAN}./launch_bolt.sh${NC}"
echo -e "2. Start the server: ${CYAN}./server.sh${NC}"
echo -e "3. Expose to internet: ${CYAN}./expose.sh${NC}"

print_success "Ready to rock! 🚀"