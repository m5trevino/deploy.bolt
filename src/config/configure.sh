#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🎯 Final configuration...${NC}"

# Create model config
mkdir -p ~/llm-server/configs/llm_configs
cat > ~/llm-server/configs/llm_configs/mistral-7b-v0.1-gguf.json << 'JSONEOF'
{
    "name": "mistral-7b-v0.1-gguf",
    "provider": "TheBloke",
    "model_type": "local",
    "max_tokens": 8192,
    "base_url_key": "TheBloke_LOCAL_API_BASE_URL",
    "provider_file": "mistral-7b-v0.1-gguf-local.ts",
    "api_handler": "mistral-7b-v0.1-gguf.py",
    "requirements": {
        "vram_gb": 5,
        "cuda_required": true
    },
    "settings": {
        "temperature": 0.7,
        "top_p": 0.95,
        "context_window": 8192,
        "model_path": "TheBloke/Mistral-7B-v0.1-GGUF",
        "quantization": "4-bit"
    }
}
JSONEOF

echo -e "${GREEN}✅ Created model config${NC}"

# Download model if not exists
MODEL_PATH="/home/flintx/models/mistral-7b-v0.1.Q4_K_M.gguf"
if [ ! -f "$MODEL_PATH" ]; then
    echo -e "${CYAN}Downloading model...${NC}"
    python3 -c "
from huggingface_hub import hf_hub_download
hf_hub_download(
    repo_id='TheBloke/Mistral-7B-v0.1-GGUF',
    filename='mistral-7b-v0.1.Q4_K_M.gguf',
    local_dir='/home/flintx/models'
)
"
fi

# Hand off to expose script
echo -e "${CYAN}Starting services...${NC}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
chmod +x "${SCRIPT_DIR}/expose.sh"
exec "${SCRIPT_DIR}/expose.sh"
