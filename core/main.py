from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
from pydantic import BaseModel
from typing import List, Optional, Union, Dict
from llama_cpp import Llama
import torch
from datetime import datetime
import logging
import uuid
import json
import os
from monitor import SystemMonitor

# Initialize FastAPI app and monitor
app = FastAPI()
monitor = SystemMonitor()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Load model config
try:
    with open('/home/flintx/deploy.bolt/src/configs/active_model.json', 'r') as f:
        model_config = json.load(f)
        MODEL_PATH = model_config['settings']['model_path']
        MODEL_DISPLAY_NAME = model_config['display_name']
except Exception as e:
    raise Exception(f"Failed to load model config: {str(e)}")

DEFAULT_MAX_TOKENS = int(os.getenv("DEFAULT_MAX_TOKENS", model_config.get('max_tokens', 1024)))
DEFAULT_TEMPERATURE = float(os.getenv("DEFAULT_TEMPERATURE", model_config['settings'].get('temperature', 0.7)))
DEFAULT_TOP_P = float(os.getenv("DEFAULT_TOP_P", model_config['settings'].get('top_p', 0.95)))

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatCompletionRequest(BaseModel):
    model: str
    messages: List[ChatMessage]
    temperature: float = DEFAULT_TEMPERATURE
    top_p: float = DEFAULT_TOP_P
    max_tokens: int = DEFAULT_MAX_TOKENS
    stream: bool = False

# Load the model
try:
    monitor.update_model_info({
        "name": MODEL_DISPLAY_NAME,
        "status": "🔄 Loading Model...",
        "config": {
            "quantization": model_config['settings'].get('quantization', '4-bit'),
            "context_length": str(model_config['settings'].get('context_window', 4096)),
            "last_loaded": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
    })
    monitor.start()

    if torch.cuda.is_available():
        torch.cuda.empty_cache()
        torch.cuda.reset_peak_memory_stats()
        torch.cuda.synchronize()

    # Initialize Llama model with CUDA
    llm = Llama(
        model_path=MODEL_PATH,
        n_ctx=model_config['settings'].get('context_window', 4096),
        n_gpu_layers=-1,  # Use all layers on GPU
        seed=42,
        n_threads=os.cpu_count(),
        use_mlock=True
    )

    # Update monitor with loaded model info
    gpus = GPUtil.getGPUs()
    monitor.update_model_info({
        "status": "✅ Model Ready",
        "memory_used": f"{torch.cuda.max_memory_allocated()//1024//1024} MiB",
        "cuda_devices": [
            {
                "name": gpu.name,
                "memory_used": gpu.memoryUsed,
                "memory_total": gpu.memoryTotal
            } for gpu in gpus
        ]
    })

except Exception as e:
    monitor.update_model_info({
        "status": f"❌ Error: {str(e)}",
    })
    raise

def format_prompt(messages: List[ChatMessage]) -> str:
    prompt = ""
    for msg in messages:
        if msg.role == "system":
            prompt += f"<|system|>\n{msg.content}\n"
        elif msg.role == "user":
            prompt += f"<|user|>\n{msg.content}\n"
        elif msg.role == "assistant":
            prompt += f"<|assistant|>\n{msg.content}\n"
    prompt += "<|assistant|>\n"
    return prompt

@app.post("/v1/chat/completions")
async def chat_completion(request: ChatCompletionRequest):
    try:
        monitor.update_model_info({"status": "🔄 Processing Request..."})

        prompt = format_prompt(request.messages)
        
        # Generate response using llama-cpp
        output = llm(
            prompt,
            max_tokens=request.max_tokens,
            temperature=request.temperature,
            top_p=request.top_p,
            echo=False
        )

        response_text = output['choices'][0]['text']

        # Update monitor stats after generation
        gpus = GPUtil.getGPUs()
        monitor.update_model_info({
            "status": "✅ Model Ready",
            "memory_used": f"{torch.cuda.max_memory_allocated()//1024//1024} MiB",
            "cuda_devices": [
                {
                    "name": gpu.name,
                    "memory_used": gpu.memoryUsed,
                    "memory_total": gpu.memoryTotal
                } for gpu in gpus
            ]
        })

        return {
            "id": f"chatcmpl-{str(uuid.uuid4())[:8]}",
            "object": "chat.completion",
            "created": int(datetime.now().timestamp()),
            "model": request.model,
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": response_text.strip()
                },
                "finish_reason": "stop"
            }],
            "usage": {
                "prompt_tokens": len(prompt.split()),  # Approximate
                "completion_tokens": len(response_text.split()),  # Approximate
                "total_tokens": len(prompt.split()) + len(response_text.split())  # Approximate
            }
        }

    except Exception as e:
        monitor.update_model_info({"status": f"❌ Error: {str(e)}"})
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "model": MODEL_PATH,
        "cuda_available": torch.cuda.is_available(),
        "cuda_device": torch.cuda.get_device_name(0) if torch.cuda.is_available() else None
    }

if __name__ == "__main__":
    import uvicorn
    try:
        uvicorn.run(app, host="0.0.0.0", port=8000)
    finally:
        monitor.stop()
