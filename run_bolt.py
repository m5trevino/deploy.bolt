#!/usr/bin/env python3
import subprocess
import sys
import time
import requests
from pathlib import Path
from rich.console import Console

console = Console()

def check_model_server():
    """Check if model server is running"""
    try:
        response = requests.get("http://localhost:8080/v1/models")
        return response.status_code == 200
    except:
        return False

def setup_bolt_diy():
    """Clone and setup bolt.diy if not present"""
    try:
        deploy_dir = Path.home() / "deploy.bolt"
        bolt_dir = deploy_dir / "bolt.diy"

        if not bolt_dir.exists():
            console.print("[cyan]bolt.diy not found. Setting up...[/cyan]")
            
            # Clone the repo
            subprocess.run([
                "git", "clone",
                "https://github.com/flintx/bolt.diy.git",
                str(bolt_dir)
            ], check=True)
            
            console.print("[green]✓ bolt.diy cloned successfully[/green]")
            return True
            
        return True

    except Exception as e:
        console.print(f"[red]Error setting up bolt.diy: {str(e)}[/red]")
        return False

def main():
    # Check if model server is running
    if not check_model_server():
        console.print("[red][!] Model server ain't running. Start that first.[/red]")
        sys.exit(1)

    # Setup bolt.diy if needed
    if not setup_bolt_diy():
        console.print("[red][!] Failed to setup bolt.diy[/red]")
        sys.exit(1)

    # Check for run_bolt.sh
    bolt_script = Path("~/deploy.bolt/scripts/run_bolt.sh").expanduser()
    
    if not bolt_script.exists():
        console.print(f"[red][!] Can't find run_bolt.sh[/red]")
        sys.exit(1)

    try:
        subprocess.run([str(bolt_script)], check=True)
    except subprocess.CalledProcessError as e:
        console.print(f"[red][!] Failed to run bolt.diy: {e}[/red]")
        sys.exit(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        console.print("\n[yellow]bolt.diy startup terminated by user[/yellow]")
        sys.exit(0)
    except Exception as e:
        console.print(f"\n[red]Critical error: {str(e)}[/red]")
        sys.exit(1)
