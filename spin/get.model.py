#!/usr/bin/env python3
import sys
import os
import json
import time
from pathlib import Path
from huggingface_hub import hf_hub_download
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn
from rich.panel import Panel
from rich.text import Text
from rich import print as rprint
import subprocess

console = Console()

def print_header():
    console.print("\n")
    console.print("""
    ╔══════════════════════════════════════╗
    ║             GET.MODEL                ║"
    ╚══════════════════════════════════════╝
    """, style="cyan", justify="center")

def load_model_config():
    config_path = Path("/home/flintx/deploy.bolt/custom/temp_model_info")
    if not config_path.exists():
        console.print("[red]❌ Model config not found![/red]")
        sys.exit(1)
    
    config = {}
    with open(config_path) as f:
        for line in f:
            key, value = line.strip().split('=', 1)
            config[key] = value
    return config

def download_model(config):
    models_dir = Path("/root/llm/models")
    if not models_dir.exists():
        console.print("[yellow]📂 Creating models directory...[/yellow]")
        os.system(f"sudo mkdir -p {models_dir}")
        os.system(f"sudo chmod 777 {models_dir}")
    
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TaskProgressColumn(),
        console=console
    ) as progress:
        task = progress.add_task("[cyan]Downloading model...", total=100)
        
        try:
            # Create model-specific directory
            model_dir = models_dir / config['MODEL_NAME'].lower()
            os.system(f"sudo mkdir -p {model_dir}")
            os.system(f"sudo chmod 777 {model_dir}")
            
            console.print(f"[yellow]📂 Downloading to: {model_dir}[/yellow]")
            
            # Download GGUF file
            model_path = hf_hub_download(
                repo_id=config['REPO_PATH'],
                filename="model.gguf",  # Most common GGUF filename
                token=config['HF_TOKEN'],
                local_dir=model_dir,
                force_download=True
            )
            
            progress.update(task, completed=100)
            console.print(f"[green]✅ Model downloaded to: {model_path}[/green]")
            
            # Launch spin.bolt.sh in new window
            subprocess.Popen(['xfce4-terminal', '--title=SPIN.BOLT', 
                            '--command=bash /home/flintx/deploy.bolt/spin/spin.bolt.sh'])
            
            return model_path
            
        except Exception as e:
            console.print(f"[red]❌ Error downloading model: {str(e)}[/red]")
            sys.exit(1)

def main():
    print_header()
    console.print("[cyan]🔍 Loading configuration...[/cyan]")
    config = load_model_config()
    
    console.print(f"[yellow]📦 Model: {config['MODEL_NAME']}[/yellow]")
    console.print(f"[yellow]🔗 Repo: {config['REPO_PATH']}[/yellow]")
    
    model_path = download_model(config)
    
    # Start model server
    console.print("[cyan]🚀 Starting model server...[/cyan]")
    server_cmd = f"python -m llama_cpp.server --model {model_path} --host 0.0.0.0 --port 8000"
    subprocess.Popen(server_cmd.split())
    
    console.print("[green]✨ Model server started on port 8000[/green]")
    
    # Give the server a moment to start
    time.sleep(3)
    
    # Launch monitor in new terminal
    console.print("[cyan]📊 Starting monitor...[/cyan]")
    subprocess.Popen(['xfce4-terminal', '--title=MONITOR', 
                     '--command=bash /home/flintx/deploy.bolt/spin/monitor.sh'])

if __name__ == "__main__":
    main()
