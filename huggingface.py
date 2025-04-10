#!/usr/bin/env python3

# START ### IMPORTS ###
import re
import os
import sys
import json
import time
import subprocess
import psutil
import requests
from pathlib import Path
from rich.console import Console
from rich.panel import Panel
from rich.prompt import Prompt
from rich.table import Table
from rich.style import Style
from huggingface_hub import HfApi, hf_hub_download, model_info
from tqdm import tqdm
from packaging import version as pkg_version # Use alias to avoid name clash
# FINISH ### IMPORTS ###

# START ### CONSOLE SETUP ###
console = Console(force_terminal=True, color_system="auto") # Try forcing color
CYBER_STYLES = {
    'neon_green': Style(color="green1", bold=True),
    'cyber_purple': Style(color="purple", bold=True),
    'cyber_orange': Style(color="orange1", bold=True),
    'matrix_text': Style(color="green4"),
    'error_red': Style(color="red1", bold=True),
    'warn_yellow': Style(color="yellow1", bold=True)
}

def print_styled(text, style_name):
    console.print(text, style=CYBER_STYLES[style_name])
# FINISH ### CONSOLE SETUP ###

# START ### SYSTEM SPECS ###
def check_system_specs():
    """Check system specifications"""
    try:
        ram = psutil.virtual_memory().total / (1024**3)  # GB
        # GPU checks are less reliable/needed here as llama.cpp checks itself
        return {
            "total_ram": ram,
            "gpu_ram": 0, # Placeholder
            "gpu_name": None, # Placeholder
            "recommended_quant": "Q4_K_M" # Placeholder, actual model is set by env/default
        }
    except Exception as e:
        console.print(f"[red]Error checking system specs: {str(e)}[/red]")
        return None
# FINISH ### SYSTEM SPECS ###

# START ### LLAMA CPP HANDLER ###
def check_llama_version():
    """Check llama-cpp-python version & CUDA status (assumes installed during Docker build)"""
    try:
        import llama_cpp
        version = llama_cpp.__version__
        print_styled(f"✓ llama-cpp-python found. Version: {version}", "neon_green")

        cuda_enabled = False
        try:
            # Check common ways CUDA support is exposed
            if hasattr(llama_cpp, 'llama_supports_gpu_offload') and llama_cpp.llama_supports_gpu_offload():
                 cuda_enabled = True
            elif hasattr(llama_cpp, 'llama_backend_has_cuda') and llama_cpp.llama_backend_has_cuda():
                 cuda_enabled = True
            elif hasattr(llama_cpp, 'llama_cpp') and hasattr(llama_cpp.llama_cpp, 'llama_supports_gpu_offload') and llama_cpp.llama_cpp.llama_supports_gpu_offload():
                 cuda_enabled = True

            if cuda_enabled:
                print_styled("✓ CUDA support appears ENABLED in llama-cpp-python build.", "neon_green")
            else:
                 # Attempt test context creation as fallback check
                 try:
                     # Create a minimal dummy GGUF header (replace with actual small model if available)
                     dummy_gguf_path = Path("/tmp/dummy_model_test.gguf")
                     if not dummy_gguf_path.exists():
                         # Write minimal valid GGUF header structure (simplified)
                         with open(dummy_gguf_path, 'wb') as f:
                             # Magic + Version
                             f.write(b'GGUF')
                             f.write((3).to_bytes(4, 'little')) # Version 3
                             # Tensor count (0) + Metadata KV count (1)
                             f.write((0).to_bytes(8, 'little'))
                             f.write((1).to_bytes(8, 'little'))
                             # Write one dummy metadata key/value
                             key = b'dummy.key'
                             value = b'dummy_value'
                             f.write(len(key).to_bytes(8, 'little'))
                             f.write(key)
                             f.write((8).to_bytes(4, 'little')) # Type STRING
                             f.write(len(value).to_bytes(8, 'little'))
                             f.write(value)

                     temp_llama = llama_cpp.Llama(model_path=str(dummy_gguf_path), n_gpu_layers=1, verbose=False)
                     del temp_llama
                     print_styled("✓ CUDA support confirmed via test context creation.", "neon_green")
                     cuda_enabled = True
                 except Exception as test_err:
                     print_styled(f"! CUDA support check returned FALSE. Test context failed: {test_err}", "warn_yellow")
                     print_styled("! Verify Docker build used CMAKE_ARGS='-DLLAMA_CUBLAS=on' and check build logs.", "warn_yellow")
                     # Do not return version if CUDA check fails and GPU is expected
                     return None # Indicate failure

        except Exception as cuda_check_err:
            print_styled(f"! Could not definitively check CUDA status: {cuda_check_err}", "warn_yellow")
            # Proceed but maybe without guarantee of GPU offload

        # Check minimum version for Mixtral
        try:
            if pkg_version.parse(version) < pkg_version.parse("0.2.26"):
                print_styled(f"! Warning: llama-cpp-python version {version} might be too old for Mixtral. Recommend >= 0.2.26.", "warn_yellow")
        except Exception as parse_err:
             print_styled(f"! Error checking minimum version: {parse_err}", "warn_yellow")

        return version # Return version if checks passed

    except ImportError:
        print_styled("ERROR: llama-cpp-python is NOT installed or accessible.", "error_red")
        return None
    except Exception as e:
        import traceback
        print_styled(f"Error checking llama-cpp-python version: {str(e)}", "error_red")
        console.print(f"{traceback.format_exc()}")
        return None
