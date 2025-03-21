#!/bin/bash

INSTALL_DIR="/home/flintx/llm-server"
BOLT_DIR="/home/flintx/bolt.diy"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Create directories with proper permissions
mkdir -p "${INSTALL_DIR}/configs/llm_configs"
mkdir -p "${BOLT_DIR}/app/lib/modules/llm/providers"
chmod -R 755 "${INSTALL_DIR}/configs"
chmod -R 755 "${BOLT_DIR}/app/lib/modules/llm"

# Get LLM details from user
echo -e "\n${CYAN}📝 Enter LLM details:${NC}"
read -p "Enter LLM name (e.g., mixtral-8x7b): " llm_name
read -p "Enter provider name (e.g., mistralai): " provider_name
read -p "Enter display name (e.g., Mixtral): " display_name
read -p "Enter model path (HF repo or local): " model_path
read -p "Enter VRAM required (GB): " vram_gb
read -p "Enter max tokens: " max_tokens

# Sanitize name
safe_name=$(echo "$llm_name" | tr '/' '-' | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

# Create JSON config
cat > "${INSTALL_DIR}/configs/llm_configs/${safe_name}.json" << EOF
{
    "name": "${safe_name}",
    "provider": "${provider_name}",
    "model_type": "local",
    "max_tokens": ${max_tokens},
    "base_url_key": "${provider_name}_LOCAL_API_BASE_URL",
    "provider_file": "${safe_name}-local.ts",
    "api_handler": "${safe_name}.py",
    "requirements": {
        "vram_gb": ${vram_gb},
        "cuda_required": true
    },
    "settings": {
        "temperature": 0.7,
        "top_p": 0.95,
        "context_window": ${max_tokens},
        "model_path": "${model_path}",
        "quantization": "4-bit"
    }
}
EOF

# Create provider file
cat > "${BOLT_DIR}/app/lib/modules/llm/providers/${safe_name}-local.ts" << EOF
import { BaseProvider, getOpenAILikeModel } from '../base-provider';
import type { ModelInfo } from '../types';
import type { IProviderSetting } from '~/types/model';
import type { LanguageModelV1 } from 'ai';
import { logger } from '~/utils/logger';

export default class ${provider_name^}Provider extends BaseProvider {
    name = '${provider_name}';
    displayName = '${display_name}';
    getApiKeyLink = 'http://localhost:8000';
    labelForGetApiKey = 'Local Server';
    icon = 'i-carbon-machine-learning-model';
    requiresApiKey = false;
    config = {
        baseUrlKey: '${provider_name^^}_API_BASE_URL',
        apiTokenKey: '${provider_name^^}_API_KEY',
        baseUrl: 'http://localhost:8000',
        modelPath: '${model_path}',
        quantization: '4-bit'
    };
    staticModels: ModelInfo[] = [
        { 
            name: '${safe_name}', 
            label: '${display_name}', 
            provider: '${provider_name}', 
            maxTokenAllowed: ${max_tokens},
            contextWindow: ${max_tokens},
            pricing: { prompt: 0, completion: 0 }
        }
    ];
    getModelInstance(options: {
        model: string;
        serverEnv?: Record<string, string>;
        apiKeys?: Record<string, string>;
        providerSettings?: Record<string, IProviderSetting>;
    }): LanguageModelV1 {
        const { model } = options;
        const { baseUrl, apiKey } = this.getProviderBaseUrlAndKey({
            apiKeys: options.apiKeys,
            providerSettings: options.providerSettings?.[this.name],
            serverEnv: options.serverEnv,
            defaultBaseUrlKey: this.config.baseUrlKey,
            defaultApiTokenKey: this.config.apiTokenKey
        });
        const finalBaseUrl = baseUrl || this.config.baseUrl;
        const finalApiKey = apiKey || 'sk-1234567890';
        
        logger.debug('${provider_name} Provider:', { 
            baseUrl: finalBaseUrl, 
            model,
            modelPath: this.config.modelPath,
            quantization: this.config.quantization
        });
        return getOpenAILikeModel(finalBaseUrl, finalApiKey, model);
    }
}
EOF

# Create registry.ts
cat > "${BOLT_DIR}/app/lib/modules/llm/registry.ts" << EOF
import ${provider_name^}LocalProvider from './providers/${safe_name}-local';

export {
    ${provider_name^}LocalProvider,
};
EOF

# Create .env.local
cat > "${BOLT_DIR}/.env.local" << EOF
${provider_name^^}_API_BASE_URL=http://localhost:8000
${provider_name^^}_API_KEY=sk-1234567890
VITE_LOG_LEVEL=debug
DEFAULT_NUM_CTX=${max_tokens}
INSTALL_DIR=${INSTALL_DIR}
BOLT_DIR=${BOLT_DIR}
EOF

chmod 600 "${BOLT_DIR}/.env.local"

# Create download_model.py with the fixed token input handling
cat > "${INSTALL_DIR}/download_model.py" << 'EOF'
#!/usr/bin/env python3
from huggingface_hub import hf_hub_download
import sys
import logging
import os
import json
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('download.log')
    ]
)

