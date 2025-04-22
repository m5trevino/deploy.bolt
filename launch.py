#!/usr/bin/env python3

import sys
import subprocess
from pathlib import Path
from rich import print as rprint
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn

BOLT_BANNER = """
[bright_magenta]╔══════════════════════════════════════════════════════╗
║[/][bright_cyan]                   DEPLOY.BOLT v1.0                   [/][bright_magenta]║
║[/][bright_cyan]          Neural Network Deployment System            [/][bright_magenta]║
╚══════════════════════════════════════════════════════╝[/]
"""

INIT_BANNER = """
[bright_magenta]╔══════════════════════════════════════════════════════╗
║[/][bright_cyan]            INITIALIZING NEURAL MATRIX               [/][bright_magenta]║
║[/][bright_cyan]         Press Enter to Access the System           [/][bright_magenta]║
╚══════════════════════════════════════════════════════╝[/]
"""

def handoff_to_scratch():
    """Hand off to scratch.py for bolt.diy installation"""
    scratch_path = Path.home() / "deploy.bolt" / "scratch.py"
    try:
        subprocess.run([sys.executable, str(scratch_path)], check=True)
    except subprocess.CalledProcessError:
        rprint("[bright_red]ERROR: Failed to launch scratch.py![/]")
        sys.exit(1)
    except FileNotFoundError:
        rprint("[bright_red]ERROR: scratch.py not found![/]")
        sys.exit(1)

def main():
    # Print main banner
    rprint(BOLT_BANNER)

    # Show initialization banner and wait for user
    rprint(INIT_BANNER)

    # Fancy loading animation
    with Progress(
        SpinnerColumn(),
        TextColumn("[bright_magenta]Accessing Neural Network Systems...[/]"),
        transient=True
    ) as progress:
        progress.add_task("", total=None)
        input()  # Wait for user to press Enter

    rprint("\n[bright_cyan]Neural link established. Initializing deployment sequence...[/]")
    handoff_to_scratch()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        rprint("\n[bright_yellow]Neural link terminated by user...[/]")
        sys.exit(0)
    except Exception as e:
        rprint(f"[bright_red]Critical error: {str(e)}[/]")
        sys.exit(1)