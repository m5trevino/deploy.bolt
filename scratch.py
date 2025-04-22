import os
import subprocess
import sys
import time
from rich import print
from rich.console import Console
from rich.panel import Panel
from rich.spinner import Spinner

console = Console()

def run_command(command, shell=True):
    try:
        subprocess.run(command, shell=shell, check=True)
        return True
    except subprocess.CalledProcessError:
        return False

def check_node_installation():
    try:
        # Check if Node.js is installed
        node_version = subprocess.check_output(['node', '--version'], stderr=subprocess.STDOUT).decode().strip()
        print(f"[green]Node.js {node_version} is installed[/green]")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

def check_pnpm_installation():
    try:
        # Check if pnpm is installed
        pnpm_version = subprocess.check_output(['pnpm', '--version'], stderr=subprocess.STDOUT).decode().strip()
        print(f"[green]pnpm {pnpm_version} is installed[/green]")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

def setup_environment():
    print("[bold green]Setting up environment...[/bold green]")

    with console.status("[bold yellow]Checking Node.js installation...", spinner="dots"):
        if not check_node_installation():
            print("[yellow]Installing Node.js...[/yellow]")
            if not run_command("curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"):
                print("[bold red]Failed to add Node.js repository[/bold red]")
                return False
            if not run_command("sudo apt-get install -y nodejs"):
                print("[bold red]Failed to install Node.js[/bold red]")
                return False

        # Verify Node.js installation
        if not check_node_installation():
            print("[bold red]Node.js installation verification failed[/bold red]")
            return False

    with console.status("[bold yellow]Checking pnpm installation...", spinner="dots"):
        if not check_pnpm_installation():
            print("[yellow]Installing pnpm...[/yellow]")
            if not run_command("sudo npm install -g pnpm"):
                print("[bold red]Failed to install pnpm[/bold red]")
                return False

        # Verify pnpm installation
        if not check_pnpm_installation():
            print("[bold red]pnpm installation verification failed[/bold red]")
            return False

    # Final verification
    print("[bold green]✓ Node.js is properly installed[/bold green]")
    print("[bold green]✓ pnpm is properly installed[/bold green]")
    print("[bold green]Environment setup complete![/bold green]")
    return True

def main():
    console.print(Panel.fit("Starting from scratch...", style="bold magenta"))

    if not setup_environment():
        print("[bold red]Setup failed![/bold red]")
        sys.exit(1)

    # Success animation
    with console.status("[bold green]Finalizing setup...", spinner="dots") as status:
        time.sleep(2)
        print("[bold green]Environment setup complete! Launching tokens.py...[/bold green]")

    # Hand off to tokens.py
    time.sleep(1)
    subprocess.run([sys.executable, "tokens.py"])

if __name__ == "__main__":
    main()