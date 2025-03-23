#!/usr/bin/env python3
from rich.console import Console
from rich.prompt import Prompt
import subprocess
import random
from pathlib import Path
import time

console = Console()

def get_random_ascii():
    ascii_file = Path("/home/flintx/deploy.bolt/ascii/run.ascii.txt")
    if not ascii_file.exists():
        return None
    
    with open(ascii_file) as f:
        ascii_arts = f.read().split('\n\n\n')
    ascii_arts = [art.strip() for art in ascii_arts if art.strip()]
    return random.choice(ascii_arts)

def print_header():
    console.print("\n")
    ascii_art = get_random_ascii()
    if ascii_art:
        console.print(f"[cyan]{ascii_art}[/cyan]", justify="center")
    
    console.print("""
    ╔══════════════════════════════════════╗
    ║           BOLT LAUNCHER              ║
    ╚══════════════════════════════════════╝
    """, style="magenta", justify="center")

def fresh_install():
    """Fresh install flow"""
    scripts = [
        ("scratch/install_bolt.sh", "INSTALL"),
        ("scratch/dependencies.sh", "DEPENDENCIES"),
        ("custom/input_info.sh", "INPUT INFO"),
        ("custom/create_custom.sh", "CREATE CUSTOM"),
        ("custom/verify_custom.sh", "VERIFY"),
        ("spin/get.model.py", "GET MODEL"),
        ("spin/spin.bolt.sh", "SPIN BOLT"),
        ("spin/expose.bolt.sh", "EXPOSE"),
        ("spin/monitor.sh", "MONITOR")
    ]
    
    for script, title in scripts:
        console.print(f"\n[cyan]Launching {title}...[/cyan]")
        time.sleep(1)
        subprocess.run(['xfce4-terminal', f'--title={title}', 
                       f'--command=bash /home/flintx/deploy.bolt/{script}'])

def add_new_llm():
    """Add new LLM flow"""
    scripts = [
        ("custom/input_info.sh", "INPUT INFO"),
        ("custom/create_custom.sh", "CREATE CUSTOM"),
        ("custom/verify_custom.sh", "VERIFY"),
        ("spin/get.model.py", "GET MODEL"),
        ("spin/spin.bolt.sh", "SPIN BOLT"),
        ("spin/expose.bolt.sh", "EXPOSE"),
        ("spin/monitor.sh", "MONITOR")
    ]
    
    for script, title in scripts:
        console.print(f"\n[cyan]Launching {title}...[/cyan]")
        time.sleep(1)
        subprocess.run(['xfce4-terminal', f'--title={title}', 
                       f'--command=bash /home/flintx/deploy.bolt/{script}'])

def use_existing():
    """Use existing setup flow"""
    subprocess.run(['xfce4-terminal', '--title=SPIN EXISTING', 
                   '--command=python3 /home/flintx/deploy.bolt/spin.exist.py'])

def main():
    print_header()
    
    options = [
        "[cyan]1.[/cyan] [green]Fresh Install[/green] (Full setup from scratch)",
        "[cyan]2.[/cyan] [yellow]Add New LLM[/yellow] (To existing setup)",
        "[cyan]3.[/cyan] [magenta]Use Existing Setup[/magenta] (Launch saved model)"
    ]
    
    console.print("\n[cyan]Choose your path:[/cyan]")
    for opt in options:
        console.print(opt)
    
    choice = Prompt.ask("\n[cyan]Enter your choice[/cyan]", choices=["1", "2", "3"])
    
    if choice == "1":
        fresh_install()
    elif choice == "2":
        add_new_llm()
    elif choice == "3":
        use_existing()

if __name__ == "__main__":
    main()
