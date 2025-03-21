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