# FINISH ### LLAMA CPP HANDLER ###

# START ### URL VALIDATION ###
def validate_hf_url(url):
    """Validate HuggingFace URL format"""
    if not url: return None
    patterns = [
        r'https?://huggingface\.co/([^/]+/[^/]+)(?:/(?:tree|blob)/[^/]+)?/?$', # Adjusted pattern
        r'^([^/]+/[^/]+)$'
    ]
    for pattern in patterns:
        match = re.match(pattern, url.strip())
        if match:
            return match.group(1)
    return None
# FINISH ### URL VALIDATION ###

# START ### MODEL FILES HANDLER ###
def get_model_files(repo_id):
    """Get model files from repository"""
    try:
        console.print(f"[dim]Listing files in repo: {repo_id}...[/dim]")
        api = HfApi()
        files = api.list_repo_files(repo_id)
        model_files = [f for f in files if f.endswith(('.gguf'))] # Only care about GGUF now
        console.print(f"[dim]Found {len(model_files)} GGUF files.[/dim]")
        return model_files
    except Exception as e:
        print_styled(f"Error listing repo files for {repo_id}: {str(e)}", "error_red")
        return None

def get_file_size(repo_id, file_name):
    """Get file size in GB"""
    try:
        from huggingface_hub.utils import build_hf_headers
        token = os.environ.get("HUGGING_FACE_HUB_TOKEN")
        headers = build_hf_headers(token=token)
        url = f"https://huggingface.co/{repo_id}/resolve/main/{file_name}"

        response = requests.head(url, headers=headers, allow_redirects=True, timeout=15) # Increased timeout
        response.raise_for_status()

        if "x-linked-size" in response.headers:
            size = int(response.headers["x-linked-size"])
            return size / (1024**3)
        elif "content-length" in response.headers:
            size = int(response.headers["content-length"])
            return size / (1024**3)
        else:
             # Fallback might be too slow/heavy for setup script
             print_styled(f"Warning: Could not determine size for {file_name} via HEAD.", "warn_yellow")
             return 0 # Return 0 if size unknown

    except requests.exceptions.RequestException as e:
        print_styled(f"Network error getting size for {file_name}: {str(e)}", "error_red")
        return None
    except Exception as e:
        print_styled(f"Error getting size for {file_name}: {str(e)}", "error_red")
        return None
# FINISH ### MODEL FILES HANDLER ###

# START ### MODEL ANALYZER ###
def analyze_model(repo_id):
    """Analyze model information"""
    try:
        info = model_info(repo_id)
        # Simplified output for setup script
        tags = info.tags if info.tags else ['N/A']
        downloads = info.downloads if info.downloads else 'N/A'
        likes = info.likes if info.likes else 'N/A'
        console.print(f"[dim]Repo Info: Tags: {', '.join(tags)} | Downloads: {downloads} | Likes: {likes}[/dim]")
        return info
    except Exception as e:
        print_styled(f"Couldn't get model info for {repo_id}: {str(e)}", "warn_yellow")
        return None
# FINISH ### MODEL ANALYZER ###

# START ### DOWNLOAD MANAGER ###
def setup_model_directory(model_name, quant_type):
    """Set up model directories using container-friendly paths"""
    base_dir = Path("/home/flintx/models") # Use consistent path mapped in compose
    safe_model_name = model_name.replace('/', '_')
    model_dir = base_dir / safe_model_name / quant_type
    model_dir.mkdir(parents=True, exist_ok=True)
    return model_dir

