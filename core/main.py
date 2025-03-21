#!/usr/bin/env python3
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

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

def load_config():
    try:
        with open('/home/flintx/deploy.bolt/src/configs/active_model.json', 'r') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Error loading config: {e}")
        raise

config = load_config()
MODEL_PATH = config["settings"]["model_path"]
DEFAULT_MAX_TOKENS = int(os.getenv("DEFAULT_MAX_TOKENS", 2048))
DEFAULT_TEMPERATURE = float(os.getenv("DEFAULT_TEMPERATURE", 0.7))
DEFAULT_TOP_P = float(os.getenv("DEFAULT_TOP_P", 0.95))

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
    if torch.cuda.is_available():
        logger.info("CUDA available, clearing cache...")
        torch.cuda.empty_cache()
    
    logger.info(f"Loading model from {MODEL_PATH}...")
    model = Llama(
        model_path=MODEL_PATH,
        n_gpu_layers=-1,  # Use all GPU layers
        n_ctx=4096,       # Context window
        n_batch=512       # Batch size
    )
    logger.info("Model loaded successfully!")
except Exception as e:
    logger.error(f"Error loading model: {e}")
    raise

def format_prompt(messages: List[ChatMessage]) -> str:
    """Format the conversation history."""
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
        prompt = format_prompt(request.messages)
        
        completion = model.create_completion(
            prompt=prompt,
            max_tokens=request.max_tokens,
            temperature=request.temperature,
            top_p=request.top_p,
            stream=request.stream
        )
        
        if request.stream:
            async def generate():
                for chunk in completion:
                    yield f"data: {json.dumps(chunk)}\n\n"
                yield "data: [DONE]\n\n"
            
            return StreamingResponse(
                generate(),
                media_type="text/event-stream"
            )
        
        response = {
            "id": f"chatcmpl-{str(uuid.uuid4())[:8]}",
            "object": "chat.completion",
            "created": int(datetime.now().timestamp()),
            "model": request.model,
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": completion["choices"][0]["text"].strip()
                },
                "finish_reason": "stop"
            }],
            "usage": completion.get("usage", {
                "prompt_tokens": 0,
                "completion_tokens": 0,
                "total_tokens": 0
            })
        }
        
        return JSONResponse(content=response)

    except Exception as e:
        logger.error(f"Error in chat completion: {e}")
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
    logger.info(f"Starting server with model {MODEL_PATH}")
    logger.info(f"CUDA available: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        logger.info(f"CUDA device: {torch.cuda.get_device_name(0)}")
    uvicorn.run(app, host="0.0.0.0", port=8000)
