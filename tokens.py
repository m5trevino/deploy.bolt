#!/usr/bin/env python3

import os
import sys
import time
import subprocess
from pathlib import Path
from rich import print as rprint
from rich.console import Console
from rich.prompt import Prompt
from rich.panel import Panel

console = Console()

def setup_token_directory():
    """Ensure token directory exists"""
    token_dir = Path.home() / "deploy.bolt" / "tokens"
    token_dir.mkdir(parents=True, exist_ok=True)
    return token_dir

def mask_token(token):
    """Mask middle part of token"""
    if len(token) <= 6:
        return token
    return f"{token[:3]}{'*' * (len(token)-6)}{token[-3:]}"

def list_tokens(token_dir, token_type):
    """List existing tokens with numbers"""
    token_file = token_dir / f"{token_type}_token"
    tokens = []

    if token_file.exists():
        with open(token_file, 'r') as f:
            for line in f:
                token = line.strip()
                if token:
                    tokens.append(token)

    if tokens:
        rprint(f"\n[bright_cyan]Existing {token_type.upper()} Tokens:[/]")
        for idx, token in enumerate(tokens, 1):
            rprint(f"[bright_green]#{idx}[/] {mask_token(token)}")

    rprint(f"[bright_yellow]#{len(tokens) + 1}[/] Enter new token")
    return tokens

def launch_huggingface(tokens):
    """Launch huggingface.py in a new Terminator window and close current window"""
    try:
        # Save current tokens to temporary files for huggingface.py
        token_dir = Path.home() / "deploy.bolt" / "tokens"
        deploy_bolt_dir = str(Path.home() / "deploy.bolt")

        # Save selected tokens to their respective files
        with open(token_dir / "current_ngrok_token", 'w') as f:
            f.write(tokens["ngrok"])
        with open(token_dir / "current_hf_token", 'w') as f:
            f.write(tokens["hf"])

        # Create a shell script to launch huggingface.py
        script_path = deploy_bolt_dir + "/launch_hf.sh"
        with open(script_path, 'w') as f:
            f.write(f'''#!/bin/bash
cd {deploy_bolt_dir}
echo "Starting HuggingFace interface..."
python3 huggingface.py
read -p "Press Enter to continue..."
''')

        # Make the script executable
        os.chmod(script_path, 0o755)

        # Launch terminator with the script
        subprocess.run([
            'terminator',
            '-e', f'bash {script_path}'
        ])

        # Exit current process
        sys.exit(0)

    except Exception as e:
        rprint(f"[red]Error launching HuggingFace interface: {str(e)}[/red]")
        return False

def collect_tokens():
    """Collect and save API tokens"""
    token_dir = Path.home() / "deploy.bolt" / "tokens"
    token_dir.mkdir(parents=True, exist_ok=True)

    console.print(Panel.fit("Token Collection Interface", style="bright_magenta"))

    # Handle NGROK token
    rprint("\n[bright_magenta]== NGROK Token Selection ==[/]")
    ngrok_tokens = list_tokens(token_dir, "ngrok")

    choice = Prompt.ask(
        "\n[bright_magenta]Select token by number[/]",
        choices=[str(i) for i in range(1, len(ngrok_tokens) + 2)]
    )

    if int(choice) == len(ngrok_tokens) + 1:
        ngrok_token = Prompt.ask("[bright_cyan]Enter new NGROK token[/]")
        with open(token_dir / "ngrok_token", 'a') as f:
            f.write(f"{ngrok_token}\n")
        rprint("[bright_green]* New NGROK token saved![/]")
    else:
        ngrok_token = ngrok_tokens[int(choice) - 1]
        rprint(f"[bright_green]* Selected NGROK token: {mask_token(ngrok_token)}[/]")

    # Handle HuggingFace token
    rprint("\n[bright_magenta]== HuggingFace Token Selection ==[/]")
    hf_tokens = list_tokens(token_dir, "hf")

    choice = Prompt.ask(
        "\n[bright_magenta]Select token by number[/]",
        choices=[str(i) for i in range(1, len(hf_tokens) + 2)]
    )

    if int(choice) == len(hf_tokens) + 1:
        hf_token = Prompt.ask("[bright_cyan]Enter new HuggingFace token[/]")
        with open(token_dir / "hf_token", 'a') as f:
            f.write(f"{hf_token}\n")
        rprint("[bright_green]* New HuggingFace token saved![/]")
    else:
        hf_token = hf_tokens[int(choice) - 1]
        rprint(f"[bright_green]* Selected HuggingFace token: {mask_token(hf_token)}[/]")

    return {"ngrok": ngrok_token, "hf": hf_token}

def main():
    """Main function to handle token collection and handoff"""
    bolt_path = Path.home() / "deploy.bolt"

    if not bolt_path.exists():
        rprint("[red]Error: deploy.bolt directory not found![/red]")
        sys.exit(1)

    # Set up directory structure
    setup_token_directory()

    # Collect tokens
    tokens = collect_tokens()
    if tokens:
        rprint("\n[bright_green]✓ Tokens collected successfully![/bright_green]")

        # Launch huggingface.py in new terminal and close this one
        if launch_huggingface(tokens):
            rprint("[bright_green]✓ Launching HuggingFace interface in new terminal...[/bright_green]")
            sys.exit(0)
        else:
            rprint("[red]Failed to launch HuggingFace interface[/red]")
            sys.exit(1)
    else:
        rprint("[red]Token collection failed. Try again.[/red]")
        sys.exit(1)

if __name__ == "__main__":
    main()