def get_model_database():
    """Get model database from mapped location"""
    db_path = Path("/home/flintx/.local/share/llm_models.json") # Mapped from host ~/.local/share
    db_path.parent.mkdir(parents=True, exist_ok=True)
    if db_path.exists():
        try:
            with open(db_path) as f:
                return json.load(f)
        except Exception: # Catch broad exceptions for file read errors
             return {"models": {}} # Return empty if read fails
    return {"models": {}}

def save_model_database(db):
    """Save model database to mapped location"""
    db_path = Path("/home/flintx/.local/share/llm_models.json")
    try:
        with open(db_path, "w") as f:
            json.dump(db, f, indent=2)
    except Exception as e:
         print_styled(f"Error saving model database to {db_path}: {e}", "error_red")

def download_model(repo_id, file_name, model_info_dict):
    """Download model with progress tracking using hf_hub_download"""
    try:
        quant_type = next((k for k in QUANT_INFO.keys() if k in file_name), "base")
        model_dir = setup_model_directory(repo_id.split("/")[1], quant_type)
        local_path = model_dir / file_name

        # Check database first
        db = get_model_database()
        models_db = db.get("models", {})
        repo_files_db = models_db.get(repo_id, {}).get("files", {})

        if file_name in repo_files_db:
             existing_path_str = repo_files_db[file_name]
             if Path(existing_path_str).exists():
                  print_styled(f"✓ Model already listed in DB and exists at: {existing_path_str}", "neon_green")
                  return existing_path_str # Assume file is good if it exists
             else:
                  print_styled(f"! Model listed in DB but file missing at: {existing_path_str}. Re-downloading.", "warn_yellow")

        # Download using huggingface_hub utility
        print_styled(f"Starting download of {file_name} from {repo_id}", "cyber_orange")
        expected_size_gb = model_info_dict.get("size_gb", 0)
        if expected_size_gb:
             console.print(f"[dim]Expected Size: {expected_size_gb:.2f} GB[/dim]")

        # Use hf_hub_download - it handles progress etc.
        downloaded_path_str = hf_hub_download(
            repo_id=repo_id,
            filename=file_name,
            local_dir=model_dir,
            local_dir_use_symlinks=False,
            resume_download=True,
            token=os.environ.get("HUGGING_FACE_HUB_TOKEN"), # Pass token if available
        )

        # Update database
        if repo_id not in models_db:
             models_db[repo_id] = {"files": {}}
        if "files" not in models_db[repo_id]: # Ensure files dict exists
             models_db[repo_id]["files"] = {}
        models_db[repo_id]["files"][file_name] = downloaded_path_str # Use actual downloaded path
        # Add/update other info if needed
        models_db[repo_id]["info"] = model_info_dict
        save_model_database({"models": models_db}) # Save updated db

        print_styled(f"✓ Download complete!", "neon_green")
        print_styled(f"✓ Saved to: {downloaded_path_str}", "neon_green")
        return downloaded_path_str

    except Exception as e:
        import traceback
        print_styled(f"Error downloading model: {str(e)}", "error_red")
        console.print(f"{traceback.format_exc()}")
        return None
# FINISH ### DOWNLOAD MANAGER ###

# START ### SERVER CONFIG GENERATOR ###
def generate_server_config(model_path, system_specs):
    """Generate server configuration based on P2000 optimizations"""
    if not model_path: # Added check for valid model path
         print_styled("Error: Cannot generate config without valid model path.", "error_red")
         return None

    config = {
        "model_path": str(model_path), # Ensure path is string
        "host": "0.0.0.0",
        "port": 8080,
        "n_ctx": 2048,
        # Use logical=False for physical cores, maybe safer in container
        "n_threads": max(1, psutil.cpu_count(logical=False) or 1), # Default to 1 if count fails
        "n_gpu_layers": 8,         # *** P2000 Optimized ***
        "tensor_split_values": [0.35, 0.35], # Store actual values
        "n_batch": 64             # *** P2000 Optimized ***
    }

    # Context adjustment based on available RAM (optional)
    # ram_gb = system_specs.get("total_ram", psutil.virtual_memory().total / (1024**3))
    # if ram_gb >= 32: config["n_ctx"] = 4096

    print_styled("Generated server config parameters (P2000 Profile):", "matrix_text")
    console.print(json.dumps(config, indent=2))
    return config

# Saving JSON config is less critical if script is generated directly
# def save_server_config(config): ...

