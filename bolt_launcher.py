#!/usr/bin/env python3
import os
import sys
import json
from pathlib import Path

class Colors:
    CYAN = '\033[0;36m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    PURPLE = '\033[0;35m'
    BOLD = '\033[1m'
    NC = '\033[0m'

def print_banner():
    print(f"{Colors.PURPLE}")
    print("""
    🔥 BOLT.DIY LAUNCHER 🔥
    ████╗  ████╗ ██╗  ████╗
    ██╔══██╗██╔═══██╗██║  ╚══██╔══╝
    ████╔╝██║   ██║██║     ██║
    ██╔══██╗██║   ██║██║     ██║
    ████╔╝╚████╔╝████╗   ██║
    ╚════╝  ╚════╝ ╚════╝   ╚═╝
    """)
    print(f"{Colors.NC}")

def clear_screen():
    os.system('clear' if os.name == 'posix' else 'cls')

def get_script_dir():
    return Path(__file__).parent.absolute()

def get_available_models():
    """Get list of configured models from configs directory"""
    config_dir = Path("/home/flintx/deploy.bolt/configs/llm_configs")
    models = []
    if config_dir.exists():
        for file in config_dir.glob("*.json"):
            try:
                with open(file) as f:
                    config = json.load(f)
                    models.append({
                        'name': config.get('name', file.stem),
                        'provider': config.get('provider', 'Unknown'),
                        'config_file': file.name
                    })
            except:
                continue
    return models

def show_model_menu():
    """Display available models and get user choice"""
    models = get_available_models()
    if not models:
        print(f"{Colors.RED}❌ No LLM configurations found!{Colors.NC}")
        return None
    
    print(f"\n{Colors.CYAN}Available LLMs:{Colors.NC}")
    for idx, model in enumerate(models, 1):
        print(f"{Colors.YELLOW}{idx}. {Colors.NC}{model['name']} ({model['provider']})")
    
    while True:
        try:
            choice = int(input(f"\n{Colors.GREEN}Choose LLM (1-{len(models)}): {Colors.NC}"))
            if 1 <= choice <= len(models):
                return models[choice-1]
        except ValueError:
            pass
        print(f"{Colors.RED}Invalid choice. Try again.{Colors.NC}")

def main():
    clear_screen()
    print_banner()

    print(f"{Colors.CYAN}Select your move:{Colors.NC}")
    print(f"{Colors.YELLOW}1. {Colors.NC}Set up new bolt.diy installation")
    print(f"{Colors.YELLOW}2. {Colors.NC}Add new LLM to existing setup")
    print(f"{Colors.YELLOW}3. {Colors.NC}Start existing LLM setup")
    print(f"{Colors.YELLOW}4. {Colors.NC}Monitor system status")
    print(f"{Colors.YELLOW}5. {Colors.NC}Cleanup & Exit")
    print(f"{Colors.YELLOW}6. {Colors.NC}Exit")

    while True:
        choice = input(f"\n{Colors.GREEN}Your choice (1-6): {Colors.NC}").strip()

        script_dir = get_script_dir()

        if choice == '1':
            setup_script = script_dir / "setup_environment.sh"
            if not setup_script.exists():
                print(f"{Colors.RED}❌ setup_environment.sh not found!{Colors.NC}")
                sys.exit(1)
            os.chmod(setup_script, 0o755)
            os.execv(str(setup_script), [str(setup_script)])

        elif choice == '2':
            custom_script = script_dir / "bolt_custom.sh"
            if not custom_script.exists():
                print(f"{Colors.RED}❌ bolt_custom.sh not found!{Colors.NC}")
                sys.exit(1)
            os.chmod(custom_script, 0o755)
            os.execv(str(custom_script), [str(custom_script)])

        elif choice == '3':
            model = show_model_menu()
            if model:
                # Export model choice for launch_bolt.sh
                os.environ['SELECTED_MODEL'] = model['name']
                launch_script = script_dir / "launch_bolt.sh"
                if not launch_script.exists():
                    print(f"{Colors.RED}❌ launch_bolt.sh not found!{Colors.NC}")
                    sys.exit(1)
                os.chmod(launch_script, 0o755)
                os.execv(str(launch_script), [str(launch_script)])

        elif choice == '4':
            monitor_script = script_dir / "monitor.sh"
            if not monitor_script.exists():
                print(f"{Colors.RED}❌ monitor.sh not found!{Colors.NC}")
                sys.exit(1)
            os.chmod(monitor_script, 0o755)
            os.system(str(monitor_script))

        elif choice == '5':
            cleanup_script = script_dir / "cleanup.sh"
            if not cleanup_script.exists():
                print(f"{Colors.RED}❌ cleanup.sh not found!{Colors.NC}")
                sys.exit(1)
            os.chmod(cleanup_script, 0o755)
            os.execv(str(cleanup_script), [str(cleanup_script)])

        elif choice == '6':
            print(f"\n{Colors.GREEN}Peace out! ✌️{Colors.NC}")
            sys.exit(0)

        else:
            print(f"{Colors.RED}Invalid choice my guy. Try again.{Colors.NC}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n\n{Colors.YELLOW}Aight, I'm out! ✌️{Colors.NC}")
        sys.exit(0)
    except Exception as e:
        print(f"\n{Colors.RED}Shit broke: {str(e)}{Colors.NC}")
        sys.exit(1)
