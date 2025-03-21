#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🖥️ Setting up LLM server...${NC}"

# Move to server directory
cd ~/llm-server || exit 1

# Create main.py if it doesn't exist
cat > main.py << 'PYEOF'
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
import os

app = FastAPI()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatRequest(BaseModel):
    messages: list
    temperature: float = 0.7
    max_tokens: int = 1000

# Global variables for model and tokenizer
model = None
tokenizer = None

def load_model():
    global model, tokenizer
    model_path = "/home/flintx/models/mistral-7b-v0.1.Q4_K_M.gguf"
    
    if not os.path.exists(model_path):
        raise HTTPException(status_code=500, detail="Model file not found")
    
    try:
        tokenizer = AutoTokenizer.from_pretrained(model_path)
        model = AutoModelForCausalLM.from_pretrained(
            model_path,
            torch_dtype=torch.float16,
            device_map="auto",
            low_cpu_mem_usage=True
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to load model: {str(e)}")

@app.on_event("startup")
async def startup_event():
    load_model()

@app.post("/v1/chat/completions")
async def chat_completion(request: ChatRequest):
    try:
        # Format messages
        prompt = ""
        for msg in request.messages:
            role = msg.get("role", "")
            content = msg.get("content", "")
            prompt += f"{role}: {content}\nassistant: "

        # Generate response
        inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
        outputs = model.generate(
            **inputs,
            max_new_tokens=request.max_tokens,
            temperature=request.temperature,
            do_sample=True
        )
        response = tokenizer.decode(outputs[0], skip_special_tokens=True)

        return {
            "choices": [{
                "message": {
                    "role": "assistant",
                    "content": response.split("assistant: ")[-1]
                }
            }]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
PYEOF

echo -e "${GREEN}✅ Created server files${NC}"

# Hand off to bolt setup
echo -e "${CYAN}Moving to bolt.diy setup...${NC}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
chmod +x "${SCRIPT_DIR}/bolt_setup.sh"
exec "${SCRIPT_DIR}/bolt_setup.sh"
