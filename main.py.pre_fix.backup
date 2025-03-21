import time
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import json
import os
from llama_cpp import Llama

app = FastAPI()

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    model: str
    max_tokens: Optional[int] = 1000
    temperature: Optional[float] = 0.7
    stream: Optional[bool] = False

def load_active_model():
    config_path = os.path.join(os.path.dirname(__file__), "configs", "active_model.json")
    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
        return config
    except Exception as e:
        print(f"Error loading model config: {e}")
        return None

@app.post("/v1/chat/completions")
async def chat_completion(request: ChatRequest):
    try:
        config = load_active_model()
        if not config:
            raise HTTPException(status_code=500, detail="No active model configured")

        model_path = os.path.expanduser(f"~/models/{config['settings']['model_path'].split('/')[-1]}.Q4_K_M.gguf")
        
        if not os.path.exists(model_path):
            raise HTTPException(status_code=404, detail=f"Model file not found: {model_path}")

        llm = Llama(
            model_path=model_path,
            n_ctx=config['max_tokens'],
            n_threads=os.cpu_count(),
        )

        # Format messages into prompt
        prompt = ""
        for msg in request.messages:
            if msg.role == "system":
                prompt += f"System: {msg.content}\n"
            elif msg.role == "user":
                prompt += f"User: {msg.content}\n"
            elif msg.role == "assistant":
                prompt += f"Assistant: {msg.content}\n"
        prompt += "Assistant: "

        # Generate response
        output = llm(
            prompt,
            max_tokens=request.max_tokens,
            temperature=request.temperature,
            stop=["User:", "System:"],
            echo=False
        )

        return {
            "id": "chatcmpl-" + os.urandom(12).hex(),
            "object": "chat.completion",
            "created": int(time.time()),
            "model": request.model,
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": output['choices'][0]['text'].strip()
                },
                "finish_reason": "stop"
            }],
            "usage": {
                "prompt_tokens": output['usage']['prompt_tokens'],
                "completion_tokens": output['usage']['completion_tokens'],
                "total_tokens": output['usage']['total_tokens']
            }
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
def health_check():
    return {"status": "ok"}