def get_hf_token():
    # Try environment variable first
    token = os.getenv('HF_TOKEN')
    if token:
        return token
        
    # Try token file next
    token_path = os.path.expanduser('~/.huggingface/token')
    if os.path.exists(token_path):
        with open(token_path, 'r') as f:
            return f.read().strip()
    
    # If no token found, prompt user        
    while True:
        print("\n🔑 Hugging Face token required!")
        print("Get your token from: https://huggingface.co/settings/tokens")
        token = input("Enter token (or 'q' to quit): ").strip()
        
        if token.lower() == 'q':
            print("Download cancelled.")
            sys.exit(0)
            
        if token:
            # Save token for future use
            os.makedirs(os.path.expanduser('~/.huggingface'), exist_ok=True)
            with open(token_path, 'w') as f:
                f.write(token)
            return token
            
        print("Token cannot be empty! Try again...")

def download_model():
    try:
        # Get active model config
        config_path = "/home/flintx/llm-server/configs/active_model.json"
        with open(config_path, 'r') as f:
            config = json.load(f)

        model_path = config['settings']['model_path']
        model_name = config['name']

        # Set correct filename based on model
        if "TheBloke" in model_path and "Mistral-7B" in model_path:
            filename = "mistral-7b-v0.1.Q4_K_M.gguf"
        else:
            filename = f"{model_name}.Q4_K_M.gguf"

        token = get_hf_token()
        if not token:
            logging.error("❌ No Hugging Face token provided!")
            return 1

        models_dir = str(Path.home() / "models")
        os.makedirs(models_dir, exist_ok=True)

        print(f"\n📥 Downloading {model_name}")
        print(f"📂 From: {model_path}")
        print(f"📦 File: {filename}")
        print(f"💾 To: {models_dir}")

        file_path = hf_hub_download(
            repo_id=model_path,
            filename=filename,
            local_dir=models_dir,
            local_dir_use_symlinks=False,
            token=token,
            force_download=True
        )

        print(f"\n✅ Download complete!")
        print(f"📍 Model saved to: {file_path}")
        return 0

    except Exception as e:
        print(f"\n❌ Download failed: {str(e)}")
        logging.error(f"Download failed: {str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(download_model())
EOF

# Make download_model.py executable
chmod +x "${INSTALL_DIR}/download_model.py"

# Create symlink for active model
ln -sf "${INSTALL_DIR}/configs/llm_configs/${safe_name}.json" "${INSTALL_DIR}/configs/active_model.json"

echo -e "${GREEN}✅ Setup complete!${NC}"
echo -e "${CYAN}Files created:${NC}"
echo -e "  ${YELLOW}Config: ${INSTALL_DIR}/configs/llm_configs/${safe_name}.json${NC}"
echo -e "  ${YELLOW}Provider: ${BOLT_DIR}/app/lib/modules/llm/providers/${safe_name}-local.ts${NC}"
echo -e "  ${YELLOW}Registry: ${BOLT_DIR}/app/lib/modules/llm/registry.ts${NC}"
echo -e "  ${YELLOW}Environment: ${BOLT_DIR}/.env.local${NC}"
echo -e "  ${YELLOW}Download Script: ${INSTALL_DIR}/download_model.py${NC}"
echo -e "${GREEN}✅ Model config setup complete!${NC}"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
chmod +x "${SCRIPT_DIR}/download_model.py"

echo -e "${GREEN}✅ Model config setup complete!${NC}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
chmod +x "${SCRIPT_DIR}/download_model.py"

echo -e "${GREEN}✅ Model config setup complete!${NC}"
echo -e "${CYAN}Moving to model download...${NC}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
chmod +x "${SCRIPT_DIR}/download_model.py"
exec python3 "${SCRIPT_DIR}/download_model.py"
