#!/usr/bin/env python3

# START ### IMPORTS ###
import os
import sys
import json
import time
import requests
from pathlib import Path
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
# FINISH ### IMPORTS ###

# START ### CONSOLE SETUP ###
console = Console()
# FINISH ### CONSOLE SETUP ###

# START ### VALIDATION TESTS ###
def test_server_health():
    """Test server health endpoint"""
    try:
        response = requests.get("http://0.0.0.0:8080/health")
        return response.status_code == 200
    except:
        return False

def test_model_list():
    """Test models endpoint"""
    try:
        response = requests.get("http://0.0.0.0:8080/v1/models")
        return response.status_code == 200 and len(response.json()["data"]) > 0
    except:
        return False

def test_completion():
    """Test completion endpoint"""
    try:
        data = {
            "messages": [
                {"role": "user", "content": "Say 'test successful' if you can read this."}
            ],
            "temperature": 0.7,
            "max_tokens": 32
        }
        response = requests.post("http://0.0.0.0:8080/v1/chat/completions", json=data)
        return response.status_code == 200 and "test successful" in response.json()["choices"][0]["message"]["content"].lower()
    except:
        return False
# FINISH ### VALIDATION TESTS ###

# START ### VALIDATION RUNNER ###
def run_validation_tests():
    """Run all validation tests"""
    tests = [
        ("Server Health", test_server_health),
        ("Model List", test_model_list),
        ("Completion", test_completion)
    ]
    
    results = []
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        transient=True,
    ) as progress:
        for name, test_func in tests:
            task = progress.add_task(f"[cyan]Testing {name}...", total=None)
            result = test_func()
            status = "[green]âœ“" if result else "[red]Ã—"
            progress.update(task, description=f"{status} {name}")
            results.append(result)
            time.sleep(1)
    
    return all(results)
# FINISH ### VALIDATION RUNNER ###

# START ### MAIN FUNCTION ###
def main():
    console.print(Panel.fit(
        "[cyan]DEPLOYMENT VALIDATOR[/cyan]\n"
        "[yellow]Ensuring everything is running smoothly[/yellow]",
        border_style="cyan"
    ))
    
    # Run validation tests
    console.print("\n[cyan]Running validation tests...[/cyan]")
    if run_validation_tests():
        console.print("\n[green]All validation tests passed![/green]")
        sys.exit(0)
    else:
        console.print("\n[red]Some validation tests failed![/red]")
        sys.exit(1)
# FINISH ### MAIN FUNCTION ###

# START ### SCRIPT RUNNER ###
if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        console.print("\n[yellow]Validation terminated by user[/yellow]")
        sys.exit(0)
    except Exception as e:
        console.print(f"\n[red]Critical error: {str(e)}[/red]")
        sys.exit(1)
# FINISH ### SCRIPT RUNNER ###