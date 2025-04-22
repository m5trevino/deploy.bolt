# START ### LLAMA CPP HANDLER ###
def check_llama_version():
    """Check llama-cpp-python version"""
    try:
        import llama_cpp
        version = llama_cpp.__version__
        console.print(f"[cyan]Current llama-cpp-python version: {version}[/cyan]")
        return version
    except ImportError:
        console.print("[yellow]! llama-cpp-python not installed[/yellow]")
        return None
    except Exception as e:
        console.print(f"[red]Error checking llama-cpp-python version: {str(e)}[/red]")
        return None

def install_llama_cpp_cuda():
    """Install llama-cpp-python with CUDA support, ensuring build tools are updated."""
    try:
        console.print("\n[cyan]Ensuring core build tools (pip, setuptools, wheel, packaging) are up-to-date...[/cyan]")
        upgrade_cmds = [
            [sys.executable, "-m", "pip", "install", "--upgrade", "pip", "setuptools", "wheel", "packaging"]
        ]
        for cmd in upgrade_cmds:
            # Use simple join for display
            cmd_str = " ".join(cmd)
            console.print(f"[dim]Running: {cmd_str}[/dim]")
            upgrade_process = subprocess.run(cmd, capture_output=True, text=True)
            if upgrade_process.returncode != 0:
                console.print(f"[yellow]Warning: Failed to upgrade build tools. Stderr:[/yellow]")
                console.print(upgrade_process.stderr)
            else:
                console.print("[green]✓ Build tools checked/updated.[/green]")

        console.print("\n[cyan]Setting up llama-cpp-python for Mixtral with CUDA... This might take a minute.[/cyan]")

        console.print("[dim]Attempting to uninstall any existing llama-cpp-python...[/dim]")
        uninstall_process = subprocess.run([sys.executable, "-m", "pip", "uninstall", "-y", "llama-cpp-python"], capture_output=True, text=True)
        if uninstall_process.returncode == 0:
            console.print("[dim]Previous version uninstalled (if existed).[/dim]")
        else:
            console.print("[yellow]Couldn't uninstall (maybe not installed), proceeding...[/yellow]")

        build_env = os.environ.copy()
        build_env["CMAKE_ARGS"] = "-DLLAMA_CUBLAS=on"
        build_env["FORCE_CMAKE"] = "1"

        install_cmd_list = [
            sys.executable,
            "-m", "pip", "install",
            "--upgrade",
            "--force-reinstall",
            "--no-cache-dir",
            "llama-cpp-python>=0.2.26"
        ]

        cmd_str_display = " ".join(install_cmd_list)
        # Escaped single quotes for the literal string display
        env_str_display = "(env: CMAKE_ARGS='-DLLAMA_CUBLAS=on' FORCE_CMAKE=1)"

        console.print("[dim]Running installation with CUDA flags...[/dim]")
        console.print(f"[dim]Executing: {cmd_str_display} {env_str_display}[/dim]")

        process = subprocess.run(install_cmd_list, env=build_env, capture_output=True, text=True)

        if process.returncode == 0:
            console.print("[green]✓ Successfully installed/upgraded llama-cpp-python with CUDA support.[/green]")
            # Verify installation immediately after potential success
            try:
                # Short pause allows filesystem changes to settle if needed
                import time
                time.sleep(1)
                # Re-import sys if necessary inside function scope after potential modification
                import sys
                # Ensure the path where pip installed is discoverable
                import site
                # Reload site packages to potentially pick up new install
                if hasattr(site, 'main'):
                   site.main() # Common way, might vary
                # Or explicitly add user site-packages if installed there
                user_site_packages = site.getusersitepackages()
                if user_site_packages not in sys.path:
                    sys.path.insert(0, user_site_packages)

                import llama_cpp
                version = llama_cpp.__version__
                console.print(f"[green]✓ Verified installation, version: {version}[/green]")
                return True
            except ImportError as import_err:
                console.print(f"[red]Installation reported success, but failed to import llama_cpp afterwards. Error: {import_err}[/red]")
                console.print(f"[red]Current sys.path: {sys.path}[/red]")
                console.print("[red]Check Python environment, paths, and potential conflicts.[/red]")
                return False
        else:
            console.print("[red]Error installing llama-cpp-python with CUDA support:[/red]")
            console.print("[bold red]----- STDOUT -----:[/bold red]")
            console.print(process.stdout if process.stdout else "[No stdout]")
            console.print("[bold red]----- STDERR -----:[/bold red]")
            console.print(process.stderr if process.stderr else "[No stderr]")
            console.print("\n[yellow]Hint: If this persists, check CUDA Toolkit, C++ compiler (g++), and CMake versions. Environment setup is key.[/yellow]")
            return False
    except Exception as e:
        # Added traceback for unexpected errors during install
        import traceback
        console.print(f"[red]An unexpected error occurred during installation setup: {str(e)}[/red]")
        console.print(f"[red]{traceback.format_exc()}[/red]")
        return False
# FINISH ### LLAMA CPP HANDLER ###
