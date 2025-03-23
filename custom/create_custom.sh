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
    echo "    ║          CREATE CUSTOM               ║"
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

# Load model info
source /home/flintx/deploy.bolt/custom/temp_model_info

# Convert model name to lowercase for file naming
MODEL_NAME_LOWER=$(echo "$MODEL_NAME" | tr '[:upper:]' '[:lower:]')

# Main execution
print_header

# Create provider file
echo -e "${CYAN}[+] Creating provider file...${RESET}"
mkdir -p /home/flintx/bolt.diy/app/lib/modules/llm/providers
cat << 'PROVIDER_EOF' > "/home/flintx/bolt.diy/app/lib/modules/llm/providers/${MODEL_NAME_LOWER}-local.ts"
import { ChatMessage, LLMProvider } from '../types';

export class ${MODEL_NAME}LocalProvider implements LLMProvider {
  constructor() {}

  async chat(messages: ChatMessage[], options?: any): Promise<string> {
    try {
      const response = await fetch('http://localhost:8000/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          messages: messages.map(msg => ({
            role: msg.role,
            content: msg.content,
          })),
          model: '${MODEL_NAME_LOWER}',
          stream: false,
        }),
      });

      if (!response.ok) {
        throw new Error('API request failed');
      }

      const data = await response.json();
      return data.choices[0].message.content;
    } catch (error) {
      console.error('Error in ${MODEL_NAME}LocalProvider:', error);
      throw error;
    }
  }
}
PROVIDER_EOF
check_step "Creating provider file"

# Create API file
echo -e "${CYAN}[+] Creating API file...${RESET}"
mkdir -p /home/flintx/bolt.diy/api
cat << 'API_EOF' > "/home/flintx/bolt.diy/api/${MODEL_NAME_LOWER}.py"
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import httpx
import json

app = FastAPI()

class Message(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[Message]
    model: str
    stream: Optional[bool] = False

class ChatResponse(BaseModel):
    choices: List[dict]

@app.post("/v1/chat/completions")
async def chat_completion(request: ChatRequest):
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "http://localhost:8000/v1/chat/completions",
                json={
                    "messages": [{"role": m.role, "content": m.content} for m in request.messages],
                    "model": "${MODEL_NAME_LOWER}",
                    "stream": request.stream
                }
            )
            
            if response.status_code != 200:
                raise HTTPException(status_code=response.status_code, detail="Model API error")
            
            return response.json()
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)
API_EOF
check_step "Creating API file"

# Update registry
echo -e "${CYAN}[+] Updating registry...${RESET}"
cat << 'REGISTRY_EOF' > /home/flintx/bolt.diy/app/lib/modules/llm/registry.ts
import { LLMProvider } from './types';
import { ${MODEL_NAME}LocalProvider } from './providers/${MODEL_NAME_LOWER}-local';

export const providers: { [key: string]: () => LLMProvider } = {
  '${MODEL_NAME_LOWER}-local': () => new ${MODEL_NAME}LocalProvider(),
};
REGISTRY_EOF
check_step "Updating registry"

# Create .env.local
echo -e "${CYAN}[+] Creating .env.local...${RESET}"
cat << 'ENV_EOF' > /home/flintx/bolt.diy/.env.local
NEXT_PUBLIC_DEFAULT_MODEL=${MODEL_NAME_LOWER}-local
ENV_EOF
check_step "Creating .env.local"

# Update vite.config
echo -e "${CYAN}[+] Updating vite.config...${RESET}"
cat << 'VITE_EOF' > /home/flintx/bolt.diy/vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
  },
});
VITE_EOF
check_step "Updating vite.config"

echo -e "\n${GREEN}[✓] All files created successfully!${RESET}"
echo -e "${CYAN}[+] Handing off to verify_custom.sh...${RESET}"

bash /home/flintx/deploy.bolt/custom/verify_custom.sh