def create_server_script(config):
    """Create server launch script with corrected rope_freq_base and explicit tensor_split"""
    if not config: # Added check for valid config
         print_styled("Error: Cannot create server script without valid config.", "error_red")
         return None

    script_dir = Path("/app/scripts") # Use /app path inside container
    script_dir.mkdir(parents=True, exist_ok=True)
    script_path = script_dir / "run_server.sh"

    # Construct the command line arguments carefully
    cmd_args = [
        "python3", "-m", "llama_cpp.server",
        "--model", config["model_path"],
        "--host", config["host"],
        "--port", str(config["port"]),
        "--n_ctx", str(config["n_ctx"]),
        "--n_threads", str(config["n_threads"]),
        "--n_gpu_layers", str(config["n_gpu_layers"]),
        "--n_batch", str(config["n_batch"]),
        "--model_alias", "mixtral", # Or make dynamic
        "--rope_freq_base", "1000000", # *** CORRECTED for Mixtral ***
        "--rope_freq_scale", "1.0",
        # "--mul_mat_q", "true", # Often default/not needed unless tuning
        "--use_mlock", "true" # Requires ulimits in compose
    ]

    # Add tensor_split argument formatted as space-separated string
    if config.get("tensor_split_values"):
         split_str = " ".join(map(str, config["tensor_split_values"]))
         cmd_args.extend(["--tensor_split", split_str])

    # Escape arguments for shell script (simple version for known args)
    escaped_args = " ".join(f"'{arg}'" if any(c in str(arg) for c in ' \'";') else str(arg) for arg in cmd_args)

    script_content = f"""#!/bin/bash
# Auto-generated by huggingface.py setup script
echo -e "\\033[36m[+] Starting Mixtral Server (P2000 Profile)...\\033[0m"
echo -e "\\033[32m[+] Model: {config["model_path"]}\\033[0m"
echo -e "\\033[32m[+] GPU Layers: {config["n_gpu_layers"]} | Batch: {config["n_batch"]} | Split: {config.get("tensor_split_values", "Auto")}\\033[0m"
echo -e "\\033[32m[+] Server will run on {config["host"]}:{config["port"]}\\033[0m"
echo ""

# Use exec to replace the shell process - IMPORTANT for Supervisor/Docker signal handling
exec {escaped_args}
"""

    try:
        with open(script_path, "w") as f:
            f.write(script_content)
        script_path.chmod(0o755) # Make executable
        print_styled(f"✓ Server launch script created: {script_path}", "neon_green")
        return str(script_path)
    except Exception as e:
        print_styled(f"Error creating server script at {script_path}: {e}", "error_red")
        return None
# FINISH ### SERVER CONFIG GENERATOR ###


# START ### QUANTIZATION INFO ###
QUANT_INFO = { # Kept for reference if downloader logic changes
    'Q2_K': {'quality': 'Lowest', 'size': 'Smallest', 'ram': '4-8GB'},
    'Q3_K_M': {'quality': 'Low', 'size': 'Very Small', 'ram': '6-10GB'},
    'Q4_0': {'quality': 'Medium-Low', 'size': 'Small', 'ram': '8-12GB'},
    'Q4_K_M': {'quality': 'Medium', 'size': 'Medium', 'ram': '8-12GB'},
    'Q5_0': {'quality': 'Medium-High', 'size': 'Medium-Large', 'ram': '10-14GB'},
    'Q5_K_M': {'quality': 'High', 'size': 'Large', 'ram': '10-14GB'},
    'Q6_K': {'quality': 'Very High', 'size': 'Very Large', 'ram': '12-16GB'},
    'Q8_0': {'quality': 'Highest', 'size': 'Largest', 'ram': '16GB+'}
}
# FINISH ### QUANTIZATION INFO ###

