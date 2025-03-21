#!/bin/bash

# ===== STEP 1: FIX SECRET HISTORY =====
echo "🧹 Cleaning Git history of Hugging Face token..."
git filter-repo --path .env --invert-paths --force
git rm .env
git commit -m "Removed .env from repository"
git push -f origin main

# ===== STEP 2: UPDATE bolt_custom.sh =====
echo "🔧 Updating bolt_custom.sh..."
cat > bolt_custom.sh << 'EOF'
#!/bin/bash
# [PASTE THE ENTIRE bolt_custom.sh content from your uploaded files here]
EOF
chmod +x bolt_custom.sh

# ===== STEP 3: FIX VRAM CHECK =====
echo "🛡 Adding VRAM check to bolt_custom.sh..."
sed -i '/read -p "Enter model path"/a \\
read -p "Enter required VRAM (GB): " vram_required \\
nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | read VRAM_GB \\
if (( $(echo "$VRAM_GB < $vram_required" | bc -l) )); then \\
    echo "❌ Your GPU has ${VRAM_GB}GB VRAM. This model requires ${vram_required}GB." \\
    exit 1 \\
fi' bolt_custom.sh

# ===== STEP 4: SETUP CHAIN FIX =====
echo "🔗 Fixing setup script chain..."
cat > setup_environment.sh << 'EOF'
#!/bin/bash
./python_setup.sh && \\
./setup_configs.sh && \\
./server_setup.sh && \\
./bolt_setup.sh && \\
./configure.sh && \\
./expose.sh && \\
./launch_bolt.sh
EOF
chmod +x setup_environment.sh

# ===== STEP 5: SECURE download_model.py =====
echo "🔒 Securing download_model.py..."
cat > download_model.py << 'EOF'
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
    token = os.getenv('HUGGINGFACE_TOKEN')
    if not token:
        token = input("Enter Hugging Face token: ")
    return token

def download_model():
    try:
        config_path = "configs/active_model.json"
        with open(config_path, 'r') as f:
            config = json.load(f)
        model_path = config['settings']['model_path']
        filename = config['name'] + ".gguf"
        token = get_hf_token()
        models_dir = str(Path.home() / "models")
        os.makedirs(models_dir, exist_ok=True)
        hf_hub_download(
            repo_id=model_path,
            filename=filename,
            local_dir=models_dir,
            token=token
        )
        print(f"✅ Model saved to {models_dir}/{filename}")
    except Exception as e:
        logging.error(f"Download failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    download_model()
EOF
chmod +x download_model.py

# ===== STEP 6: FINAL PERMISSIONS =====
echo "🔑 Setting proper permissions..."
chmod +x *.sh
chmod 600 configs/*.json
chmod 755 -R models/ providers/

echo "✅ All fixes applied! To start your server:"
echo "1. Run: ./setup_environment.sh"
echo "2. When prompted, select your GPU model"
echo "3. The server will auto-launch after setup completes"