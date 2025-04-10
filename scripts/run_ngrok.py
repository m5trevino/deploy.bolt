#!/usr/bin/env python3

# START ### IMPORTS ###
import os
import sys
import json
import time
import requests
import subprocess
from pathlib import Path
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
# FINISH ### IMPORTS ###

# START ### CONSOLE SETUP ###
console = Console()
# FINISH ### CONSOLE SETUP ###

# START ### TOKEN HANDLER ###
def get_ngrok_token():
    """Get ngrok token from file"""
    token_path = Path.home() / "deploy.bolt" / "tokens" / "current_ngrok_token"
    if not token_path.exists():
        console.print("[red]Ngrok token not found![/red]")
        return None
    
    with open(token_path) as f:
        return f.read().strip()
# FINISH ### TOKEN HANDLER ###

# START ### NGROK MANAGER ###
def setup_ngrok():
    """Configure ngrok with token"""
    token = get_ngrok_token()
    if not token:
        return False
    
    try:
        subprocess.run(["ngrok", "config", "add-authtoken", token], check=True)
        return True
    except subprocess.CalledProcessError as e:
        console.print(f"[red]Error configuring ngrok: {str(e)}[/red]")
        return False

def start_ngrok_tunnel():
    """Start ngrok tunnel"""
    try:
        process = subprocess.Popen(
            ["ngrok", "http", "8080", "--log=stdout"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True
        )
        return process
    except Exception as e:
        console.print(f"[red]Error starting ngrok: {str(e)}[/red]")
        return None

def get_ngrok_url():
    """Get public URL from ngrok API"""
    try:
        response = requests.get("http://localhost:4040/api/tunnels")
        data = response.json()
        return data["tunnels"][0]["public_url"]
    except:
        return None
# FINISH ### NGROK MANAGER ###

# START ### URL MONITOR ###
def monitor_tunnel():
    """Monitor ngrok tunnel and display URL"""
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        transient=True,
    ) as progress:
        task = progress.add_task("[cyan]Waiting for ngrok tunnel...", total=None)
        
        while True:
            url = get_ngrok_url()
            if url:
                progress.update(task, description=f"[green]Tunnel active: {url}")
            else:
                progress.update(task, description="[yellow]Waiting for tunnel...")
            time.sleep(2)
# FINISH ### URL MONITOR ###

# START ### MAIN FUNCTION ###
def main():
    console.print(Panel.fit(
        "[cyan]NGROK TUNNEL MANAGER[/cyan]\n"
        "[yellow]Creating secure access to your deployment[/yellow]",
        border_style="cyan"
    ))
    
    # Setup ngrok
    console.print("\n[cyan]Setting up ngrok...[/cyan]")
    if not setup_ngrok():
        console.print("[red]Failed to configure ngrok![/red]")
        sys.exit(1)
    
    # Start tunnel
    console.print("\n[cyan]Starting ngrok tunnel...[/cyan]")
    process = start_ngrok_tunnel()
    if not process:
        console.print("[red]Failed to start ngrok tunnel![/red]")
        sys.exit(1)
    
    # Monitor tunnel
    try:
        monitor_tunnel()
    except KeyboardInterrupt:
        process.terminate()
        console.print("\n[yellow]Ngrok tunnel terminated by user[/yellow]")
# FINISH ### MAIN FUNCTION ###

# START ### SCRIPT RUNNER ###
if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        console.print(f"\n[red]Critical error: {str(e)}[/red]")
        sys.exit(1)
# FINISH ### SCRIPT RUNNER ###