# START ### MAIN FUNCTION (SETUP ONLY) ###
def main():
    console.rule("[bold cyan]Bolt LLM Server Pre-flight Check & Setup[/bold cyan]")

    # --- Check llama-cpp-python status ---
    if not check_llama_version():
         print_styled("CRITICAL: llama-cpp-python check failed. Cannot continue.", "error_red")
         sys.exit(1)

    # --- Define the target model using Env Vars or Defaults ---
    default_repo_id = os.environ.get("MODEL_REPO_ID", "TheBloke/Mixtral-8x7B-v0.1-GGUF")
    default_filename = os.environ.get("MODEL_FILENAME", "mixtral-8x7b-v0.1.Q4_K_M.gguf") # The one that worked

    repo_id = validate_hf_url(default_repo_id)
    if not repo_id:
         print_styled(f"ERROR: Invalid default/env repo ID: {default_repo_id}", "error_red")
         sys.exit(1)
    print_styled(f"Target repo ID: {repo_id}", "cyber_purple")
    analyze_model(repo_id) # Show basic info

    # --- Select the model file (non-interactive based on defaults/env) ---
    files = get_model_files(repo_id)
    if files is None: # Check if list failed
        print_styled(f"ERROR: Could not list files for repo {repo_id}.", "error_red")
        sys.exit(1)
    if not files: # Check if list is empty
        print_styled(f"ERROR: No GGUF files found in repo {repo_id}.", "error_red")
        sys.exit(1)

    selected_file = None
    if default_filename in files:
        selected_file = default_filename
        print_styled(f"Target model file: {selected_file}", "cyber_purple")
    else:
        # Fallback logic if default/env var filename isn't found
        fallback_file = files[0] # Use the first file found
        print_styled(f"Warning: Target file '{default_filename}' not found in repo.", "warn_yellow")
        print_styled(f"Using first available GGUF file: {fallback_file}", "warn_yellow")
        selected_file = fallback_file

    # --- Get model size ---
    selected_file_size_gb = get_file_size(repo_id, selected_file)
    if selected_file_size_gb is None:
         # Decide how to handle failure: exit or proceed with unknown size?
         print_styled(f"Warning: Could not determine size for {selected_file}. Proceeding...", "warn_yellow")
         selected_file_size_gb = 0 # Default to 0 for DB storage

    model_info_payload = {
        "repo_id": repo_id,
        "file": selected_file,
        "type": "gguf",
        "size_gb": selected_file_size_gb
    }

    # --- Ensure model is downloaded (non-interactive) ---
    should_download = os.environ.get("AUTO_DOWNLOAD_MODEL", "yes").lower() != "no"

    downloaded_path_str = None
    model_available = False
    if should_download:
         console.print(f"[cyan]Ensuring model file '{selected_file}' exists...[/cyan]")
         downloaded_path_str = download_model(repo_id, selected_file, model_info_payload)
         if downloaded_path_str and Path(downloaded_path_str).exists():
              model_available = True
         else:
              print_styled(f"ERROR: Failed to download or locate model file: {selected_file}.", "error_red")
              sys.exit(1)
    else:
         # Try to find pre-existing model if download skipped
         db = get_model_database()
         models_db = db.get("models", {})
         repo_files_db = models_db.get(repo_id, {}).get("files", {})
         if selected_file in repo_files_db:
             existing_path_str = repo_files_db[selected_file]
             if Path(existing_path_str).exists():
                 downloaded_path_str = existing_path_str
                 print_styled(f"✓ Using existing model found in DB (download skipped): {downloaded_path_str}", "neon_green")
                 model_available = True
         # Add fallback to known path if needed? Usually rely on DB or download.

         if not model_available:
              print_styled(f"ERROR: Download skipped, and model file '{selected_file}' not found. Cannot proceed.", "error_red")
              sys.exit(1)


    # --- Generate Config & Script ---
    sys_specs = check_system_specs() # Simple RAM check might be useful here
    if not sys_specs:
         print_styled("ERROR: Failed to get system specs for config generation.", "error_red")
         sys.exit(1) # Exit if we can't get specs

    print_styled("Generating server configuration and launch script...", "cyber_orange")
    config = generate_server_config(downloaded_path_str, sys_specs)
    if not config: # Check if config generation failed
        print_styled("ERROR: Failed to generate server config.", "error_red")
        sys.exit(1)

    server_script_path = create_server_script(config)
    if not server_script_path:
         print_styled("ERROR: Failed to create server launch script.", "error_red")
         sys.exit(1)

    console.rule("[bold green]✓ Setup Complete[/bold green]")
    console.print(f"[cyan]Model:[/cyan] [yellow]{downloaded_path_str}[/yellow]")
    console.print(f"[cyan]Launch Script:[/cyan] [yellow]{server_script_path}[/yellow]")
    console.print("[dim]Supervisor will now launch services defined in supervisord.conf.[/dim]")
    console.print() # Add a newline for cleaner exit

# FINISH ### MAIN FUNCTION (SETUP ONLY) ###


# START ### SCRIPT RUNNER ###
if __name__ == "__main__":
    try:
        main()
        # Exit with 0 on successful completion of main()
        sys.exit(0)
    except KeyboardInterrupt:
        print_styled("\nSetup script interrupted by user.", "warn_yellow")
        sys.exit(130) # Standard exit code for Ctrl+C
    except SystemExit as e:
         # Propagate specific exit codes from main()
         sys.exit(e.code)
    except Exception as e:
        import traceback
        print_styled(f"\nUnhandled Critical Error in Setup: {str(e)}", "error_red")
        console.print(f"{traceback.format_exc()}")
        sys.exit(1) # Exit with generic error code
# FINISH ### SCRIPT RUNNER ###
