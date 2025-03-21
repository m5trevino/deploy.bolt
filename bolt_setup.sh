#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔧 Setting up bolt.diy...${NC}"

# Move to bolt.diy directory
cd ~/bolt.diy || exit 1

# Create provider file
mkdir -p app/lib/modules/llm/providers
cat > app/lib/modules/llm/providers/mistral-7b-v0.1-gguf-local.ts << 'TSEOF'
import { BaseProvider, getOpenAILikeModel } from '../base-provider';
import type { ModelInfo } from '../types';
import type { IProviderSetting } from '~/types/model';
import type { LanguageModelV1 } from 'ai';
import { logger } from '~/utils/logger';

export default class TheBlokeProvider extends BaseProvider {
    name = 'TheBloke';
    displayName = 'Mistral';
    getApiKeyLink = 'http://localhost:8000';
    labelForGetApiKey = 'Local Server';
    icon = 'i-carbon-machine-learning-model';
    requiresApiKey = false;
    config = {
        baseUrlKey: 'THEBLOKE_API_BASE_URL',
        apiTokenKey: 'THEBLOKE_API_KEY',
        baseUrl: 'http://localhost:8000',
        modelPath: 'TheBloke/Mistral-7B-v0.1-GGUF',
        quantization: '4-bit'
    };
    staticModels: ModelInfo[] = [
        { 
            name: 'mistral-7b-v0.1-gguf', 
            label: 'Mistral', 
            provider: 'TheBloke', 
            maxTokenAllowed: 8192,
            contextWindow: 8192,
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
        
        logger.debug('TheBloke Provider:', { 
            baseUrl: finalBaseUrl, 
            model,
            modelPath: this.config.modelPath,
            quantization: this.config.quantization
        });
        return getOpenAILikeModel(finalBaseUrl, finalApiKey, model);
    }
}
TSEOF

# Update registry
cat > app/lib/modules/llm/registry.ts << 'TSEOF'
import TheBlokeLocalProvider from './providers/mistral-7b-v0.1-gguf-local';

export {
    TheBlokeLocalProvider,
};
TSEOF

echo -e "${GREEN}✅ Created provider files${NC}"

# Build bolt.diy
echo -e "${CYAN}Building bolt.diy...${NC}"
pnpm build

# Hand off to configure script
echo -e "${CYAN}Moving to final configuration...${NC}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
chmod +x "${SCRIPT_DIR}/configure.sh"
exec "${SCRIPT_DIR}/configure.sh"
